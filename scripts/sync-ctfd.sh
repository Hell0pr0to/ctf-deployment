#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common-helpers.sh"

CTFD_HOST="your.ctfd.server.ip"
check_ssh_connection "$CTFD_HOST"

echo "🚀 Syncing ctfd-server config..."
rsync -avz ./ctfd-server/ ubuntu@$CTFD_HOST:/opt/CTFd/

echo "♻️ Restarting services on CTFd server..."
ssh ubuntu@$CTFD_HOST "cd /opt/CTFd && docker compose restart nginx ctfd"
