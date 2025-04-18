# CTF Deployment Platform

A Capture The Flag (CTF) platform deployment using CTFd, Docker, and AWS.

## Architecture

The platform uses a two-host architecture:
- **CTFd Host**: Runs the CTFd platform using Docker Compose and Nginx
- **Challenge Host**: Runs Docker containers for challenge environments with TLS enabled

## Local Development

### Prerequisites
- Docker and Docker Compose
- Python 3.8+
- Node.js 14+ (for theme development)
- AWS CLI configured

### Setup
1. Clone the repository
2. Copy `.env.example` to `.env` and configure variables
3. Generate SSL certificates:
   ```bash
   ./scripts/generate-ssl.sh
   ```
4. Start the local environment:
   ```bash
   docker-compose -f docker-compose.local.yml up -d
   ```

### Access Points
- CTFd: http://localhost:8000
- Nginx: http://localhost
- Nginx (SSL): https://localhost

## Development Workflow

We follow a GitOps model with the following branches:
- `main`: Production deployment branch
- `dev`: Active development branch
- `feature/*`: Feature branches

### Branch Strategy
1. Create feature branch from `dev`
2. Develop and test locally
3. Create PR to merge into `dev`
4. After testing, merge to `main` for production deployment

## Deployment

Production deployments are automated via GitHub Actions:
1. Changes to `main` trigger deployment workflow
2. Workflow SSH into AWS servers
3. Executes deployment scripts
4. Verifies deployment success

## Project Structure

```
.
├── .github/            # GitHub Actions workflows
├── scripts/           # Deployment and utility scripts
├── themes/           # CTFd themes
├── plugins/          # CTFd plugins
├── challenges/       # Challenge definitions
├── nginx/           # Nginx configuration
├── ssl/             # SSL certificates (gitignored)
└── docker-compose.local.yml  # Local development setup
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## License

Proprietary - All rights reserved
