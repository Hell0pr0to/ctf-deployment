# AWS Infrastructure Status

## Current AWS Infrastructure Status

### 1. CTFd Server (i-0c75b6fff8d320739)
- **Status**: Running
- **Public IP**: 50.17.106.161
- **Private IP**: 172.31.26.45
- **Services Running**:
  - **Nginx**: Running as a reverse proxy on ports 80/443
  - **Docker**: Running with 3 containers:
    - **ctfd_ctfd_1**: The main CTFd application container
    - **ctfd_cache_1**: Redis cache for CTFd
    - **ctfd_db_1**: MariaDB database for CTFd
  - **CTFd Configuration**: 
    - Running on port 8000 internally
    - Using MariaDB for database
    - Using Redis for caching
    - Nginx configured to proxy requests to the CTFd container
    - SSL/TLS configured with Let's Encrypt certificates

### 2. Docker Challenge Server (i-074b5b0cdf7542c66)
- **Status**: Running
- **Public IP**: 52.201.21.177
- **Private IP**: 172.31.0.54
- **Services Running**:
  - **Docker**: Running but no challenge containers are currently deployed
  - **Challenges Directory**: Not yet created (the `~/challenges` directory doesn't exist)

### 3. Challenge Files
- **CTFd Server**:
  - Has several challenge ZIP files in the home directory:
    - `bypass-immutable.zip`
    - `immutable-illusion.zip`
    - `restoreops-snap-recovery-files.zip`
  - Has a `challenges` directory with:
    - `restoreops-snap-recovery.zip`
  - Has a backup directory: `ctf-backup-2025-04-11`
  - Has a deployment script: `deploy-ctfd.sh`

### 4. Deployment Status
- **CTFd Platform**: Successfully deployed and running
- **Challenge Containers**: Not yet deployed on the Docker server
- **SSH Access**: Working correctly with the `~/.ssh/CTFd.pem` key

## What's Happening

1. **CTFd Platform**: The CTFd platform is fully operational on the CTFd server, running in Docker containers with Nginx as a reverse proxy. It's configured to use HTTPS with Let's Encrypt certificates.

2. **Challenge Deployment**: While the challenge files exist on the CTFd server, they haven't been deployed to the Docker server yet. The Docker server is running but doesn't have any challenge containers deployed.

3. **Infrastructure**: The two-server architecture is in place, with the CTFd server handling the web interface and standard challenges, and the Docker server ready to host container-based challenges.

4. **Backup System**: There's a backup system in place with a recent backup from April 11, 2025.

## Next Steps

To complete the deployment:
1. Deploy the challenge containers to the Docker server
2. Configure the CTFd platform to use the Docker server for container challenges
3. Ensure all challenges are properly accessible to players 