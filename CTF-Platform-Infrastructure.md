# CTF Platform Infrastructure Documentation

## Overview
This document provides comprehensive information about the CTF (Capture The Flag) platform infrastructure, including production and test environments, server configurations, networking, security, and scaling considerations for hosting 100 players.

## Environment Information

### Production Environment
- **Main URL**: https://ctf.myota.io
- **Public IP**: 44.212.203.31 (Elastic IP)

### Test Environment
- **Test URL**: https://test-ctf.myota.io
- **Test IP**: 44.212.203.31 (Same Elastic IP)

## Server Infrastructure

### CTFd Server
- **Instance ID**: i-0c75b6fff8d320739
- **AMI ID**: ami-0ec550110d065f101
- **Operating System**: Ubuntu (based on AMI)
- **Web Server**: Nginx with SSL/TLS
- **SSL Certificate**: Let's Encrypt
- **SSH Access**: 
  - Key: `~/.ssh/CTFd.pem`
  - User: `ubuntu`
  - Deployment Path: `~/deploy-ctfd.sh`

### Docker Challenge Server
- **Instance ID**: i-074b5b0cdf7542c66
- **AMI ID**: ami-0c8ddfc3e44f95526
- **Operating System**: Ubuntu (based on AMI)
- **Docker Configuration**: TLS-enabled daemon
- **SSH Access**:
  - Key: `~/.ssh/CTFd.pem`
  - User: `ubuntu`
  - Deployment Path: `~/challenges/`

## Networking Configuration

### Protocol and Security
- **Protocol**: HTTPS (443)
- **SSL/TLS Versions**: TLSv1.2, TLSv1.3
- **Cipher Suites**: HIGH:!aNULL:!MD5

## Backup System

### Configuration
- **Backup Type**: AMI Snapshots
- **Backup Location**: ./backups/
- **Latest Backup**: 2025-04-17 23:18:14 EDT

### Backup Components
- **Backup Script**: ./backup.sh
- **Restore Script**: ./restore.sh
- **Deploy Script**: ./deploy.sh

## Security Measures

### Docker Security
- TLS with certificates
- Secure daemon configuration
- Certificate-based authentication

### SSL/TLS Security
- Let's Encrypt certificates
- Modern TLS configuration
- Strong cipher suites

### Access Control
- IAM roles
- Security groups
- Network ACLs

## Monitoring and Maintenance

### Logging
- **Logs Location**: ./backups/backup-*.log
- **Manifest Files**: ./backups/backup-manifest-*.json

### Maintenance Scripts
```bash
# Backup
./backup.sh

# Restore
./restore.sh

# Deploy
./deploy.sh
```

## SSH Configuration

### Access Details
- **Key Pair Name**: CTFd
- **Key Location**: `~/.ssh/CTFd.pem`
- **Key Permissions**: 400 (read-only for owner)
- **Default User**: ubuntu

### Server Access
1. **CTFd Server**
   ```bash
   ssh -i ~/.ssh/CTFd.pem ubuntu@<ctfd-public-ip>
   ```

2. **Docker Server**
   ```bash
   ssh -i ~/.ssh/CTFd.pem ubuntu@<docker-private-ip>
   ```

### Deployment Paths
1. **CTFd Server**
   - Home Directory: `/home/ubuntu`
   - Deployment Script: `~/deploy-ctfd.sh`
   - Challenge Files: `~/challenges/`

2. **Docker Server**
   - Home Directory: `/home/ubuntu`
   - Challenge Directory: `~/challenges/`
   - Docker Compose: `~/challenges/docker-compose.yml`

## Scaling Considerations for 100 Players

### Current Architecture
- Two-server architecture
- Nginx reverse proxy
- Docker container management

### Recommended Upgrades

#### Infrastructure
1. **Instance Types**
   - Upgrade based on load monitoring
   - Consider auto-scaling groups
   - Monitor resource utilization

2. **Storage**
   - Monitor AMI storage usage
   - Implement storage scaling
   - Regular cleanup of old backups

3. **Network**
   - Ensure sufficient bandwidth
   - Consider CDN implementation
   - Implement rate limiting

#### Security
1. **Access Control**
   - Implement proper IAM roles
   - Regular security audits
   - Access logging and monitoring

2. **Network Security**
   - Regular security group reviews
   - Implement WAF if needed
   - DDoS protection

#### Monitoring
1. **System Monitoring**
   - Set up CloudWatch alarms
   - Monitor resource utilization
   - Track user metrics

2. **Security Monitoring**
   - Monitor access logs
   - Track failed attempts
   - Monitor for suspicious activity

## Maintenance Procedures

### Regular Tasks
1. **Backup Schedule**
   - Daily AMI backups
   - Weekly full system backups
   - Monthly backup verification

2. **Security Updates**
   - Regular OS updates
   - Docker updates
   - SSL certificate renewal

3. **Performance Monitoring**
   - Resource utilization
   - User load patterns
   - Network performance

### Emergency Procedures
1. **Backup Restoration**
   ```bash
   ./restore.sh <ctfd_ami_id> <docker_ami_id>
   ```

2. **Deployment Rollback**
   ```bash
   ./deploy.sh --rollback
   ```

## Best Practices

### Development
1. Use test environment for all changes
2. Implement proper version control
3. Document all configuration changes

### Operations
1. Regular backup testing
2. Performance monitoring
3. Security audits

### Security
1. Regular security updates
2. Access control reviews
3. Certificate management

## Troubleshooting

### Common Issues
1. **Backup Failures**
   - Check AWS credentials
   - Verify instance states
   - Check available disk space
   - Review backup logs

2. **Restore Failures**
   - Verify AMI availability
   - Check instance state
   - Review restore logs
   - Verify AWS permissions

### Support Contacts
- System Administrator: [Contact Info]
- Security Team: [Contact Info]
- AWS Support: [Contact Info]

## Future Improvements

### Planned Upgrades
1. Implement auto-scaling
2. Enhanced monitoring
3. Improved backup strategy
4. CDN integration
5. WAF implementation

### Scaling Strategy
1. Monitor current usage patterns
2. Plan for peak loads
3. Implement gradual scaling
4. Regular capacity planning

## Appendix

### Useful Commands
```bash
# Check server status
aws ec2 describe-instances --instance-ids <instance-id>

# View backup logs
cat ./backups/backup-*.log

# Check SSL certificate
openssl s_client -connect ctf.myota.io:443
```

### Reference Links
- [AWS Documentation](https://docs.aws.amazon.com)
- [CTFd Documentation](https://docs.ctfd.io)
- [Docker Documentation](https://docs.docker.com)
- [Nginx Documentation](https://nginx.org/en/docs/) 