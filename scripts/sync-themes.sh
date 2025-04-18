#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n${YELLOW}=== $1 ===${NC}\n"
}

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &>/dev/null; then
    echo -e "${RED}Error: AWS credentials not configured${NC}"
    echo "Please run 'aws configure' to set up your AWS credentials"
    exit 1
fi

# Get CTFd server instance ID
print_header "Getting CTFd server instance ID"
CTFD_INSTANCE_ID="i-0c75b6fff8d320739"

# Get the public IP of the CTFd server
print_header "Getting CTFd server public IP"
CTFD_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $CTFD_INSTANCE_ID --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)

if [ -z "$CTFD_PUBLIC_IP" ]; then
    echo -e "${RED}Error: Could not get CTFd server IP${NC}"
    exit 1
fi

echo -e "CTFd server IP: ${GREEN}$CTFD_PUBLIC_IP${NC}"

# Create themes directory if it doesn't exist
mkdir -p themes

# Sync themes from CTFd server
print_header "Syncing themes from CTFd server"
rsync -avz -e "ssh -o StrictHostKeyChecking=no" ubuntu@$CTFD_PUBLIC_IP:/opt/CTFd/CTFd/themes/ themes/

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Themes synced successfully${NC}"
else
    echo -e "${RED}Error: Failed to sync themes${NC}"
    exit 1
fi

print_header "Theme sync complete!" 