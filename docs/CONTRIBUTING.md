# Ozi Script - Contributing Guide

Thank you for your interest in contributing to Ozi Script! This guide will help you understand how to contribute effectively.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Development Workflow](#development-workflow)
3. [Code Standards](#code-standards)
4. [Commit Guidelines](#commit-guidelines)
5. [Testing Requirements](#testing-requirements)
6. [Pull Request Process](#pull-request-process)
7. [Issue Reporting](#issue-reporting)
8. [Community](#community)

## Getting Started

### Prerequisites

- Git installed and configured
- Bash 4.0+
- Access to Debian 12 or Debian 13 VPS for testing
- Text editor (VS Code recommended)
- Basic understanding of Bash scripting

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/oziTube.git
   cd oziTube/packages/oziDebianScript
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/original-repo-url
   ```

### Set Up Development Environment

1. Install recommended VS Code extensions:
   - ShellCheck
   - Bash IDE
   - Better Comments
   - GitLens

2. Configure Git:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your@email.com"
   ```

3. Create development branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

### Before Starting

1. Check existing issues and pull requests
2. Discuss major changes in an issue first
3. Follow the coding standards

### Development Steps

1. **Create Feature Branch:**
   ```bash
   git checkout -b feature/descriptive-name
   ```

2. **Make Changes:**
   - Follow coding standards (see below)
   - Write clear, maintainable code
   - Add comments for complex logic

3. **Test Locally:**
   ```bash
   # On Debian VPS
   cd /opt/oziscript
   bash install.sh
   ozi --version
   ```

4. **Verify with ShellCheck:**
   ```bash
   shellcheck modules/category/your_module.sh
   ```

5. **Commit Changes:**
   ```bash
   git add .
   git commit -m "Type: Clear description (#issue)"
   ```

6. **Push to Your Fork:**
   ```bash
   git push origin feature/descriptive-name
   ```

7. **Create Pull Request:**
   - Provide clear description
   - Reference related issues
   - Include testing notes

## Code Standards

### File Structure

Every new module must follow this structure:

```bash
#!/bin/bash
#================================================================
# Ozi Script - Module: {Name}
# Mô tả: {Description}
# Tác giả: {Your Name}
# Phiên bản: 1.0.0
#================================================================

set -euo pipefail

# Load dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/helpers.sh"
source "$SCRIPT_DIR/../../core/colors.sh"

#================================================================
# CONFIGURATION
#================================================================

MODULE_NAME="module_name"
MODULE_VERSION="1.0.0"

#================================================================
# PRIVATE FUNCTIONS
#================================================================

_private_function() {
    # Implementation
}

#================================================================
# PUBLIC COMMANDS
#================================================================

cmd_action() {
    # Implementation
}

#================================================================
# HELP AND MAIN
#================================================================

show_help() {
    cat << 'EOF'
Usage: ozi category {command} [options]

Commands:
    action      Description
    help        Show this help

Examples:
    ozi category action
EOF
}

main() {
    local cmd="${1:-help}"
    shift || true
    
    case "$cmd" in
        action)
            cmd_action "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $cmd"
            show_help
            return 1
            ;;
    esac
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && main "$@"
```

### Naming Conventions

**Files:**
- Lowercase with underscores: `my_module.sh`
- Descriptive names: `mail_config.sh` (not `mc.sh`)

**Functions:**
- Public commands: `cmd_action_name`
- Private functions: `_helper_function`
- Regular helpers: `setup_environment`

**Variables:**
- Constants: `UPPER_CASE_WITH_UNDERSCORES`
- Global variables: `GLOBAL_VAR_NAME`
- Local variables: `local_var_name`

**Examples:**
```bash
# Good
OZI_VERSION="1.0.0"
INSTALL_DIR="/opt/oziscript"
local site_domain="example.com"
function cmd_install() { }
function _validate_input() { }

# Avoid
VERSION=1.0  # Unclear scope
v="1.0"      # Unclear purpose
versionNum   # Mixed case
function install() { }  # Ambiguous (public or private?)
```

### Code Style

**Indentation:**
- Use 4 spaces (not tabs)
- Consistent across file

**Line Length:**
- Keep lines under 120 characters
- Break long lines logically

**Comments:**
- Use for complex logic
- Explain "why" not "what"
- Use `#================================================================` for section headers

**Example:**
```bash
# Good comment: explains purpose
# Calculate file size to determine if cleanup needed
file_size=$(stat -f%z "$file" 2>/dev/null || echo 0)

# Avoid: states obvious
# Get file size
file_size=$(stat -f%z "$file")
```

### Error Handling

Always validate and handle errors:

```bash
# Check inputs
[[ -z "$parameter" ]] && {
    print_error "Parameter required"
    return 1
}

# Check dependencies
require_root
validate_os
is_installed "required-package" || {
    print_error "Package not installed"
    return 1
}

# Handle command failures
if ! some_command; then
    print_error "Command failed"
    return 1
fi
```

### Output Standards

Use consistent output:

```bash
# Success
print_success "Operation completed"

# Error
print_error "Operation failed: reason"

# Warning
print_warning "This action is irreversible"

# Information
print_info "Starting installation..."

# Header
print_header "Section Title"
```

## Commit Guidelines

### Commit Message Format

```
{Type}: {Description} ({#issue})

Longer explanation if needed. 
Can span multiple lines.

Related to: #123
```

### Types

- **feat**: New feature or module
- **fix**: Bug fix
- **docs**: Documentation changes
- **refactor**: Code refactoring without feature changes
- **test**: Testing additions/changes
- **chore**: Build, CI, dependencies
- **style**: Code formatting (no logic change)

### Examples

**Good commits:**
```
feat: Add Redis cache management module (#45)

Implements installation, configuration, and management of Redis cache service.
- Install Redis from default Debian repository
- Auto-start on boot
- Include CLI commands for status and administration
- Comprehensive error handling

Related to: #45

---

fix: Handle missing user input in site creation (#62)

Prevent nil error when domain name not provided.
- Add input validation
- Display helpful error message
- Return proper exit code

---

docs: Update API reference for helper functions (#78)

Added comprehensive documentation for all core helper functions including:
- Function signatures
- Parameter descriptions
- Return values
- Usage examples
```

**Avoid:**
```
fix typo
update
wip
test
```

## Testing Requirements

### Local Testing

Test your changes on actual Debian VPS:

```bash
# 1. Backup current installation
cp -r /opt/oziscript /opt/oziscript.backup

# 2. Deploy your changes
scp -r . root@vps:/opt/oziscript

# 3. Test basic functionality
ssh root@vps 'ozi --version'

# 4. Test your specific module
ssh root@vps 'ozi category action'

# 5. Check logs
ssh root@vps 'tail -f /var/log/oziscript/ozi.log'

# 6. Test on both Debian 12 and 13
```

### Testing Checklist

Before submitting PR, verify:

- [ ] Code runs without syntax errors
- [ ] ShellCheck passes without warnings
- [ ] Works on Debian 12
- [ ] Works on Debian 13
- [ ] All user inputs validated
- [ ] Error messages are helpful
- [ ] Help text is accurate
- [ ] Color output displays correctly
- [ ] Logs are generated
- [ ] Documentation updated
- [ ] No unintended side effects

### Automated Testing

Run ShellCheck on your code:

```bash
# Install ShellCheck
sudo apt-get install shellcheck

# Check file
shellcheck modules/category/my_module.sh

# Check all modules
shellcheck modules/**/*.sh
```

### Manual Test Cases

Document test cases in TESTING.md:

```markdown
### Test [X] My Module

**Setup:**
- Prerequisites needed

**Steps:**
1. Select menu option
2. Perform action
3. Verify result

**Expected:**
- Command succeeds
- Proper output displayed
- Files created

**Verify:**
- Check `systemctl status`
- Check configuration file
- Run validation command
```

## Pull Request Process

### Before Submitting

1. **Update with latest changes:**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Test thoroughly:**
   - Follow testing checklist
   - Test on multiple Debian versions

3. **Update documentation:**
   - Update TESTING.md
   - Update API_REFERENCE.md (if applicable)
   - Update MODULE_CATALOG.md (if new module)
   - Update README.md (if major feature)

### PR Template

```markdown
## Description

Clear description of changes.

## Type of Change

- [ ] New feature
- [ ] Bug fix
- [ ] Documentation update
- [ ] Code refactoring

## Related Issue

Fixes #123

## Testing

Describe testing performed:

- [ ] Tested on Debian 12
- [ ] Tested on Debian 13
- [ ] Manually tested: [describe]
- [ ] ShellCheck passed

## Checklist

- [ ] Code follows style guidelines
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests pass
- [ ] Changes verified locally

## Screenshots (if applicable)

If UI changes, include screenshots.
```

### Review Process

Maintainers will:
1. Review code for quality
2. Check against standards
3. Verify testing
4. Request changes if needed
5. Merge when approved

## Issue Reporting

### Bug Reports

Include:
- Clear title
- Debian version
- Steps to reproduce
- Expected behavior
- Actual behavior
- Error messages/logs
- Environment details

**Template:**
```markdown
## Bug Description

Clear description of the issue.

## Steps to Reproduce

1. Step 1
2. Step 2
3. Result

## Expected Behavior

What should happen.

## Actual Behavior

What actually happens.

## Environment

- Debian: 12/13
- Ozi Script Version: 1.0.0
- Error Message: (if applicable)

## Logs

```
Relevant log content
```
```

### Feature Requests

Include:
- Clear description
- Use case
- Expected behavior
- Why this is useful
- Alternative solutions

**Template:**
```markdown
## Feature Request

## Description

What should be implemented.

## Use Case

When/why this is needed.

## Expected Behavior

How it should work.

## Example

```bash
# How user would use it
ozi category action
```

## Additional Context

Any other relevant information.
```

## Community

### Code of Conduct

We are committed to providing a welcoming and inclusive environment:

- Be respectful of others
- Assume good intentions
- Accept constructive criticism
- Focus on code, not people
- Help other contributors

### Getting Help

- Check existing documentation
- Search closed issues/PRs
- Ask in issue comments
- Contact maintainers

### Communication

- Use clear, professional language
- Provide context and details
- Be patient with responses
- Help others when possible

## Tips for Success

1. **Start small:** First PR should be minor
2. **Read existing code:** Learn project patterns
3. **Ask before big changes:** Discuss in issues first
4. **Test thoroughly:** Multiple Debian versions
5. **Write clear messages:** Help maintainers understand
6. **Be patient:** Reviews take time
7. **Iterate:** Respond to feedback constructively
8. **Keep learning:** Improve Bash skills continuously

## Resources

- [Bash Style Guide](https://google.github.io/styleguide/shellstyle.html)
- [ShellCheck](https://www.shellcheck.net/)
- [Git Documentation](https://git-scm.com/doc)
- [Debian Documentation](https://www.debian.org/doc/)

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Credited in release notes
- Given appropriate roles in project

## Questions?

- Open a discussion issue
- Contact maintainers
- Review existing documentation

---

**Thank you for contributing to Ozi Script! 🎉**

Version: 1.0.0  
Last Updated: 2026-01-23
