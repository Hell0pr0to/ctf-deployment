#!/bin/bash
set -euo pipefail

check_ssh_connection() {
    local host=$1
    ssh -o BatchMode=yes -o ConnectTimeout=5 ubuntu@"$host" "echo SSH OK" || {
        echo "❌ SSH connection to $host failed. Aborting."
        exit 1
    }
}
