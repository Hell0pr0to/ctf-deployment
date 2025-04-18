#!/bin/bash

# Test Backup Script
# This script creates AMIs of the test CTF EC2 instances

# Configuration
CTFD_INSTANCE_ID="i-0c75b6fff8d320739"
DOCKER_INSTANCE_ID="i-074b5b0cdf7542c66"
BACKUP_DIR="./test-backups"
DATE=$(date +"%Y%m%d-%H%M%S")
BACKUP_LOG="$BACKUP_DIR/backup-$DATE.log"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n${GREEN}==== $1 ====${NC}\n"
}

# Function to check if a command succeeded
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 successful${NC}"
        echo "$(date): $1 successful" >> "$BACKUP_LOG"
    else
        echo -e "${RED}✗ $1 failed${NC}"
        echo "$(date): $1 failed" >> "$BACKUP_LOG"
        exit 1
    fi
}

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"
echo "$(date): Starting backup process" > "$BACKUP_LOG"

# Function to create AMI of an instance
create_ami() {
    local instance_id=$1
    local instance_name=$2
    local ami_name="TEST-CTF-$instance_name-Backup-$DATE"
    
    print_header "Creating AMI for $instance_name"
    echo "Creating AMI: $ami_name from instance: $instance_id"
    
    # Create the AMI
    AMI_ID=$(aws ec2 create-image \
        --instance-id "$instance_id" \
        --name "$ami_name" \
        --description "Test backup of $instance_name created on $(date)" \
        --no-reboot \
        --output text)
    
    check_status "Creating AMI for $instance_name"
    echo "AMI ID: $AMI_ID"
    
    # Wait for the AMI to be available
    print_header "Waiting for AMI to be available"
    echo "This may take several minutes..."
    
    aws ec2 wait image-available --image-ids "$AMI_ID"
    check_status "AMI creation completed for $instance_name"
    
    # Save AMI information to backup log
    echo "$(date): Created AMI $AMI_ID for $instance_name" >> "$BACKUP_LOG"
    
    return 0
}

# Create AMIs for both instances
create_ami "$CTFD_INSTANCE_ID" "CTFd-Server"
create_ami "$DOCKER_INSTANCE_ID" "Docker-Server"

# Create a backup manifest file
print_header "Creating backup manifest"
MANIFEST_FILE="$BACKUP_DIR/backup-manifest-$DATE.json"

cat > "$MANIFEST_FILE" << EOL
{
  "backup_date": "$(date)",
  "ctfd_instance_id": "$CTFD_INSTANCE_ID",
  "docker_instance_id": "$DOCKER_INSTANCE_ID",
  "backup_log": "$BACKUP_LOG",
  "amis": {
    "ctfd_server": "$AMI_ID",
    "docker_server": "$AMI_ID"
  }
}
EOL

check_status "Creating backup manifest"

# List all AMIs created by this script
print_header "Listing backup AMIs"
aws ec2 describe-images --owners self --filters "Name=name,Values=TEST-CTF-*-Backup-$DATE" --query "Images[*].[ImageId,Name,CreationDate]" --output table

echo -e "\n${GREEN}Backup completed successfully!${NC}"
echo -e "Backup log: ${YELLOW}$BACKUP_LOG${NC}"
echo -e "Backup manifest: ${YELLOW}$MANIFEST_FILE${NC}"
echo -e "\nTo restore from these backups, use the test-restore.sh script with the AMI IDs listed above."
