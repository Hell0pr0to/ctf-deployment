#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common-helpers.sh"

CTFDOCKER_HOST="your.docker.server.ip"
check_ssh_connection "$CTFDOCKER_HOST"

echo "🚀 Syncing ctfdocker-server config..."
rsync -avz ./ctfdocker-server/ ubuntu@$CTFDOCKER_HOST:/opt/ctfdocker/

echo "♻️ Restarting Docker service..."
ssh ubuntu@$CTFDOCKER_HOST "sudo systemctl restart docker"
