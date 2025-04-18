# Contributing Guidelines

## Branch Strategy

We follow a GitOps model with the following branch structure:

### Branches
- `main`: Production deployment branch
  - Protected branch
  - Requires PR review
  - Triggers production deployment
- `dev`: Active development branch
  - Default branch for development
  - Merges into `main` via PR
- `feature/*`: Feature branches
  - Created from `dev`
  - Merged back to `dev` via PR

### Branch Naming
- Feature branches: `feature/description`
- Bug fixes: `fix/description`
- Documentation: `docs/description`

## Pull Request Process

1. Create a feature branch from `dev`
2. Make your changes
3. Test locally using `docker-compose.local.yml`
4. Create a PR to merge into `dev`
5. Ensure CI checks pass
6. Get review approval
7. Merge to `dev`
8. Create PR from `dev` to `main` for production deployment

## Development Workflow

1. **Local Setup**
   ```bash
   git checkout dev
   git pull origin dev
   git checkout -b feature/your-feature
   ```

2. **Testing**
   - Run local environment:
     ```bash
     docker-compose -f docker-compose.local.yml up -d
     ```
   - Test changes at http://localhost:8000
   - Verify theme changes
   - Test challenge functionality

3. **Committing Changes**
   - Use descriptive commit messages
   - Follow conventional commits format:
     ```
     type(scope): description
     ```
   - Types: feat, fix, docs, style, refactor, test, chore

4. **Creating PR**
   - Clear title and description
   - Link related issues
   - Include testing notes
   - List any breaking changes

## Code Style

- Python: Follow PEP 8
- JavaScript: Use ESLint config
- Docker: Follow best practices
- YAML: Use 2-space indentation

## Testing Requirements

- All changes must be tested locally
- Docker challenges must be tested
- Theme changes must be verified
- Database operations must be tested
- Security implications must be considered

## Security Guidelines

- No sensitive data in commits
- Use environment variables
- Follow security best practices
- Document security considerations

## Documentation

- Update README.md if needed
- Document new features
- Update deployment notes
- Include testing instructions

## Review Process

1. Code review by at least one team member
2. Security review for sensitive changes
3. Testing verification
4. Documentation review
5. Final approval

## Deployment

- Changes to `main` trigger production deployment
- Deployment is automated via GitHub Actions
- Manual intervention available if needed
- Rollback procedures documented 