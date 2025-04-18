#!/bin/bash

# CTF Deployment Script
# This script helps deploy the CTF platform and challenges to AWS instances

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

# Start the instances
print_header "Starting EC2 instances"

echo "Starting CTFd server instance..."
aws ec2 start-instances --instance-ids $CTFD_INSTANCE_ID
check_status "Starting CTFd server instance"

echo "Starting Docker server instance..."
aws ec2 start-instances --instance-ids $DOCKER_INSTANCE_ID
check_status "Starting Docker server instance"

# Wait for instances to be running
print_header "Waiting for instances to be running"
echo "This may take a few minutes..."

while true; do
    CTFD_STATUS=$(aws ec2 describe-instances --instance-ids $CTFD_INSTANCE_ID --query "Reservations[0].Instances[0].State.Name" --output text)
    DOCKER_STATUS=$(aws ec2 describe-instances --instance-ids $DOCKER_INSTANCE_ID --query "Reservations[0].Instances[0].State.Name" --output text)
    
    echo "CTFd server status: $CTFD_STATUS"
    echo "Docker server status: $DOCKER_STATUS"
    
    if [ "$CTFD_STATUS" == "running" ] && [ "$DOCKER_STATUS" == "running" ]; then
        break
    fi
    
    echo "Waiting for instances to be fully running..."
    sleep 30
done

# Get instance IPs
print_header "Getting instance IPs"
CTFD_PRIVATE_IP=$(aws ec2 describe-instances --instance-ids $CTFD_INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
DOCKER_PRIVATE_IP=$(aws ec2 describe-instances --instance-ids $DOCKER_INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)

echo "CTFd server private IP: $CTFD_PRIVATE_IP"
echo "Docker server private IP: $DOCKER_PRIVATE_IP"

# Verify Elastic IP association
print_header "Verifying Elastic IP association"
CURRENT_EIP_ASSOCIATION=$(aws ec2 describe-addresses --public-ips $CTFD_IP --query "Addresses[0].InstanceId" --output text)

if [ "$CURRENT_EIP_ASSOCIATION" != "$CTFD_INSTANCE_ID" ]; then
    echo "Elastic IP $CTFD_IP is not associated with CTFd instance. Associating now..."
    aws ec2 associate-address --instance-id $CTFD_INSTANCE_ID --public-ip $CTFD_IP
    check_status "Associating Elastic IP with CTFd instance"
else
    echo "Elastic IP $CTFD_IP is already associated with CTFd instance."
fi

# Deploy CTFd platform
print_header "Deploying CTFd platform"
echo "SSH into CTFd server and deploy platform..."
ssh -i ~/.ssh/CTFd.pem ubuntu@$CTFD_IP "cd ~ && ./deploy-ctfd.sh"
check_status "Deploying CTFd platform"

# Deploy challenge containers
print_header "Deploying challenge containers"
echo "SSH into Docker server and deploy challenges..."
ssh -i ~/.ssh/CTFd.pem ubuntu@$DOCKER_PRIVATE_IP "cd ~ && mkdir -p challenges && cd challenges && docker-compose up -d"
check_status "Deploying challenge containers"

# Verify deployment
print_header "Verifying deployment"
echo "Checking if CTFd platform is accessible..."
# Add verification commands here
# Example: curl -I https://$CTFD_DOMAIN

echo -e "\n${GREEN}Deployment completed!${NC}"
echo -e "CTFd platform should be accessible at: ${YELLOW}https://$CTFD_DOMAIN${NC}"
echo -e "Challenge containers should be running on Docker server: ${YELLOW}$DOCKER_PRIVATE_IP${NC}" 