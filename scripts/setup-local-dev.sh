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

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required tools
print_header "Checking required tools"
REQUIRED_TOOLS=("docker" "docker-compose" "rsync")

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command_exists "$tool"; then
        echo -e "${RED}Error: $tool is not installed${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ $tool is installed${NC}"
    fi
done

# Create necessary directories
print_header "Creating directories"
mkdir -p themes uploads

# Sync themes from AWS server
print_header "Syncing themes from AWS server"
./scripts/sync-themes.sh

# Start local development environment
print_header "Starting local development environment"
docker-compose -f docker-compose.dev.yml up -d

# Wait for services to be ready
print_header "Waiting for services to be ready"
sleep 10

# Check if services are running
print_header "Checking services"
if docker-compose -f docker-compose.dev.yml ps | grep -q "Up"; then
    echo -e "${GREEN}✓ All services are running${NC}"
    echo -e "\nCTFd is now available at: http://localhost:8000"
else
    echo -e "${RED}Error: Some services failed to start${NC}"
    exit 1
fi

print_header "Local development environment is ready!"
echo -e "To stop the environment, run: ${YELLOW}docker-compose -f docker-compose.dev.yml down${NC}"
echo -e "To view logs, run: ${YELLOW}docker-compose -f docker-compose.dev.yml logs -f${NC}" 