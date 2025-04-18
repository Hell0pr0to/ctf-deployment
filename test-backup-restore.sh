#!/bin/bash

# Test Environment Setup for Backup and Restore Scripts
# This script creates a test environment for testing the backup and restore functionality

# Configuration
TEST_CTFD_INSTANCE_ID="i-0c75b6fff8d320739"  # Replace with a test instance ID
TEST_DOCKER_INSTANCE_ID="i-074b5b0cdf7542c66"  # Replace with a test instance ID
TEST_CTFD_IP="44.212.203.31"  # Replace with a test Elastic IP
TEST_CTFD_DOMAIN="test-ctf.myota.io"  # Replace with a test domain
TEST_BACKUP_DIR="./test-backups"
DATE=$(date +"%Y%m%d-%H%M%S")
TEST_LOG="$TEST_BACKUP_DIR/test-$DATE.log"

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
        echo "$(date): $1 successful" >> "$TEST_LOG"
    else
        echo -e "${RED}✗ $1 failed${NC}"
        echo "$(date): $1 failed" >> "$TEST_LOG"
        exit 1
    fi
}

# Create test backup directory if it doesn't exist
mkdir -p "$TEST_BACKUP_DIR"
echo "$(date): Starting test environment setup" > "$TEST_LOG"

# Create test configuration files
print_header "Creating test configuration files"

# Create test backup script
cat > "$TEST_BACKUP_DIR/test-backup.sh" << EOF
#!/bin/bash

# Test Backup Script
# This script creates AMIs of the test CTF EC2 instances

# Configuration
CTFD_INSTANCE_ID="$TEST_CTFD_INSTANCE_ID"
DOCKER_INSTANCE_ID="$TEST_DOCKER_INSTANCE_ID"
BACKUP_DIR="$TEST_BACKUP_DIR"
DATE=\$(date +"%Y%m%d-%H%M%S")
BACKUP_LOG="\$BACKUP_DIR/backup-\$DATE.log"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n\${GREEN}==== \$1 ====\${NC}\n"
}

# Function to check if a command succeeded
check_status() {
    if [ \$? -eq 0 ]; then
        echo -e "\${GREEN}✓ \$1 successful\${NC}"
        echo "\$(date): \$1 successful" >> "\$BACKUP_LOG"
    else
        echo -e "\${RED}✗ \$1 failed\${NC}"
        echo "\$(date): \$1 failed" >> "\$BACKUP_LOG"
        exit 1
    fi
}

# Create backup directory if it doesn't exist
mkdir -p "\$BACKUP_DIR"
echo "\$(date): Starting backup process" > "\$BACKUP_LOG"

# Function to create AMI of an instance
create_ami() {
    local instance_id=\$1
    local instance_name=\$2
    local ami_name="TEST-CTF-\$instance_name-Backup-\$DATE"
    
    print_header "Creating AMI for \$instance_name"
    echo "Creating AMI: \$ami_name from instance: \$instance_id"
    
    # Create the AMI
    AMI_ID=\$(aws ec2 create-image \\
        --instance-id "\$instance_id" \\
        --name "\$ami_name" \\
        --description "Test backup of \$instance_name created on \$(date)" \\
        --no-reboot \\
        --output text)
    
    check_status "Creating AMI for \$instance_name"
    echo "AMI ID: \$AMI_ID"
    
    # Wait for the AMI to be available
    print_header "Waiting for AMI to be available"
    echo "This may take several minutes..."
    
    aws ec2 wait image-available --image-ids "\$AMI_ID"
    check_status "AMI creation completed for \$instance_name"
    
    # Save AMI information to backup log
    echo "\$(date): Created AMI \$AMI_ID for \$instance_name" >> "\$BACKUP_LOG"
    
    return 0
}

# Create AMIs for both instances
create_ami "\$CTFD_INSTANCE_ID" "CTFd-Server"
create_ami "\$DOCKER_INSTANCE_ID" "Docker-Server"

# Create a backup manifest file
print_header "Creating backup manifest"
MANIFEST_FILE="\$BACKUP_DIR/backup-manifest-\$DATE.json"

cat > "\$MANIFEST_FILE" << EOL
{
  "backup_date": "\$(date)",
  "ctfd_instance_id": "\$CTFD_INSTANCE_ID",
  "docker_instance_id": "\$DOCKER_INSTANCE_ID",
  "backup_log": "\$BACKUP_LOG",
  "amis": {
    "ctfd_server": "\$AMI_ID",
    "docker_server": "\$AMI_ID"
  }
}
EOL

check_status "Creating backup manifest"

# List all AMIs created by this script
print_header "Listing backup AMIs"
aws ec2 describe-images --owners self --filters "Name=name,Values=TEST-CTF-*-Backup-\$DATE" --query "Images[*].[ImageId,Name,CreationDate]" --output table

echo -e "\n\${GREEN}Backup completed successfully!\${NC}"
echo -e "Backup log: \${YELLOW}\$BACKUP_LOG\${NC}"
echo -e "Backup manifest: \${YELLOW}\$MANIFEST_FILE\${NC}"
echo -e "\nTo restore from these backups, use the test-restore.sh script with the AMI IDs listed above."
EOF

# Create test restore script
cat > "$TEST_BACKUP_DIR/test-restore.sh" << EOF
#!/bin/bash

# Test Restore Script
# This script restores the test CTF EC2 instances from AMI backups

# Configuration
CTFD_INSTANCE_ID="$TEST_CTFD_INSTANCE_ID"
DOCKER_INSTANCE_ID="$TEST_DOCKER_INSTANCE_ID"
CTFD_IP="$TEST_CTFD_IP"
CTFD_DOMAIN="$TEST_CTFD_DOMAIN"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n\${GREEN}==== \$1 ====\${NC}\n"
}

# Function to check if a command succeeded
check_status() {
    if [ \$? -eq 0 ]; then
        echo -e "\${GREEN}✓ \$1 successful\${NC}"
    else
        echo -e "\${RED}✗ \$1 failed\${NC}"
        exit 1
    fi
}

# Check if AMI IDs were provided
if [ \$# -lt 2 ]; then
    echo -e "\${RED}Error: Missing AMI IDs\${NC}"
    echo "Usage: \$0 <ctfd_ami_id> <docker_ami_id>"
    echo "Example: \$0 ami-0123456789abcdef0 ami-0123456789abcdef1"
    exit 1
fi

CTFD_AMI_ID=\$1
DOCKER_AMI_ID=\$2

print_header "Restoring test CTF instances from AMIs"

# Verify AMIs exist
echo "Verifying AMIs exist..."
aws ec2 describe-images --image-ids "\$CTFD_AMI_ID" "\$DOCKER_AMI_ID" > /dev/null
check_status "Verifying AMIs"

# Stop the instances
print_header "Stopping EC2 instances"

echo "Stopping CTFd server instance..."
aws ec2 stop-instances --instance-ids \$CTFD_INSTANCE_ID
check_status "Stopping CTFd server instance"

echo "Stopping Docker server instance..."
aws ec2 stop-instances --instance-ids \$DOCKER_INSTANCE_ID
check_status "Stopping Docker server instance"

# Wait for instances to be stopped
print_header "Waiting for instances to be stopped"
echo "This may take a few minutes..."

while true; do
    CTFD_STATUS=\$(aws ec2 describe-instances --instance-ids \$CTFD_INSTANCE_ID --query "Reservations[0].Instances[0].State.Name" --output text)
    DOCKER_STATUS=\$(aws ec2 describe-instances --instance-ids \$DOCKER_INSTANCE_ID --query "Reservations[0].Instances[0].State.Name" --output text)
    
    echo "CTFd server status: \$CTFD_STATUS"
    echo "Docker server status: \$DOCKER_STATUS"
    
    if [ "\$CTFD_STATUS" == "stopped" ] && [ "\$DOCKER_STATUS" == "stopped" ]; then
        break
    fi
    
    echo "Waiting for instances to be fully stopped..."
    sleep 30
done

# Create new instances from AMIs
print_header "Creating new instances from AMIs"

# Get instance details for the new instances
CTFD_DETAILS=\$(aws ec2 describe-instances --instance-ids \$CTFD_INSTANCE_ID --query "Reservations[0].Instances[0]" --output json)
DOCKER_DETAILS=\$(aws ec2 describe-instances --instance-ids \$DOCKER_INSTANCE_ID --query "Reservations[0].Instances[0]" --output json)

# Extract necessary details
CTFD_SUBNET_ID=\$(echo \$CTFD_DETAILS | jq -r '.SubnetId')
CTFD_SECURITY_GROUPS=\$(echo \$CTFD_DETAILS | jq -r '.SecurityGroups[].GroupId' | tr '\n' ' ')
CTFD_KEY_NAME=\$(echo \$CTFD_DETAILS | jq -r '.KeyName')
CTFD_INSTANCE_TYPE=\$(echo \$CTFD_DETAILS | jq -r '.InstanceType')
CTFD_IAM_ROLE=\$(echo \$CTFD_DETAILS | jq -r '.IamInstanceProfile.Arn')

DOCKER_SUBNET_ID=\$(echo \$DOCKER_DETAILS | jq -r '.SubnetId')
DOCKER_SECURITY_GROUPS=\$(echo \$DOCKER_DETAILS | jq -r '.SecurityGroups[].GroupId' | tr '\n' ' ')
DOCKER_KEY_NAME=\$(echo \$DOCKER_DETAILS | jq -r '.KeyName')
DOCKER_INSTANCE_TYPE=\$(echo \$DOCKER_DETAILS | jq -r '.InstanceType')
DOCKER_IAM_ROLE=\$(echo \$DOCKER_DETAILS | jq -r '.IamInstanceProfile.Arn')

# Terminate old instances
print_header "Terminating old instances"

echo "Terminating old CTFd server instance..."
aws ec2 terminate-instances --instance-ids \$CTFD_INSTANCE_ID
check_status "Terminating old CTFd server instance"

echo "Terminating old Docker server instance..."
aws ec2 terminate-instances --instance-ids \$DOCKER_INSTANCE_ID
check_status "Terminating old Docker server instance"

# Wait for instances to be terminated
print_header "Waiting for instances to be terminated"
echo "This may take a few minutes..."

while true; do
    CTFD_STATUS=\$(aws ec2 describe-instances --instance-ids \$CTFD_INSTANCE_ID --query "Reservations[0].Instances[0].State.Name" --output text 2>/dev/null || echo "terminated")
    DOCKER_STATUS=\$(aws ec2 describe-instances --instance-ids \$DOCKER_INSTANCE_ID --query "Reservations[0].Instances[0].State.Name" --output text 2>/dev/null || echo "terminated")
    
    echo "CTFd server status: \$CTFD_STATUS"
    echo "Docker server status: \$DOCKER_STATUS"
    
    if [ "\$CTFD_STATUS" == "terminated" ] && [ "\$DOCKER_STATUS" == "terminated" ]; then
        break
    fi
    
    echo "Waiting for instances to be fully terminated..."
    sleep 30
done

# Launch new instances from AMIs
print_header "Launching new instances from AMIs"

echo "Launching new CTFd server instance..."
NEW_CTFD_INSTANCE_ID=\$(aws ec2 run-instances \\
    --image-id "\$CTFD_AMI_ID" \\
    --count 1 \\
    --instance-type "\$CTFD_INSTANCE_TYPE" \\
    --key-name "\$CTFD_KEY_NAME" \\
    --subnet-id "\$CTFD_SUBNET_ID" \\
    --security-group-ids \$CTFD_SECURITY_GROUPS \\
    --iam-instance-profile Name="\$CTFD_IAM_ROLE" \\
    --query "Instances[0].InstanceId" \\
    --output text)
check_status "Launching new CTFd server instance"

echo "Launching new Docker server instance..."
NEW_DOCKER_INSTANCE_ID=\$(aws ec2 run-instances \\
    --image-id "\$DOCKER_AMI_ID" \\
    --count 1 \\
    --instance-type "\$DOCKER_INSTANCE_TYPE" \\
    --key-name "\$DOCKER_KEY_NAME" \\
    --subnet-id "\$DOCKER_SUBNET_ID" \\
    --security-group-ids \$DOCKER_SECURITY_GROUPS \\
    --iam-instance-profile Name="\$DOCKER_IAM_ROLE" \\
    --query "Instances[0].InstanceId" \\
    --output text)
check_status "Launching new Docker server instance"

# Wait for instances to be running
print_header "Waiting for new instances to be running"
echo "This may take a few minutes..."

while true; do
    CTFD_STATUS=\$(aws ec2 describe-instances --instance-ids \$NEW_CTFD_INSTANCE_ID --query "Reservations[0].Instances[0].State.Name" --output text)
    DOCKER_STATUS=\$(aws ec2 describe-instances --instance-ids \$NEW_DOCKER_INSTANCE_ID --query "Reservations[0].Instances[0].State.Name" --output text)
    
    echo "CTFd server status: \$CTFD_STATUS"
    echo "Docker server status: \$DOCKER_STATUS"
    
    if [ "\$CTFD_STATUS" == "running" ] && [ "\$DOCKER_STATUS" == "running" ]; then
        break
    fi
    
    echo "Waiting for instances to be fully running..."
    sleep 30
done

# Get new instance IPs
print_header "Getting new instance IPs"
CTFD_PRIVATE_IP=\$(aws ec2 describe-instances --instance-ids \$NEW_CTFD_INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
DOCKER_PRIVATE_IP=\$(aws ec2 describe-instances --instance-ids \$NEW_DOCKER_INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)

echo "CTFd server private IP: \$CTFD_PRIVATE_IP"
echo "Docker server private IP: \$DOCKER_PRIVATE_IP"

# Associate Elastic IP with new CTFd instance
print_header "Associating Elastic IP with new CTFd instance"
aws ec2 associate-address --instance-id \$NEW_CTFD_INSTANCE_ID --public-ip \$CTFD_IP
check_status "Associating Elastic IP with new CTFd instance"

# Update configuration file with new instance IDs
print_header "Updating configuration file"
CONFIG_FILE="./test-deploy.sh"
sed -i.bak "s/CTFD_INSTANCE_ID=.*/CTFD_INSTANCE_ID=\"\$NEW_CTFD_INSTANCE_ID\"/" \$CONFIG_FILE
sed -i.bak "s/DOCKER_INSTANCE_ID=.*/DOCKER_INSTANCE_ID=\"\$NEW_DOCKER_INSTANCE_ID\"/" \$CONFIG_FILE
rm -f "\${CONFIG_FILE}.bak"
check_status "Updating configuration file"

echo -e "\n\${GREEN}Restore completed successfully!\${NC}"
echo -e "New CTFd server instance ID: \${YELLOW}\$NEW_CTFD_INSTANCE_ID\${NC}"
echo -e "New Docker server instance ID: \${YELLOW}\$NEW_DOCKER_INSTANCE_ID\${NC}"
echo -e "CTFd platform should be accessible at: \${YELLOW}https://\$CTFD_DOMAIN\${NC}"
echo -e "Challenge containers should be running on Docker server: \${YELLOW}\$DOCKER_PRIVATE_IP\${NC}"
EOF

# Create test deployment script
cat > "$TEST_BACKUP_DIR/test-deploy.sh" << EOF
#!/bin/bash

# Test Deployment Script
# This script deploys the CTF platform and challenges to test AWS instances

# Configuration
CTFD_INSTANCE_ID="$TEST_CTFD_INSTANCE_ID"
DOCKER_INSTANCE_ID="$TEST_DOCKER_INSTANCE_ID"
CTFD_IP="$TEST_CTFD_IP"
CTFD_DOMAIN="$TEST_CTFD_DOMAIN"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n\${GREEN}==== \$1 ====\${NC}\n"
}

# Function to check if a command succeeded
check_status() {
    if [ \$? -eq 0 ]; then
        echo -e "\${GREEN}✓ \$1 successful\${NC}"
    else
        echo -e "\${RED}✗ \$1 failed\${NC}"
        exit 1
    fi
}

# Start the EC2 instances
print_header "Starting EC2 instances"

echo "Starting CTFd server instance..."
aws ec2 start-instances --instance-ids \$CTFD_INSTANCE_ID
check_status "Starting CTFd server instance"

echo "Starting Docker server instance..."
aws ec2 start-instances --instance-ids \$DOCKER_INSTANCE_ID
check_status "Starting Docker server instance"

# Wait for instances to be running
print_header "Waiting for instances to be running"
echo "This may take a few minutes..."

while true; do
    CTFD_STATUS=\$(aws ec2 describe-instances --instance-ids \$CTFD_INSTANCE_ID --query "Reservations[0].Instances[0].State.Name" --output text)
    DOCKER_STATUS=\$(aws ec2 describe-instances --instance-ids \$DOCKER_INSTANCE_ID --query "Reservations[0].Instances[0].State.Name" --output text)
    
    echo "CTFd server status: \$CTFD_STATUS"
    echo "Docker server status: \$DOCKER_STATUS"
    
    if [ "\$CTFD_STATUS" == "running" ] && [ "\$DOCKER_STATUS" == "running" ]; then
        break
    fi
    
    echo "Waiting for instances to be fully running..."
    sleep 30
done

# Get instance IPs
print_header "Getting instance IPs"
CTFD_PRIVATE_IP=\$(aws ec2 describe-instances --instance-ids \$CTFD_INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
DOCKER_PRIVATE_IP=\$(aws ec2 describe-instances --instance-ids \$DOCKER_INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)

echo "CTFd server private IP: \$CTFD_PRIVATE_IP"
echo "Docker server private IP: \$DOCKER_PRIVATE_IP"

# Verify Elastic IP association
print_header "Verifying Elastic IP association"
ASSOCIATED_IP=\$(aws ec2 describe-addresses --public-ips \$CTFD_IP --query "Addresses[0].InstanceId" --output text)

if [ "\$ASSOCIATED_IP" == "\$CTFD_INSTANCE_ID" ]; then
    echo -e "\${GREEN}Elastic IP \$CTFD_IP is correctly associated with CTFd server instance \$CTFD_INSTANCE_ID\${NC}"
else
    echo -e "\${YELLOW}Elastic IP \$CTFD_IP is not associated with CTFd server instance \$CTFD_INSTANCE_ID\${NC}"
    echo "Associating Elastic IP with CTFd server instance..."
    aws ec2 associate-address --instance-id \$CTFD_INSTANCE_ID --public-ip \$CTFD_IP
    check_status "Associating Elastic IP with CTFd server instance"
fi

# Deploy CTFd platform
print_header "Deploying CTFd platform"
echo "This is a test deployment. In a real deployment, this would deploy the CTFd platform to the CTFd server."

# Deploy challenge containers
print_header "Deploying challenge containers"
echo "This is a test deployment. In a real deployment, this would deploy the challenge containers to the Docker server."

# Verify deployment
print_header "Verifying deployment"
echo "This is a test deployment. In a real deployment, this would verify that the CTFd platform and challenge containers are running correctly."

echo -e "\n\${GREEN}Test deployment completed successfully!\${NC}"
echo -e "CTFd platform should be accessible at: \${YELLOW}https://\$CTFD_DOMAIN\${NC}"
echo -e "Challenge containers should be running on Docker server: \${YELLOW}\$DOCKER_PRIVATE_IP\${NC}"
EOF

# Make the test scripts executable
chmod +x "$TEST_BACKUP_DIR/test-backup.sh"
chmod +x "$TEST_BACKUP_DIR/test-restore.sh"
chmod +x "$TEST_BACKUP_DIR/test-deploy.sh"

# Create a test README
cat > "$TEST_BACKUP_DIR/README.md" << EOF
# CTF Test Environment

This directory contains scripts for testing the backup and restore functionality of the CTF deployment.

## Test Environment Setup

The test environment consists of:

1. Test instances for the CTFd server and Docker server
2. Test scripts for backup, restore, and deployment
3. Test configuration files

## Test Process

To test the backup and restore functionality:

1. Run the test deployment script to start the test instances:
   \`\`\`bash
   ./test-deploy.sh
   \`\`\`

2. Run the test backup script to create AMIs of the test instances:
   \`\`\`bash
   ./test-backup.sh
   \`\`\`

3. Run the test restore script to restore the test instances from the AMIs:
   \`\`\`bash
   ./test-restore.sh <ctfd_ami_id> <docker_ami_id>
   \`\`\`

## Test Configuration

The test scripts use the following configuration:

- \`TEST_CTFD_INSTANCE_ID\`: ID of the test CTFd server instance
- \`TEST_DOCKER_INSTANCE_ID\`: ID of the test Docker server instance
- \`TEST_CTFD_IP\`: Elastic IP for the test CTFd server
- \`TEST_CTFD_DOMAIN\`: Domain for the test CTFd server

## Test Results

The test results are logged in the \`test-$DATE.log\` file.
EOF

print_header "Test environment setup completed"
echo -e "Test scripts are located in: ${YELLOW}$TEST_BACKUP_DIR${NC}"
echo -e "Test README is located at: ${YELLOW}$TEST_BACKUP_DIR/README.md${NC}"
echo -e "Test log is located at: ${YELLOW}$TEST_LOG${NC}"
echo -e "\nTo test the backup and restore functionality, follow the instructions in the test README." 