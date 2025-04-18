# Local Files Overview

## Documentation Files
1. **AWS-Infrastructure-Status.md** - Current status of your AWS infrastructure
2. **CTF-Challenges-Documentation.md** - Documentation of all CTF challenges
3. **CTF-Platform-Infrastructure.md** - Infrastructure documentation
4. **README.md** - Main project README

## Deployment Scripts
1. **deploy.sh** - Main deployment script for the CTF platform
2. **backup.sh** - Script for backing up the platform
3. **restore.sh** - Script for restoring from backups
4. **test-backup-restore.sh** - Script for testing backup and restore functionality

## Server Configuration
1. **ctfd-server/nginx.conf** - Nginx configuration for the CTFd server
2. **ctfdocker-server/daemon.json** - Docker daemon configuration for the Docker server
3. **ctfdocker-server/certs/** - Directory for Docker TLS certificates

## Challenge Files
1. **challenges/** - Directory containing all challenge files
   - **recursive-exposure/** - Backup misconfiguration challenge
   - **immutable-illusion/** - Immutability bypass challenge
   - **bypass-immutable-privreq/** - Privilege escalation challenge
   - **backup-left-behind/** - Backup misconfiguration challenge
   - **restoreops-snap-recovery/** - Forensics challenge

## Sync Scripts
1. **scripts/sync-ctfd.sh** - Script for syncing CTFd server configuration
2. **scripts/sync-ctfdocker.sh** - Script for syncing Docker server configuration
3. **scripts/common-helpers.sh** - Common helper functions for scripts
4. **scripts/build_*.sh** - Scripts for building specific challenges

## Backup Files
1. **backups/** - Directory containing backup logs and manifests
2. **test-backups/** - Directory containing test backup files and scripts

## Key Findings

### Challenge Structure
Each challenge has a consistent structure with:
- `challenge.json` - Challenge metadata and configuration
- `Dockerfile` - For container-based challenges
- `entrypoint.sh` - Container startup script
- Challenge-specific files and directories

### Deployment Process
The deployment process involves:
- Starting EC2 instances
- Associating Elastic IPs
- Deploying CTFd platform on the CTFd server
- Deploying challenge containers on the Docker server

### Sync Process
There are scripts for syncing configuration:
- `sync-ctfd.sh` - Syncs CTFd server configuration
- `sync-ctfdocker.sh` - Syncs Docker server configuration

### Backup System
There's a comprehensive backup system:
- `backup.sh` - Creates AMI backups
- `restore.sh` - Restores from AMI backups
- Test scripts for verifying backup/restore functionality

### Challenge Types
The challenges cover various security topics:
- Backup misconfiguration
- Immutability bypass
- Privilege escalation
- Forensics

This local repository contains all the necessary files for managing your CTF platform, including deployment, backup, and challenge management. 