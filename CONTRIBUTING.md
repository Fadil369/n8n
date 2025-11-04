# Contributing to Brainsait Healthcare Ecosystem

Thank you for your interest in contributing to the Brainsait Healthcare Ecosystem! This document provides guidelines for contributing to the project.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/Fadil369/N8n/issues)
2. If not, create a new issue with:
   - Clear, descriptive title
   - Detailed description of the bug
   - Steps to reproduce
   - Expected behavior
   - Actual behavior
   - Environment details (OS, Docker version, etc.)
   - Screenshots if applicable

### Suggesting Enhancements

1. Check if the enhancement has been suggested
2. Create a new issue with:
   - Clear, descriptive title
   - Detailed description of the enhancement
   - Use cases and benefits
   - Potential implementation approach

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

#### Pull Request Guidelines

- Follow existing code style
- Add tests for new features
- Update documentation as needed
- Keep commits atomic and well-described
- Ensure all tests pass
- Address review comments promptly

## Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/Fadil369/N8n.git
   cd N8n
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment**
   ```bash
   cp .env.example .env
   # Edit .env with your local settings
   ```

4. **Start development environment**
   ```bash
   docker-compose up -d
   ```

## Coding Standards

### JavaScript

- Use ES6+ syntax
- Follow ESLint configuration
- Use meaningful variable and function names
- Add JSDoc comments for functions
- Keep functions small and focused

### Workflows

- Use descriptive node names
- Add comments for complex logic
- Follow naming convention: `Brainsait - <Workflow Name>`
- Tag workflows appropriately
- Test workflows thoroughly before committing

### Documentation

- Use Markdown for documentation
- Keep language clear and concise
- Include code examples where helpful
- Update documentation with code changes

## Testing

- Write unit tests for new modules
- Test workflows with sample data
- Verify HIPAA compliance for PHI handling
- Test error scenarios
- Validate performance under load

## Security

- Never commit secrets or credentials
- Use environment variables for sensitive data
- Follow HIPAA guidelines for PHI
- Report security vulnerabilities privately
- Encrypt sensitive data appropriately

## Healthcare Compliance

When contributing healthcare-related features:

- Ensure HIPAA compliance
- Follow HL7 FHIR standards
- Validate medical terminology accuracy
- Consider patient safety implications
- Document compliance measures

## Documentation

Update documentation for:

- New features
- API changes
- Configuration changes
- Deployment procedures
- User-facing changes

## Commit Message Guidelines

Use clear, descriptive commit messages:

```
feat: Add patient portal login workflow
fix: Correct appointment reminder timing
docs: Update deployment guide for Azure
refactor: Simplify patient search logic
test: Add tests for appointment scheduling
```

Prefixes:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

## Review Process

1. Maintainers review all pull requests
2. At least one approval required
3. All checks must pass
4. Changes must be HIPAA compliant
5. Documentation must be updated

## Questions?

- Open a discussion in GitHub Discussions
- Email: support@brainsait.health
- Check documentation: https://docs.brainsait.health

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Brainsait Healthcare Ecosystem!
