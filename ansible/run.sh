#!/bin/bash
# =============================================================================
# Run Ansible Playbook - Automatic Setup for WSL
# =============================================================================
# This script handles all the WSL/Windows compatibility issues automatically
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"
SSH_KEY_SOURCE="$TERRAFORM_DIR/hajar-project-key.pem"
SSH_KEY_DEST="$HOME/hajar-project-key.pem"

echo "========================================"
echo "  Hajar Project - Ansible Runner"
echo "========================================"

# Step 1: Copy SSH key to WSL home (where permissions work)
if [ -f "$SSH_KEY_SOURCE" ]; then
    echo "🔑 Copying SSH key to WSL home directory..."
    cp "$SSH_KEY_SOURCE" "$SSH_KEY_DEST"
    chmod 600 "$SSH_KEY_DEST"
    echo "   ✅ SSH key ready at $SSH_KEY_DEST"
else
    echo "❌ SSH key not found at $SSH_KEY_SOURCE"
    echo "   Run 'terraform apply' first!"
    exit 1
fi

# Step 2: Create logs directory
mkdir -p "$SCRIPT_DIR/logs"

# Step 3: Set Ansible config
export ANSIBLE_CONFIG="$SCRIPT_DIR/ansible.cfg"

# Step 4: Run Ansible
echo ""
echo "🚀 Running Ansible playbook..."
echo "========================================"

cd "$SCRIPT_DIR"

# Pass any arguments to ansible-playbook (e.g., --tags, --limit)
if [ $# -eq 0 ]; then
    # Default: run site.yml
    ansible-playbook -i inventory/hosts.yml playbooks/site.yml
else
    # Run with user-provided arguments
    ansible-playbook -i inventory/hosts.yml "$@"
fi
