# CTF Challenges Documentation

## Overview
This document provides a comprehensive overview of the CTF challenges available in the platform. Each challenge is categorized by type (standard or container-based) and includes details about its structure, difficulty, and solution approach.

## Challenge Categories

### Backup Misconfiguration Challenges
These challenges focus on security issues related to backup systems and configurations.

### Immutability Bypass Challenges
These challenges explore ways to bypass immutability protections in backup systems.

### Forensics Challenges
These challenges involve analyzing and recovering data from compromised systems.

## Challenge Details

### 1. Recursive Exposure
- **Category**: Backup Misconfiguration
- **Type**: Standard
- **Value**: 350 points
- **Difficulty**: Medium
- **Description**: A recursive backup inside `/var/backups/` contains a forgotten shadow file. Players must navigate through nested directories to find the flag.
- **Flag**: `flag{nested_backup_exposure_872a}`
- **Files**:
  - `recursive-exposure.tar.gz`: The main challenge file
  - `var/`: Directory containing nested backup files
- **Solution Approach**: Extract the tar file, navigate through nested directories, and locate the hidden flag.

### 2. Immutable Illusion
- **Category**: Immutability Bypass
- **Type**: Container
- **Value**: 500 points
- **Difficulty**: Hard
- **Description**: Players must explore a container with an "immutable" snapshot to find the flag. The challenge involves bypassing immutability protections.
- **Flag**: `flag{immutable_bypass_success}`
- **Files**:
  - `Dockerfile`: Container configuration
  - `entrypoint.sh`: Container startup script
  - `immutable_snapshot/`: Directory containing the protected snapshot
  - `live_data/`: Directory with live data
  - `audit_logs/`: Directory with system logs
- **Solution Approach**: Run the container, explore the filesystem, and find a way to access the protected snapshot data.

### 3. Bypass the Immutable - Privilege Required
- **Category**: Immutability Bypass
- **Type**: Standard
- **Value**: 500 points
- **Difficulty**: Hard
- **Description**: Players take on the role of a backup user who needs to recover a flag from a protected immutable snapshot without direct permissions.
- **Flag**: `flag{privilege_escalation_master}`
- **Connection**: `nc ctf.myota.io 1338`
- **Files**:
  - `backup.c`: Source code for the backup system
  - `backup`: Compiled backup binary
  - `immutable_snapshot/`: Directory with the protected snapshot
  - `live_data/`: Directory with live data
  - `audit_logs/`: Directory with system logs
  - `solve.md`: Solution documentation
- **Solution Approach**: Analyze the backup system, find a privilege escalation vulnerability, and use it to access the protected snapshot.

### 4. Backup Left Behind
- **Category**: Backup Misconfiguration
- **Type**: Standard
- **Value**: 250 points
- **Difficulty**: Easy
- **Description**: A forgotten system backup in `/var/backups/` contains sensitive information that needs to be recovered.
- **Flag**: `flag{exposed_hash_leak_3f21}`
- **Files**:
  - `etc-backup.tar.gz`: The backup file
  - `var/`: Directory containing backup data
  - `test_extract/`: Directory for testing extraction
- **Solution Approach**: Extract the backup file, analyze its contents, and find the exposed sensitive information.

### 5. Snapshot Recovery Ops
- **Category**: Forensics
- **Type**: Standard
- **Value**: 300 points
- **Difficulty**: Medium
- **Description**: After a ransomware attack, players must use a backup snapshot to recover an important file with its original permissions and structure.
- **Flag**: `flag{snapshot_restore_success}`
- **Files**:
  - `compromised/`: Directory with encrypted files
  - `snapshot-2025-03-24/`: Directory with the clean snapshot
  - `test_restore_integrity.sh`: Script to test restore integrity
  - `setup.sh`: Setup script
- **Solution Approach**: Compare the compromised files with the snapshot, identify the important file, and restore it with proper permissions.

## Challenge Directory Structure

```
challenges/
├── recursive-exposure/
│   ├── challenge.json
│   ├── recursive-exposure.tar.gz
│   └── var/
├── immutable-illusion/
│   ├── challenge.json
│   ├── Dockerfile
│   ├── entrypoint.sh
│   ├── immutable_snapshot/
│   ├── live_data/
│   └── audit_logs/
├── bypass-immutable-privreq/
│   ├── challenge.json
│   ├── Dockerfile
│   ├── entrypoint.sh
│   ├── backup.c
│   ├── backup
│   ├── immutable_snapshot/
│   ├── live_data/
│   ├── audit_logs/
│   └── solve.md
├── backup-left-behind/
│   ├── challenge.json
│   ├── etc-backup.tar.gz
│   ├── test_extract/
│   └── var/
└── restoreops-snap-recovery/
    ├── challenge.json
    ├── README.md
    ├── compromised/
    ├── snapshot-2025-03-24/
    ├── test_restore_integrity.sh
    └── setup.sh
```

## Challenge Types

### Standard Challenges
These challenges involve analyzing files, solving puzzles, or performing forensics without requiring a container environment. Players typically download files, analyze them locally, and submit the flag.

### Container Challenges
These challenges run in Docker containers and require players to interact with a live environment. Players typically connect to the container via SSH or netcat, explore the environment, and find the flag.

## Challenge Themes

### Backup Security
The challenges focus on various aspects of backup security:
- Misconfigured backups exposing sensitive data
- Immutability protections and their bypass
- Backup system privilege escalation
- Recovery from ransomware attacks

### Skills Tested
- File system analysis
- Privilege escalation
- Forensics
- Backup system understanding
- Docker container exploration

## Deployment Information

### Standard Challenges
Standard challenges are deployed as downloadable files that players can analyze locally. These files are stored in the CTFd server's `~/challenges/` directory.

### Container Challenges
Container challenges are deployed as Docker containers on the Docker Challenge Server (Instance ID: i-074b5b0cdf7542c66). The deployment process involves:

1. **Server Access**
   ```bash
   ssh -i ~/.ssh/CTFd.pem ubuntu@<docker-server-ip>
   ```

2. **Deployment Directory**
   - Base Path: `~/challenges/`
   - Each challenge has its own subdirectory
   - Docker Compose file manages container deployment

3. **Deployment Process**
   ```bash
   cd ~/challenges
   docker-compose up -d
   ```

### Challenge Management

### Adding New Challenges
To add a new challenge:
1. Create a new directory in the `challenges/` folder
2. Add a `challenge.json` file with challenge metadata
3. Add challenge files and resources
4. For container challenges, include a Dockerfile and entrypoint script
5. Update the CTFd platform with the new challenge
6. Deploy using the appropriate server:
   - Standard challenges: CTFd server (`~/challenges/`)
   - Container challenges: Docker server (`~/challenges/`)

### Updating Challenges
To update an existing challenge:
1. SSH into the appropriate server:
   ```bash
   # For CTFd server
   ssh -i ~/.ssh/CTFd.pem ubuntu@<ctfd-server-ip>
   
   # For Docker server
   ssh -i ~/.ssh/CTFd.pem ubuntu@<docker-server-ip>
   ```
2. Navigate to the challenge directory
3. Update the challenge files
4. For container challenges:
   ```bash
   cd ~/challenges
   docker-compose down
   docker-compose up -d --build
   ```
5. Update the CTFd platform with the changes

## Challenge Testing

### Testing Standard Challenges
1. Extract and analyze challenge files
2. Verify the flag can be found
3. Check for unintended solutions

### Testing Container Challenges
1. Build the Docker container
2. Run the container and verify it works
3. Test the challenge solution
4. Check for security issues

## Challenge Hints

### Recursive Exposure
- Look for hidden files in nested directories
- Check file permissions carefully

### Immutable Illusion
- Examine the audit logs for clues
- Look for backup files that might have survived tampering

### Bypass the Immutable - Privilege Required
- Analyze the backup binary for vulnerabilities
- Check the audit logs for hints about privilege escalation

### Backup Left Behind
- Extract the backup file and examine its contents
- Look for sensitive information in configuration files

### Snapshot Recovery Ops
- Compare file metadata between compromised and snapshot directories
- Restore the file with proper permissions using appropriate tools 