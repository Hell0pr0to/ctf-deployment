#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# SSH Configuration
SSH_HOST="50.17.106.161"
SSH_USER="ubuntu"
SSH_KEY="~/.ssh/CTFd.pem"
SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=no"

echo -e "${GREEN}=== Syncing CTFd from AWS to Local Environment ===${NC}"

# Stop local containers
echo -e "\n${YELLOW}Stopping local containers...${NC}"
docker-compose -f docker-compose.local.yml down

# Create required directories
echo -e "\n${YELLOW}Creating required directories...${NC}"
mkdir -p .data/CTFd/{logs,uploads} plugins themes challenges

# Sync themes
echo -e "\n${YELLOW}Syncing themes...${NC}"
rsync -avz -e "ssh $SSH_OPTS" --delete $SSH_USER@$SSH_HOST:/opt/CTFd/CTFd/themes/ ./themes/

# Sync plugins
echo -e "\n${YELLOW}Syncing plugins...${NC}"
rsync -avz -e "ssh $SSH_OPTS" --delete $SSH_USER@$SSH_HOST:/opt/CTFd/CTFd/plugins/ ./plugins/

# Sync uploads
echo -e "\n${YELLOW}Syncing uploads...${NC}"
rsync -avz -e "ssh $SSH_OPTS" --delete $SSH_USER@$SSH_HOST:/opt/CTFd/.data/CTFd/uploads/ ./.data/CTFd/uploads/

# Export and sync database
echo -e "\n${YELLOW}Syncing database...${NC}"
ssh $SSH_OPTS $SSH_USER@$SSH_HOST 'docker exec ctfd_db_1 mysqldump -u root -pctfd --opt --single-transaction --skip-lock-tables ctfd' > .data/ctfd.sql

# Sync challenges from utils directory
echo -e "\n${YELLOW}Syncing challenges...${NC}"
rsync -avz -e "ssh $SSH_OPTS" --delete $SSH_USER@$SSH_HOST:/opt/CTFd/CTFd/utils/challenges/ ./challenges/

# Start local environment
echo -e "\n${YELLOW}Starting local environment...${NC}"
docker-compose -f docker-compose.local.yml up -d

# Wait for database to be ready
echo -e "\n${YELLOW}Waiting for database to be ready...${NC}"
sleep 15

# Import database
echo -e "\n${YELLOW}Importing database...${NC}"
docker exec ctf-deployment-db-1 mysql -u root -pctfd_root_password -e "DROP DATABASE IF EXISTS ctfd; CREATE DATABASE ctfd;"
docker exec -i ctf-deployment-db-1 mysql -u root -pctfd_root_password ctfd < .data/ctfd.sql

# Copy configuration files
echo -e "\n${YELLOW}Copying configuration files...${NC}"
rsync -avz -e "ssh $SSH_OPTS" $SSH_USER@$SSH_HOST:/opt/CTFd/CTFd/config.py ./config.py

# Restart CTFd to apply changes
echo -e "\n${YELLOW}Restarting CTFd...${NC}"
docker-compose -f docker-compose.local.yml restart ctfd

echo -e "\n${GREEN}Sync completed!${NC}"
echo -e "Local CTFd instance should be accessible at: ${YELLOW}http://localhost:8000${NC}"
echo -e "Please verify that everything is working correctly." 