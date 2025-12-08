#!/bin/bash
# =============================================================================
# Quick Setup Script for Ansible
# =============================================================================
# Run this script to prepare your Ansible environment
# =============================================================================

set -e

echo "=============================================="
echo "  Ansible Setup for Graph Analytics Platform"
echo "=============================================="

# Check if running in WSL or Linux
if [[ "$(uname -s)" == "Linux" ]]; then
    PLATFORM="Linux"
else
    PLATFORM="Other"
fi

echo "Platform: $PLATFORM"
echo ""

# Check Python
echo "Checking Python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "  ✅ $PYTHON_VERSION"
else
    echo "  ❌ Python3 not found. Please install Python 3."
    exit 1
fi

# Check pip
echo "Checking pip..."
if command -v pip3 &> /dev/null; then
    echo "  ✅ pip3 found"
else
    echo "  ❌ pip3 not found. Installing..."
    sudo apt install python3-pip -y
fi

# Check Ansible
echo "Checking Ansible..."
if command -v ansible &> /dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -n 1)
    echo "  ✅ $ANSIBLE_VERSION"
else
    echo "  ⚠️ Ansible not found. Installing..."
    pip3 install ansible boto3 botocore
fi

# Check AWS CLI
echo "Checking AWS CLI..."
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version)
    echo "  ✅ $AWS_VERSION"
else
    echo "  ⚠️ AWS CLI not found. Please install it."
fi

# Check for AWS credentials
echo "Checking AWS credentials..."
if [[ -f ~/.aws/credentials ]] || [[ -n "$AWS_ACCESS_KEY_ID" ]]; then
    echo "  ✅ AWS credentials found"
else
    echo "  ❌ No AWS credentials found"
    echo "     Run: aws configure"
fi

# Install Ansible AWS collection
echo "Installing AWS collection..."
ansible-galaxy collection install amazon.aws --force

# Check SSH key
echo ""
echo "Checking SSH key..."
KEY_PATH="$HOME/.ssh/hajar-project-key.pem"
if [[ -f "$KEY_PATH" ]]; then
    echo "  ✅ SSH key found at $KEY_PATH"
    chmod 600 "$KEY_PATH"
else
    echo "  ❌ SSH key not found at $KEY_PATH"
    echo "     Please copy your .pem file to $KEY_PATH"
fi

# Test AWS connectivity
echo ""
echo "Testing AWS connectivity..."
if aws sts get-caller-identity &> /dev/null; then
    ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text)
    echo "  ✅ Connected to AWS Account: $ACCOUNT"
else
    echo "  ❌ Cannot connect to AWS"
fi

# Create logs directory
mkdir -p logs

echo ""
echo "=============================================="
echo "  Setup Complete!"
echo "=============================================="
echo ""
echo "Next steps:"
echo "  1. Ensure your SSH key is at ~/.ssh/hajar-project-key.pem"
echo "  2. Run: ansible all -m ping"
echo "  3. Run: ansible-playbook playbooks/site.yml"
echo ""
