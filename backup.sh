#!/bin/bash

# CTF Platform Backup Script
# This script creates AMIs of the CTF EC2 instances for backup and rollback purposes

# Configuration
CTFD_INSTANCE_ID="i-0c75b6fff8d320739"  # CTFd server instance
DOCKER_INSTANCE_ID="i-074b5b0cdf7542c66"  # Challenge Docker server instance
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
BACKUP_LOG="$BACKUP_DIR/backup-$TIMESTAMP.log"
MANIFEST_FILE="$BACKUP_DIR/backup-manifest-$TIMESTAMP.json"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}==== $1 ====${NC}\n" >&2
}

# Function to print status messages
print_status() {
    echo -e "${YELLOW}$1${NC}" >&2
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}$1${NC}" >&2
}

# Function to print error messages
print_error() {
    echo -e "${RED}$1${NC}" >&2
}

# Function to check if a command succeeded
check_status() {
    if [ $? -eq 0 ]; then
        print_success "✓ $1 successful"
        echo "$(date): $1 successful" >> "$BACKUP_LOG"
        return 0
    else
        print_error "✗ $1 failed"
        echo "$(date): $1 failed" >> "$BACKUP_LOG"
        return 1
    fi
}

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"
echo "$(date): Starting backup process" > "$BACKUP_LOG"

# Function to create AMI of an instance
create_ami() {
    local instance_id=$1
    local instance_name=$2
    local ami_name="CTF-Platform-$instance_name-Backup-$TIMESTAMP"
    local ami_id=""
    
    print_header "Creating AMI for $instance_name"
    print_status "Creating AMI: $ami_name"
    print_status "Source instance: $instance_id"
    
    # Create the AMI
    ami_id=$(aws ec2 create-image \
        --instance-id "$instance_id" \
        --name "$ami_name" \
        --description "Backup of $instance_name created on $(date)" \
        --no-reboot \
        --output text)
    
    if ! check_status "Creating AMI for $instance_name"; then
        return 1
    fi
    
    print_success "AMI ID: $ami_id"
    
    # Wait for the AMI to be available
    print_header "Waiting for AMI to be available"
    print_status "This may take several minutes..."
    
    aws ec2 wait image-available --image-ids "$ami_id"
    if ! check_status "AMI creation completed for $instance_name"; then
        return 1
    fi
    
    # Save AMI information to backup log
    echo "$(date): Created AMI $ami_id for $instance_name" >> "$BACKUP_LOG"
    
    printf "%s" "$ami_id"
    return 0
}

# Main backup process
print_header "Starting CTF Platform Backup"
print_status "Backup started at: $(date)"
print_status "Backup log: $BACKUP_LOG"
print_status "Manifest file: $MANIFEST_FILE"

# Create AMIs for both instances
print_header "Creating CTFd Server AMI"
CTFD_AMI_ID=$(create_ami "$CTFD_INSTANCE_ID" "CTFd-Server")
if [ $? -ne 0 ]; then
    print_error "Failed to create CTFd-Server AMI"
    exit 1
fi

print_header "Creating Docker Server AMI"
DOCKER_AMI_ID=$(create_ami "$DOCKER_INSTANCE_ID" "Docker-Server")
if [ $? -ne 0 ]; then
    print_error "Failed to create Docker-Server AMI"
    exit 1
fi

# Create a backup manifest file
print_header "Creating backup manifest"
cat > "$MANIFEST_FILE" << EOF
{
  "backup_date": "$(date)",
  "backup_timestamp": "$TIMESTAMP",
  "instances": {
    "ctfd_server": {
      "instance_id": "$CTFD_INSTANCE_ID",
      "ami_id": "$CTFD_AMI_ID"
    },
    "docker_server": {
      "instance_id": "$DOCKER_INSTANCE_ID",
      "ami_id": "$DOCKER_AMI_ID"
    }
  },
  "files": {
    "backup_log": "$BACKUP_LOG",
    "manifest": "$MANIFEST_FILE"
  }
}
EOF

check_status "Creating backup manifest"

# List all AMIs created by this script
print_header "Backup Summary"
print_status "Created AMIs:"
aws ec2 describe-images --owners self --filters "Name=name,Values=CTF-Platform-*-Backup-$TIMESTAMP" --query "Images[*].[ImageId,Name,CreationDate]" --output table

print_success "\nBackup completed successfully!"
print_status "Backup log: $BACKUP_LOG"
print_status "Backup manifest: $MANIFEST_FILE"
print_status "\nTo restore from these backups, use the restore.sh script with the AMI IDs listed above." 