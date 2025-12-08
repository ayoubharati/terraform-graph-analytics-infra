#!/usr/bin/env python3
"""
=============================================================================
Infrastructure Connectivity Test Script
=============================================================================
This script tests all connection possibilities between components:
- Zeppelin ↔ Spark
- Spark ↔ Neo4j
- Zeppelin ↔ Neo4j
- All instances ↔ Internet
- All instances ↔ S3
- ALB ↔ Zeppelin

IPs are discovered DYNAMICALLY from AWS or instance metadata!
=============================================================================
"""

import socket
import subprocess
import sys
import json
import time
import os
from datetime import datetime
from typing import Dict, List, Tuple, Optional

# =============================================================================
# CONFIGURATION
# =============================================================================
# These are discovered dynamically - no manual updates needed!
CONFIG = {
    # Ports (these don't change)
    "zeppelin_port": 8080,
    "spark_master_port": 7077,
    "spark_webui_port": 8081,
    "neo4j_bolt_port": 7687,
    "neo4j_http_port": 7474,
    
    # AWS
    "aws_region": os.environ.get("AWS_REGION", "eu-central-1"),
    "project_name": os.environ.get("PROJECT_NAME", "hajar-project"),
    
    # Test endpoints
    "internet_test_host": "google.com",
    "internet_test_port": 443,
}

# =============================================================================
# Dynamic Discovery Functions
# =============================================================================

def get_instance_ip_by_tag(tag_name: str, region: str) -> Optional[str]:
    """Get instance private IP by Name tag using AWS CLI"""
    try:
        result = subprocess.run([
            "aws", "ec2", "describe-instances",
            "--region", region,
            "--filters", f"Name=tag:Name,Values={tag_name}", "Name=instance-state-name,Values=running",
            "--query", "Reservations[0].Instances[0].PrivateIpAddress",
            "--output", "text"
        ], capture_output=True, text=True, timeout=30)
        
        ip = result.stdout.strip()
        if ip and ip != "None" and ip != "null":
            return ip
        return None
    except Exception as e:
        print(f"  ⚠️ Could not get IP for {tag_name}: {e}")
        return None


def get_alb_dns(project_name: str, region: str) -> Optional[str]:
    """Get ALB DNS name using AWS CLI"""
    try:
        result = subprocess.run([
            "aws", "elbv2", "describe-load-balancers",
            "--region", region,
            "--query", f"LoadBalancers[?contains(LoadBalancerName, '{project_name}')].DNSName",
            "--output", "text"
        ], capture_output=True, text=True, timeout=30)
        
        dns = result.stdout.strip()
        if dns and dns != "None":
            return dns
        return None
    except Exception as e:
        print(f"  ⚠️ Could not get ALB DNS: {e}")
        return None


def get_s3_bucket(project_name: str, region: str) -> Optional[str]:
    """Get S3 bucket name using AWS CLI"""
    try:
        result = subprocess.run([
            "aws", "s3api", "list-buckets",
            "--query", f"Buckets[?contains(Name, '{project_name}')].Name",
            "--output", "text"
        ], capture_output=True, text=True, timeout=30)
        
        bucket = result.stdout.strip().split()[0] if result.stdout.strip() else None
        return bucket
    except Exception as e:
        print(f"  ⚠️ Could not get S3 bucket: {e}")
        return None


def get_instance_metadata() -> Tuple[Optional[str], Optional[str]]:
    """Get current instance's hostname and IP from EC2 metadata (if running on EC2)"""
    try:
        # Try IMDSv2 first (more secure)
        token_result = subprocess.run([
            "curl", "-s", "-X", "PUT", 
            "http://169.254.169.254/latest/api/token",
            "-H", "X-aws-ec2-metadata-token-ttl-seconds: 21600",
            "--connect-timeout", "2"
        ], capture_output=True, text=True, timeout=5)
        
        token = token_result.stdout.strip()
        
        if token:
            # Use token to get metadata
            ip_result = subprocess.run([
                "curl", "-s",
                "http://169.254.169.254/latest/meta-data/local-ipv4",
                "-H", f"X-aws-ec2-metadata-token: {token}",
                "--connect-timeout", "2"
            ], capture_output=True, text=True, timeout=5)
            
            hostname_result = subprocess.run([
                "curl", "-s",
                "http://169.254.169.254/latest/meta-data/tags/instance/Name",
                "-H", f"X-aws-ec2-metadata-token: {token}",
                "--connect-timeout", "2"
            ], capture_output=True, text=True, timeout=5)
            
            return hostname_result.stdout.strip(), ip_result.stdout.strip()
    except:
        pass
    
    # Fallback to socket
    try:
        hostname = socket.gethostname()
        local_ip = socket.gethostbyname(hostname)
        return hostname, local_ip
    except:
        return None, None


def discover_infrastructure() -> Dict:
    """Discover all infrastructure IPs dynamically"""
    print("\n🔍 Discovering infrastructure...")
    
    project = CONFIG["project_name"]
    region = CONFIG["aws_region"]
    
    infra = {
        "zeppelin_ip": None,
        "spark_ip": None,
        "neo4j_ip": None,
        "alb_dns": None,
        "s3_bucket": None,
    }
    
    # Discover IPs
    print(f"  Looking for instances with project: {project}")
    
    infra["zeppelin_ip"] = get_instance_ip_by_tag(f"{project}-zeppelin", region)
    print(f"  Zeppelin IP: {infra['zeppelin_ip'] or '❌ Not found'}")
    
    infra["spark_ip"] = get_instance_ip_by_tag(f"{project}-spark-worker", region)
    print(f"  Spark IP: {infra['spark_ip'] or '❌ Not found'}")
    
    infra["neo4j_ip"] = get_instance_ip_by_tag(f"{project}-neo4j", region)
    print(f"  Neo4j IP: {infra['neo4j_ip'] or '❌ Not found'}")
    
    infra["alb_dns"] = get_alb_dns(project, region)
    print(f"  ALB DNS: {infra['alb_dns'] or '❌ Not found'}")
    
    infra["s3_bucket"] = get_s3_bucket(project, region)
    print(f"  S3 Bucket: {infra['s3_bucket'] or '❌ Not found'}")
    
    return infra


# =============================================================================
# Test Results
# =============================================================================
class TestResult:
    def __init__(self, name: str, status: bool, message: str, duration: float):
        self.name = name
        self.status = status
        self.message = message
        self.duration = duration
    
    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "status": "✅ PASS" if self.status else "❌ FAIL",
            "message": self.message,
            "duration_ms": round(self.duration * 1000, 2)
        }


# =============================================================================
# Test Functions
# =============================================================================

def test_tcp_connection(host: str, port: int, timeout: int = 5) -> Tuple[bool, str, float]:
    """Test TCP connection to a host:port"""
    if not host:
        return False, "Host IP not discovered", 0
    
    start = time.time()
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((host, port))
        sock.close()
        duration = time.time() - start
        if result == 0:
            return True, f"Connected to {host}:{port}", duration
        else:
            return False, f"Cannot connect to {host}:{port} (error code: {result})", duration
    except socket.timeout:
        return False, f"Timeout connecting to {host}:{port}", time.time() - start
    except socket.gaierror:
        return False, f"Cannot resolve hostname: {host}", time.time() - start
    except Exception as e:
        return False, f"Error: {str(e)}", time.time() - start


def test_dns_resolution(hostname: str) -> Tuple[bool, str, float]:
    """Test DNS resolution"""
    if not hostname:
        return False, "Hostname not discovered", 0
    
    start = time.time()
    try:
        ip = socket.gethostbyname(hostname)
        duration = time.time() - start
        return True, f"Resolved {hostname} to {ip}", duration
    except socket.gaierror as e:
        return False, f"DNS resolution failed: {str(e)}", time.time() - start


def test_http_endpoint(url: str, timeout: int = 10) -> Tuple[bool, str, float]:
    """Test HTTP endpoint using curl"""
    if not url or "None" in url:
        return False, "URL not discovered", 0
    
    start = time.time()
    try:
        result = subprocess.run(
            ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", "--connect-timeout", str(timeout), url],
            capture_output=True,
            text=True,
            timeout=timeout + 5
        )
        duration = time.time() - start
        status_code = result.stdout.strip()
        if status_code.startswith("2") or status_code.startswith("3"):
            return True, f"HTTP {status_code} from {url}", duration
        else:
            return False, f"HTTP {status_code} from {url}", duration
    except subprocess.TimeoutExpired:
        return False, f"Timeout accessing {url}", time.time() - start
    except Exception as e:
        return False, f"Error: {str(e)}", time.time() - start


def test_s3_access(bucket: str, region: str) -> Tuple[bool, str, float]:
    """Test S3 bucket access"""
    if not bucket:
        return False, "S3 bucket not discovered", 0
    
    start = time.time()
    try:
        result = subprocess.run(
            ["aws", "s3", "ls", f"s3://{bucket}", "--region", region],
            capture_output=True,
            text=True,
            timeout=30
        )
        duration = time.time() - start
        if result.returncode == 0:
            return True, f"S3 bucket {bucket} is accessible", duration
        else:
            return False, f"S3 access failed: {result.stderr}", duration
    except subprocess.TimeoutExpired:
        return False, "S3 access timeout", time.time() - start
    except FileNotFoundError:
        return False, "AWS CLI not installed", time.time() - start
    except Exception as e:
        return False, f"Error: {str(e)}", time.time() - start


# =============================================================================
# Test Suites
# =============================================================================

def run_zeppelin_tests(infra: Dict) -> List[TestResult]:
    """Tests to run FROM Zeppelin instance"""
    results = []
    
    status, msg, dur = test_tcp_connection(CONFIG["internet_test_host"], CONFIG["internet_test_port"])
    results.append(TestResult("Zeppelin → Internet", status, msg, dur))
    
    status, msg, dur = test_tcp_connection(infra["spark_ip"], CONFIG["spark_master_port"])
    results.append(TestResult("Zeppelin → Spark Master (7077)", status, msg, dur))
    
    status, msg, dur = test_tcp_connection(infra["spark_ip"], CONFIG["spark_webui_port"])
    results.append(TestResult("Zeppelin → Spark WebUI (8081)", status, msg, dur))
    
    status, msg, dur = test_tcp_connection(infra["neo4j_ip"], CONFIG["neo4j_bolt_port"])
    results.append(TestResult("Zeppelin → Neo4j Bolt (7687)", status, msg, dur))
    
    status, msg, dur = test_tcp_connection(infra["neo4j_ip"], CONFIG["neo4j_http_port"])
    results.append(TestResult("Zeppelin → Neo4j HTTP (7474)", status, msg, dur))
    
    status, msg, dur = test_s3_access(infra["s3_bucket"], CONFIG["aws_region"])
    results.append(TestResult("Zeppelin → S3 Bucket", status, msg, dur))
    
    return results


def run_spark_tests(infra: Dict) -> List[TestResult]:
    """Tests to run FROM Spark instance"""
    results = []
    
    status, msg, dur = test_tcp_connection(CONFIG["internet_test_host"], CONFIG["internet_test_port"])
    results.append(TestResult("Spark → Internet (NAT)", status, msg, dur))
    
    status, msg, dur = test_tcp_connection(infra["neo4j_ip"], CONFIG["neo4j_bolt_port"])
    results.append(TestResult("Spark → Neo4j Bolt (7687)", status, msg, dur))
    
    status, msg, dur = test_tcp_connection(infra["neo4j_ip"], CONFIG["neo4j_http_port"])
    results.append(TestResult("Spark → Neo4j HTTP (7474)", status, msg, dur))
    
    status, msg, dur = test_tcp_connection(infra["zeppelin_ip"], CONFIG["zeppelin_port"])
    results.append(TestResult("Spark → Zeppelin (8080)", status, msg, dur))
    
    status, msg, dur = test_s3_access(infra["s3_bucket"], CONFIG["aws_region"])
    results.append(TestResult("Spark → S3 Bucket", status, msg, dur))
    
    return results


def run_neo4j_tests(infra: Dict) -> List[TestResult]:
    """Tests to run FROM Neo4j instance"""
    results = []
    
    status, msg, dur = test_tcp_connection(CONFIG["internet_test_host"], CONFIG["internet_test_port"])
    results.append(TestResult("Neo4j → Internet (NAT)", status, msg, dur))
    
    status, msg, dur = test_tcp_connection(infra["spark_ip"], CONFIG["spark_master_port"])
    results.append(TestResult("Neo4j → Spark Master (7077)", status, msg, dur))
    
    status, msg, dur = test_tcp_connection(infra["zeppelin_ip"], CONFIG["zeppelin_port"])
    results.append(TestResult("Neo4j → Zeppelin (8080)", status, msg, dur))
    
    status, msg, dur = test_s3_access(infra["s3_bucket"], CONFIG["aws_region"])
    results.append(TestResult("Neo4j → S3 Bucket", status, msg, dur))
    
    return results


def run_external_tests(infra: Dict) -> List[TestResult]:
    """Tests to run from OUTSIDE (your local machine)"""
    results = []
    
    status, msg, dur = test_dns_resolution(infra["alb_dns"])
    results.append(TestResult("ALB DNS Resolution", status, msg, dur))
    
    if infra["alb_dns"]:
        status, msg, dur = test_http_endpoint(f"http://{infra['alb_dns']}")
        results.append(TestResult("ALB → Zeppelin (HTTP)", status, msg, dur))
    
    return results


# =============================================================================
# Main
# =============================================================================

def print_banner():
    print("""
╔═══════════════════════════════════════════════════════════════════════════════╗
║                    INFRASTRUCTURE CONNECTIVITY TESTS                          ║
║                         Graph Analytics Platform                               ║
║                        (Dynamic IP Discovery)                                  ║
╚═══════════════════════════════════════════════════════════════════════════════╝
    """)


def print_results(title: str, results: List[TestResult]):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")
    
    passed = sum(1 for r in results if r.status)
    total = len(results)
    
    for r in results:
        status_icon = "✅" if r.status else "❌"
        print(f"  {status_icon} {r.name}")
        print(f"     └─ {r.message} ({r.duration*1000:.1f}ms)")
    
    print(f"\n  Summary: {passed}/{total} tests passed")
    return passed == total


def main():
    print_banner()
    
    # Discover infrastructure dynamically
    infra = discover_infrastructure()
    
    # Detect which instance we're running on
    print("\n🖥️ Detecting current instance...")
    hostname, local_ip = get_instance_metadata()
    print(f"  Hostname: {hostname}")
    print(f"  Local IP: {local_ip}")
    
    all_passed = True
    results = []
    
    # Determine which test suite to run based on the instance
    if hostname and "zeppelin" in hostname.lower():
        print("\n  → Running on ZEPPELIN instance")
        results = run_zeppelin_tests(infra)
        all_passed &= print_results("Zeppelin Connectivity Tests", results)
        
    elif hostname and "spark" in hostname.lower():
        print("\n  → Running on SPARK instance")
        results = run_spark_tests(infra)
        all_passed &= print_results("Spark Connectivity Tests", results)
        
    elif hostname and "neo4j" in hostname.lower():
        print("\n  → Running on NEO4J instance")
        results = run_neo4j_tests(infra)
        all_passed &= print_results("Neo4j Connectivity Tests", results)
        
    elif local_ip and local_ip.startswith("10.10.1"):
        print("\n  → Running on ZEPPELIN instance (detected by IP)")
        results = run_zeppelin_tests(infra)
        all_passed &= print_results("Zeppelin Connectivity Tests", results)
        
    elif local_ip and local_ip.startswith("10.10.11"):
        # Could be Spark or Neo4j - run both tests
        print("\n  → Running on PRIVATE subnet instance")
        if local_ip == infra["spark_ip"]:
            results = run_spark_tests(infra)
            all_passed &= print_results("Spark Connectivity Tests", results)
        elif local_ip == infra["neo4j_ip"]:
            results = run_neo4j_tests(infra)
            all_passed &= print_results("Neo4j Connectivity Tests", results)
        else:
            print("  ⚠️ Could not determine instance type, running external tests")
            results = run_external_tests(infra)
            all_passed &= print_results("External Connectivity Tests", results)
    else:
        print("\n  → Running from LOCAL machine (external tests)")
        results = run_external_tests(infra)
        all_passed &= print_results("External Connectivity Tests", results)
        
        print("\n💡 To run full tests, copy this script to each EC2 instance and run it there.")
    
    # Final summary
    print("\n" + "="*60)
    if all_passed:
        print("  🎉 ALL TESTS PASSED!")
    else:
        print("  ⚠️  SOME TESTS FAILED - Check the results above")
    print("="*60)
    
    # Export results
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = f"connectivity_test_{timestamp}.json"
    
    with open(output_file, 'w') as f:
        json.dump({
            "timestamp": timestamp,
            "hostname": hostname,
            "local_ip": local_ip,
            "infrastructure": infra,
            "results": [r.to_dict() for r in results],
            "all_passed": all_passed
        }, f, indent=2)
    
    print(f"\n📄 Results saved to: {output_file}")
    
    return 0 if all_passed else 1


if __name__ == "__main__":
    sys.exit(main())
