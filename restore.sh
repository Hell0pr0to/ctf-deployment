#!/bin/bash

# CTF Restore Script
# This script restores the CTF EC2 instances from AMI backups

# Configuration
CTFD_INSTANCE_ID="i-0c75b6fff8d320739"  # CTFd server instance
DOCKER_INSTANCE_ID="i-074b5b0cdf7542c66"  # Challenge Docker server instance
CTFD_IP="44.212.203.31"  # Elastic IP for CTFd server
CTFD_DOMAIN="ctf.myota.io"  # Domain for CTFd server

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
    else
        echo -e "${RED}✗ $1 failed${NC}"
        exit 1
    fi
}

# Check if AMI IDs were provided
if [ $# -lt 2 ]; then
    echo -e "${RED}Error: Missing AMI IDs${NC}"
    echo "Usage: $0 <ctfd_ami_id> <docker_ami_id>"
    echo "Example: $0 ami-0123456789abcdef0 ami-0123456789abcdef1"
    exit 1
fi

CTFD_AMI_ID=$1
DOCKER_AMI_ID=$2

print_header "Restoring CTF instances from AMIs"

# Verify AMIs exist
echo "Verifying AMIs exist..."
aws ec2 describe-images --image-ids "$CTFD_AMI_ID" "$DOCKER_AMI_ID" > /dev/null
check_status "Verifying AMIs"

# Stop the instances
print_header "Stopping EC2 instances"

echo "Stopping CTFd server instance..."
aws ec2 stop-instances --instance-ids $CTFD_INSTANCE_ID
check_status "Stopping CTFd server instance"

echo "Stopping Docker server instance..."
aws ec2 stop-instances --instance-ids $DOCKER_INSTANCE_ID
check_status "Stopping Docker server instance"

# Wait for instances to be stopped
print_header "Waiting for instances to be stopped"
echo "This may take a few minutes..."

while true; do
    CTFD_STATUS=$(aws ec2 describe-instances --instance-ids $CTFD_INSTANCE_ID --query "Reservations[0].Instances[0].State.Name" --output text)
    DOCKER_STATUS=$(aws ec2 describe-instances --instance-ids $DOCKER_INSTANCE_ID --query "Reservations[0].Instances[0].State.Name" --output text)
    
    echo "CTFd server status: $CTFD_STATUS"
    echo "Docker server status: $DOCKER_STATUS"
    
    if [ "$CTFD_STATUS" == "stopped" ] && [ "$DOCKER_STATUS" == "stopped" ]; then
        break
    fi
    
    echo "Waiting for instances to be fully stopped..."
    sleep 30
done

# Create new instances from AMIs
print_header "Creating new instances from AMIs"

# Get instance details for the new instances
CTFD_DETAILS=$(aws ec2 describe-instances --instance-ids $CTFD_INSTANCE_ID --query "Reservations[0].Instances[0]" --output json)
DOCKER_DETAILS=$(aws ec2 describe-instances --instance-ids $DOCKER_INSTANCE_ID --query "Reservations[0].Instances[0]" --output json)

# Extract necessary details
CTFD_SUBNET_ID=$(echo $CTFD_DETAILS | jq -r '.SubnetId')
CTFD_SECURITY_GROUPS=$(echo $CTFD_DETAILS | jq -r '.SecurityGroups[].GroupId' | tr '\n' ' ')
CTFD_KEY_NAME=$(echo $CTFD_DETAILS | jq -r '.KeyName')
CTFD_INSTANCE_TYPE=$(echo $CTFD_DETAILS | jq -r '.InstanceType')
CTFD_IAM_ROLE=$(echo $CTFD_DETAILS | jq -r '.IamInstanceProfile.Arn')

DOCKER_SUBNET_ID=$(echo $DOCKER_DETAILS | jq -r '.SubnetId')
DOCKER_SECURITY_GROUPS=$(echo $DOCKER_DETAILS | jq -r '.SecurityGroups[].GroupId' | tr '\n' ' ')
DOCKER_KEY_NAME=$(echo $DOCKER_DETAILS | jq -r '.KeyName')
DOCKER_INSTANCE_TYPE=$(echo $DOCKER_DETAILS | jq -r '.InstanceType')
DOCKER_IAM_ROLE=$(echo $DOCKER_DETAILS | jq -r '.IamInstanceProfile.Arn')

# Terminate old instances
print_header "Terminating old instances"

echo "Terminating old CTFd server instance..."
aws ec2 terminate-instances --instance-ids $CTFD_INSTANCE_ID
check_status "Terminating old CTFd server instance"

echo "Terminating old Docker server instance..."
aws ec2 terminate-instances --instance-ids $DOCKER_INSTANCE_ID
check_status "Terminating old Docker server instance"

# Wait for instances to be terminated
print_header "Waiting for instances to be terminated"
echo "This may take a few minutes..."

while true; do
    CTFD_STATUS=$(aws ec2 describe-instances --instance-ids $CTFD_INSTANCE_ID --query "Reservations[0].Instances[0].State.Name" --output text 2>/dev/null || echo "terminated")
    DOCKER_STATUS=$(aws ec2 describe-instances --instance-ids $DOCKER_INSTANCE_ID --query "Reservations[0].Instances[0].State.Name" --output text 2>/dev/null || echo "terminated")
    
    echo "CTFd server status: $CTFD_STATUS"
    echo "Docker server status: $DOCKER_STATUS"
    
    if [ "$CTFD_STATUS" == "terminated" ] && [ "$DOCKER_STATUS" == "terminated" ]; then
        break
    fi
    
    echo "Waiting for instances to be fully terminated..."
    sleep 30
done

# Launch new instances from AMIs
print_header "Launching new instances from AMIs"

echo "Launching new CTFd server instance..."
NEW_CTFD_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$CTFD_AMI_ID" \
    --count 1 \
    --instance-type "$CTFD_INSTANCE_TYPE" \
    --key-name "$CTFD_KEY_NAME" \
    --subnet-id "$CTFD_SUBNET_ID" \
    --security-group-ids $CTFD_SECURITY_GROUPS \
    --iam-instance-profile Name="$CTFD_IAM_ROLE" \
    --query "Instances[0].InstanceId" \
    --output text)
check_status "Launching new CTFd server instance"

echo "Launching new Docker server instance..."
NEW_DOCKER_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$DOCKER_AMI_ID" \
    --count 1 \
    --instance-type "$DOCKER_INSTANCE_TYPE" \
    --key-name "$DOCKER_KEY_NAME" \
    --subnet-id "$DOCKER_SUBNET_ID" \
    --security-group-ids $DOCKER_SECURITY_GROUPS \
    --iam-instance-profile Name="$DOCKER_IAM_ROLE" \
    --query "Instances[0].InstanceId" \
    --output text)
check_status "Launching new Docker server instance"

# Wait for instances to be running
print_header "Waiting for new instances to be running"
echo "This may take a few minutes..."

while true; do
    CTFD_STATUS=$(aws ec2 describe-instances --instance-ids $NEW_CTFD_INSTANCE_ID --query "Reservations[0].Instances[0].State.Name" --output text)
    DOCKER_STATUS=$(aws ec2 describe-instances --instance-ids $NEW_DOCKER_INSTANCE_ID --query "Reservations[0].Instances[0].State.Name" --output text)
    
    echo "CTFd server status: $CTFD_STATUS"
    echo "Docker server status: $DOCKER_STATUS"
    
    if [ "$CTFD_STATUS" == "running" ] && [ "$DOCKER_STATUS" == "running" ]; then
        break
    fi
    
    echo "Waiting for instances to be fully running..."
    sleep 30
done

# Get new instance IPs
print_header "Getting new instance IPs"
CTFD_PRIVATE_IP=$(aws ec2 describe-instances --instance-ids $NEW_CTFD_INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
DOCKER_PRIVATE_IP=$(aws ec2 describe-instances --instance-ids $NEW_DOCKER_INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)

echo "CTFd server private IP: $CTFD_PRIVATE_IP"
echo "Docker server private IP: $DOCKER_PRIVATE_IP"

# Associate Elastic IP with new CTFd instance
print_header "Associating Elastic IP with new CTFd instance"
aws ec2 associate-address --instance-id $NEW_CTFD_INSTANCE_ID --public-ip $CTFD_IP
check_status "Associating Elastic IP with new CTFd instance"

# Update configuration file with new instance IDs
print_header "Updating configuration file"
CONFIG_FILE="./deploy.sh"
sed -i.bak "s/CTFD_INSTANCE_ID=.*/CTFD_INSTANCE_ID=\"$NEW_CTFD_INSTANCE_ID\"/" $CONFIG_FILE
sed -i.bak "s/DOCKER_INSTANCE_ID=.*/DOCKER_INSTANCE_ID=\"$NEW_DOCKER_INSTANCE_ID\"/" $CONFIG_FILE
rm -f "${CONFIG_FILE}.bak"
check_status "Updating configuration file"

echo -e "\n${GREEN}Restore completed successfully!${NC}"
echo -e "New CTFd server instance ID: ${YELLOW}$NEW_CTFD_INSTANCE_ID${NC}"
echo -e "New Docker server instance ID: ${YELLOW}$NEW_DOCKER_INSTANCE_ID${NC}"
echo -e "CTFd platform should be accessible at: ${YELLOW}https://$CTFD_DOMAIN${NC}"
echo -e "Challenge containers should be running on Docker server: ${YELLOW}$DOCKER_PRIVATE_IP${NC}" 