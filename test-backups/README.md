# CTF Test Environment

This directory contains scripts for testing the backup and restore functionality of the CTF deployment.

## Test Environment Setup

The test environment consists of:

1. Test instances for the CTFd server and Docker server
2. Test scripts for backup, restore, and deployment
3. Test configuration files

## Test Process

To test the backup and restore functionality:

1. Run the test deployment script to start the test instances:
   ```bash
   ./test-deploy.sh
   ```

2. Run the test backup script to create AMIs of the test instances:
   ```bash
   ./test-backup.sh
   ```

3. Run the test restore script to restore the test instances from the AMIs:
   ```bash
   ./test-restore.sh <ctfd_ami_id> <docker_ami_id>
   ```

## Test Configuration

The test scripts use the following configuration:

- `TEST_CTFD_INSTANCE_ID`: ID of the test CTFd server instance
- `TEST_DOCKER_INSTANCE_ID`: ID of the test Docker server instance
- `TEST_CTFD_IP`: Elastic IP for the test CTFd server
- `TEST_CTFD_DOMAIN`: Domain for the test CTFd server

## Test Results

The test results are logged in the `test-20250417-230309.log` file.
