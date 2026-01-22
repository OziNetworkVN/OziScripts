# Ozi Script - Complete Developer Guide

## Table of Contents

1. [Project Overview](#project-overview)
2. [Getting Started](#getting-started)
3. [Architecture](#architecture)
4. [Module Development](#module-development)
5. [CLI Command Structure](#cli-command-structure)
6. [Best Practices](#best-practices)
7. [Testing](#testing)
8. [Deployment](#deployment)
9. [Troubleshooting](#troubleshooting)

## Project Overview

**Ozi Script** is a comprehensive VPS management toolkit for Debian 12+ systems. It provides a menu-driven CLI interface (fully in Vietnamese) for:

- System administration and monitoring
- Multi-version PHP management
- Web server configuration (Nginx)
- Database management (PostgreSQL, MySQL)
- Website creation and management
- SSL/TLS certificate management (Cloudflare integration)
- Security configuration (Firewall, SSH hardening, Fail2ban)
- Backup and restore operations
- Application deployment (Laravel, Node.js, WordPress)

### Key Features

| Feature | Description |
|---------|-------------|
| **Multi-PHP** | Install and manage PHP 7.4, 8.1, 8.2, 8.3, 8.4 |
| **Nginx** | Automated Nginx configuration and management |
| **Databases** | PostgreSQL, MySQL/MariaDB, Redis |
| **SSL** | 15-year Cloudflare Origin Certificates |
| **Websites** | Quick setup for Laravel, WordPress, Node.js |
| **Security** | UFW, SSH hardening, Fail2ban |
| **Backup** | Full backup of files and databases |
| **Deploy** | Automated deployment for Laravel, Node.js, WordPress |

## Getting Started

### Prerequisites

- Debian 12 (Bookworm) or Debian 13 (Trixie)
- Root access
- Git (for development)
- Basic Bash knowledge

### Development Environment Setup

1. **Clone or download the project:**
   ```bash
   cd d:/laragon/www/oziTube/packages/oziDebianScript
   ```

2. **Review the documentation:**
   - Read `README.md` for project overview
   - Read `TESTING.md` for testing procedures
   - Read `docs/IMPLEMENTATION_PLAN.md` for architecture details

3. **Understand the structure:**
   - Core modules in `core/`
   - Feature modules in `modules/`
   - Templates in `templates/`

4. **Set up editor configuration:**
   - VS Code extensions: ShellCheck, Bash IDE, Better Comments
   - Use provided `.vscode/settings.json`

### First Time Running

```bash
# On a Debian 12/13 VPS:
cd /opt/oziscript
bash install.sh

# Start using:
ozi

# View version:
ozi --version

# Get help:
ozi --help
```

## Architecture

### Directory Structure Deep Dive

```
oziDebianScript/
├── .github/
│   └── copilot-instructions.md    # GitHub Copilot instructions
├── .agent/
│   ├── skills/
│   │   └── oziscript-dev/         # Development skills
│   └── workflows/                  # Workflow definitions
├── .vscode/
│   ├── settings.json              # VS Code settings
│   └── launch.json                # Debug configuration
├── core/                          # Core libraries (shared by all modules)
│   ├── colors.sh                  # Terminal color definitions
│   ├── helpers.sh                 # Helper functions (142 functions)
│   ├── config.sh                  # Configuration management
│   ├── menu.sh                    # Menu system and display
│   └── os.sh                      # OS detection and validation
├── modules/                       # Feature modules
│   ├── system/
│   │   ├── info.sh                # System information and statistics
│   │   └── swap.sh                # Swap space management
│   ├── stack/
│   │   ├── php.sh                 # Multi-PHP installer
│   │   ├── nginx.sh               # Nginx installation and config
│   │   ├── mysql.sh               # MySQL/MariaDB installer
│   │   ├── postgresql.sh          # PostgreSQL installer
│   │   ├── redis.sh               # Redis installation
│   │   ├── nodejs.sh              # Node.js (NVM) installer
│   │   ├── composer.sh            # PHP Composer installer
│   │   └── supervisor.sh          # Supervisor installation
│   ├── security/
│   │   ├── firewall.sh            # UFW firewall configuration
│   │   ├── ssh.sh                 # SSH hardening
│   │   └── fail2ban.sh            # Fail2ban installation
│   ├── site/
│   │   ├── manage.sh              # Website CRUD operations
│   │   └── cloudflare.sh          # Cloudflare SSL integration
│   ├── database/
│   │   └── admin.sh               # Adminer installation
│   ├── backup/
│   │   └── local.sh               # Local backup functionality
│   └── deploy/
│       ├── laravel.sh             # Laravel deployment
│       ├── nodejs.sh              # Node.js deployment
│       └── wordpress.sh           # WordPress deployment
├── templates/
│   └── nginx/
│       ├── laravel.conf           # Laravel Nginx config
│       ├── laravel-octane.conf    # Octane Nginx config
│       ├── wordpress.conf         # WordPress Nginx config
│       └── nodejs.conf            # Node.js Nginx config
├── docs/
│   ├── IMPLEMENTATION_PLAN.md     # Original implementation plan
│   └── TASK.md                    # Task tracker
├── ozi                            # Main CLI entry point (102 lines)
├── install.sh                     # Installation script (182 lines)
├── uninstall.sh                   # Uninstallation script
├── README.md                      # Project README
└── TESTING.md                     # Testing guide
```

### Core Modules Explained

#### colors.sh (40 lines)
Defines terminal color codes and styling for consistent output across all modules.

**Provides:**
- Color variables (RED, GREEN, YELLOW, BLUE, CYAN, MAGENTA)
- Bold/bright variants (BOLD_WHITE, etc.)
- Box drawing characters (BOX_TL, BOX_TR, etc.)

#### helpers.sh (342 lines)
Central helper function library used by all other modules.

**Categories:**
- Print functions (8 functions)
- Input functions (4 functions)
- Validation functions (10 functions)
- System information (12 functions)
- Package management (8 functions)
- File and directory operations (12 functions)
- Service management (8 functions)
- Port checking (3 functions)
- Date/time utilities (4 functions)

#### config.sh (80 lines)
Configuration management for persistent settings.

**Features:**
- Load/save configuration files
- Get/set individual config values
- Initialize default configuration
- Config file location: `/etc/oziscript/config`

#### menu.sh (517 lines)
Complete menu system and display logic.

**Provides:**
- Main menu display
- All submenu displays (10+ submenus)
- Menu navigation logic
- Module handlers for each menu item

#### os.sh (70 lines)
Operating system detection and validation.

**Functions:**
- Verify Debian 12+ requirement
- Get OS information
- Check system capabilities
- Get hardware information

### Module Development Pattern

Every module follows this pattern:

```bash
#!/bin/bash
#================================================================
# Ozi Script - Module: {Name}
# Description: {What it does}
#================================================================

set -euo pipefail

# Load dependencies
source "$(dirname "$0")/../../core/helpers.sh"
source "$(dirname "$0")/../../core/colors.sh"

#================================================================
# CONFIGURATION
#================================================================
# Module-specific constants

#================================================================
# PRIVATE FUNCTIONS
#================================================================
_private_helper() { }
_validate_params() { }

#================================================================
# PUBLIC COMMANDS
#================================================================
cmd_action1() { }
cmd_action2() { }

#================================================================
# HELP AND MAIN
#================================================================
show_help() { }
main() { }

# Auto-run if called directly
[[ "${BASH_SOURCE[0]}" == "$0" ]] && main "$@"
```

## Module Development

### Step 1: Planning

Before coding, plan your module:

1. **Define Purpose:** What problem does this solve?
2. **Identify Commands:** What actions should users take?
3. **Determine Inputs:** What information do users provide?
4. **Plan Outputs:** What results should users see?
5. **List Dependencies:** What packages/services are needed?

Example:
```
Module: Cache Management
Purpose: Install, configure, and manage Redis cache
Commands: 
  - install: Install Redis
  - config: Configure Redis settings
  - status: Check Redis status
Inputs: Port, memory limit, password
Dependencies: redis-server
```

### Step 2: Create Module File

```bash
touch modules/category/module_name.sh
chmod +x modules/category/module_name.sh
```

### Step 3: Implement Core Functions

```bash
#!/bin/bash
#================================================================
# Ozi Script - Module: Your Module
# Mô tả: What this module does
#================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/helpers.sh"
source "$SCRIPT_DIR/../../core/colors.sh"

#================================================================
# CONFIGURATION
#================================================================

MODULE_NAME="mymodule"
MODULE_VERSION="1.0.0"

# Module-specific settings
DEFAULT_PORT=6379
CONFIG_FILE="/etc/mymodule/config"

#================================================================
# PRIVATE FUNCTIONS
#================================================================

_validate_port() {
    local port="$1"
    [[ ! "$port" =~ ^[0-9]+$ ]] && {
        print_error "Port must be a number"
        return 1
    }
    [[ "$port" -lt 1 || "$port" -gt 65535 ]] && {
        print_error "Port must be between 1 and 65535"
        return 1
    }
}

_check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! is_installed "build-essential"; then
        print_info "Installing build tools..."
        apt-get update
        apt-get install -y build-essential
    fi
}

#================================================================
# PUBLIC COMMANDS
#================================================================

cmd_install() {
    print_header "Installing My Module"
    
    require_root
    _check_prerequisites
    
    print_info "Installing packages..."
    apt-get install -y mymodule
    
    print_info "Configuring module..."
    systemctl start mymodule
    systemctl enable mymodule
    
    print_success "Installation complete!"
}

cmd_status() {
    print_header "My Module Status"
    
    if is_installed "mymodule"; then
        if systemctl is-active mymodule >/dev/null; then
            print_success "My Module is running"
            systemctl status mymodule
        else
            print_warning "My Module is not running"
        fi
    else
        print_error "My Module is not installed"
        return 1
    fi
}

cmd_config() {
    local setting="$1"
    local value="$2"
    
    [[ -z "$setting" ]] && {
        print_error "Please specify setting"
        return 1
    }
    
    [[ -z "$value" ]] && {
        print_error "Please specify value"
        return 1
    }
    
    print_info "Configuring $setting=$value..."
    # Implementation here
    print_success "Configuration updated"
}

#================================================================
# HELP
#================================================================

show_help() {
    cat << 'EOF'
Usage: ozi mymodule {command} [options]

Commands:
    install     Install My Module
    status      Show module status
    config      Configure settings
    help        Show this help

Examples:
    ozi mymodule install
    ozi mymodule status
    ozi mymodule config setting value
EOF
}

#================================================================
# MAIN
#================================================================

main() {
    local cmd="${1:-help}"
    shift || true
    
    case "$cmd" in
        install)
            cmd_install "$@"
            ;;
        status)
            cmd_status "$@"
            ;;
        config)
            cmd_config "$@"
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

### Step 4: Integrate Into CLI

Edit the main `ozi` script:

```bash
# Find the appropriate category in the case statement
# Add your module handler:

case "$1" in
    mymodule)
        require_root
        source "$OZI_DIR/modules/category/module_name.sh"
        main "${@:2}"
        ;;
esac
```

### Step 5: Add to Menu System

Edit `core/menu.sh` to add menu item:

```bash
# In the main menu function:
menu_main() {
    show_banner
    
    echo -e "${BOLD_WHITE}  MENU CHÍNH${NC}"
    print_separator
    echo ""
    
    # ... existing items ...
    print_menu_item "11" "My Module"  # Add this
    
    print_menu_exit
}

# Add handler in the main menu loop:
case "$choice" in
    11)
        menu_mymodule
        read_choice "Nhập lựa chọn" "3"
        case "$?" in
            1) cmd_install ;;
            2) cmd_status ;;
            0) continue ;;
        esac
        ;;
esac

# Create the submenu:
menu_mymodule() {
    show_submenu_header "MY MODULE"
    
    print_menu_item "1" "Install"
    print_menu_item "2" "Status"
    
    print_menu_back
}
```

### Step 6: Add Testing

Create test cases in `TESTING.md`:

```markdown
### Test [X] My Module
- Chọn `X` → `1` (Install)
- Kiểm tra: `systemctl status mymodule` chạy
- Chọn `X` → `2` (Status)
- Kiểm tra: Shows running status
```

### Step 7: Update Documentation

Update `docs/TASK.md`:

```markdown
- [x] Module: My Module
```

Update `README.md` features section if significant.

## CLI Command Structure

### Command Format

```bash
ozi {category} {action} [arguments] [options]
```

### Category Organization

| Category | Purpose | Example |
|----------|---------|---------|
| system | System administration | `ozi system info` |
| php | PHP management | `ozi php install 8.3` |
| nginx | Web server | `ozi nginx restart` |
| database | Database tools | `ozi database status` |
| site | Website management | `ozi site create laravel example.com` |
| ssl | Certificate management | `ozi ssl cloudflare` |
| security | Security config | `ozi security firewall` |
| backup | Backup/restore | `ozi backup create` |
| deploy | Application deploy | `ozi deploy laravel` |

### Help System

Every command should support:
```bash
ozi {category} help
ozi {category} {action} --help
ozi {category} -h
```

### Example Commands

```bash
# System commands
ozi system info
ozi system swap enable

# PHP commands
ozi php install 8.3
ozi php list
ozi php set-default 8.3

# Website commands
ozi site create laravel example.com
ozi site list
ozi site delete example.com

# Backup commands
ozi backup create --full
ozi backup restore backup-2026-01-23.tar.gz
ozi backup list
```

## Best Practices

### 1. Error Handling

**DO:** Validate all inputs
```bash
cmd_action() {
    local param="${1:-}"
    [[ -z "$param" ]] && {
        print_error "Parameter required"
        return 1
    }
    # Continue...
}
```

**DO:** Check dependencies
```bash
require_root
validate_os
is_installed "required-package" || {
    print_error "Package not installed"
    return 1
}
```

**DON'T:** Ignore errors silently
```bash
# BAD:
apt-get install nginx >/dev/null 2>&1

# GOOD:
if ! apt-get install -y nginx; then
    print_error "Failed to install Nginx"
    return 1
fi
```

### 2. User Feedback

**Always provide feedback:**
```bash
print_info "Starting operation..."
# Do something
print_success "Operation completed successfully"

# For errors:
print_error "Operation failed: specific reason"

# For warnings:
print_warning "This will delete data"
```

**Ask before destructive operations:**
```bash
if confirm "Delete all data?"; then
    delete_data
    print_success "Data deleted"
else
    print_info "Operation cancelled"
fi
```

### 3. Code Organization

**Group related functions:**
```bash
#================================================================
# INSTALLATION FUNCTIONS
#================================================================
_install_package() { }
_configure_package() { }
_verify_installation() { }

#================================================================
# CONFIGURATION FUNCTIONS
#================================================================
_load_config() { }
_save_config() { }
_validate_config() { }

#================================================================
# UTILITY FUNCTIONS
#================================================================
_get_status() { }
_format_output() { }
```

### 4. Variable Naming

```bash
# Constants (UPPER_CASE)
OZI_VERSION="1.0.0"
INSTALL_DIR="/opt/oziscript"
MAX_RETRIES=5

# Function variables (lower_case)
local site_name="$1"
local config_file="/etc/myapp/config"
local retry_count=0

# Temporary variables (_prefixed)
local _temp_dir
local _backup_file
```

### 5. Function Documentation

```bash
# Document complex functions
#
# cmd_deploy_app
# 
# Deploy an application to the server
#
# Usage:
#   cmd_deploy_app {app_name} {version}
#
# Arguments:
#   app_name    Name of application to deploy
#   version     Version to deploy (optional, default: latest)
#
# Returns:
#   0 on success
#   1 on failure
#
# Environment:
#   Requires root privileges
#   Requires app_name to exist in /opt/apps/
#
cmd_deploy_app() {
    local app_name="$1"
    # ...
}
```

### 6. Logging

Implement logging in modules:
```bash
# Log file location
LOG_FILE="/var/log/oziscript/mymodule.log"

log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"
}

log_info() { log_message "INFO" "$1"; }
log_error() { log_message "ERROR" "$1"; }
log_warning() { log_message "WARN" "$1"; }
```

### 7. Configuration Files

Use standard Bash config format:
```bash
# /etc/oziscript/config
OZI_ADMIN_EMAIL="admin@example.com"
OZI_BACKUP_RETENTION_DAYS=30
OZI_LOG_LEVEL="INFO"

# Load in modules:
if [[ -f /etc/oziscript/config ]]; then
    source /etc/oziscript/config
fi
```

## Testing

### Manual Testing Process

1. **Setup test VPS:**
   ```bash
   # On Debian 12/13 VPS
   cd /opt/oziscript
   ```

2. **Run tests from TESTING.md:**
   - Start with menu tests
   - Test each module systematically
   - Document any issues

3. **Automated Testing:**
   - Create test scripts in `tests/` directory
   - Test command execution
   - Verify output formatting
   - Check error handling

Example test:
```bash
#!/bin/bash
# tests/test_system_info.sh

source /opt/oziscript/core/colors.sh
source /opt/oziscript/core/helpers.sh

test_get_public_ip() {
    local ip
    ip=$(get_public_ip)
    [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && {
        echo "✓ get_public_ip works"
        return 0
    }
    echo "✗ get_public_ip failed"
    return 1
}

test_get_public_ip
```

### Testing Checklist

- [ ] Feature works on Debian 12
- [ ] Feature works on Debian 13
- [ ] All error cases handled gracefully
- [ ] Help text is clear and accurate
- [ ] Color output displays correctly
- [ ] No unintended side effects
- [ ] Logs generated correctly
- [ ] All user inputs validated
- [ ] Permissions checked correctly
- [ ] Documentation updated

## Deployment

### Production Deployment

1. **Testing Phase:**
   - Test on staging VPS (Debian 13)
   - Verify all modules work
   - Check logs for errors

2. **Backup Existing:**
   ```bash
   cp -r /opt/oziscript /opt/oziscript.backup.$(date +%Y%m%d)
   ```

3. **Deploy New Version:**
   ```bash
   scp -r . root@production-vps:/opt/oziscript
   ssh root@production-vps 'chmod +x /opt/oziscript/ozi'
   ```

4. **Verify Installation:**
   ```bash
   ssh root@production-vps 'ozi --version'
   ```

5. **Test Key Functions:**
   - Run menu navigation tests
   - Test critical modules
   - Monitor logs

### Version Updates

When updating version:

1. Update `OZI_VERSION` in `ozi` script
2. Update version in `install.sh`
3. Update module versions if significant changes
4. Update `README.md`
5. Create release notes

## Troubleshooting

### Common Issues

#### Issue: "Command not found: ozi"
```bash
# Check if installed
test -f /opt/oziscript/ozi

# Check symlink
ls -l /usr/local/bin/ozi

# Fix:
ln -sf /opt/oziscript/ozi /usr/local/bin/ozi
```

#### Issue: Permission denied
```bash
# Check file permissions
ls -l /opt/oziscript/ozi

# Fix:
chmod +x /opt/oziscript/ozi
chmod +x /opt/oziscript/modules/**/*.sh
chmod +x /opt/oziscript/core/*.sh
```

#### Issue: Colors not showing
- Verify terminal is ANSI-capable
- Check that `source core/colors.sh` is in module
- Ensure `${COLOR}text${NC}` pattern used

#### Issue: Config not saving
- Verify `/etc/oziscript/` exists with correct permissions
- Check that `config_set` function is used
- Verify config file is readable/writable

#### Issue: Module fails with "source: not found"
- Check relative paths in source statements
- Use `SCRIPT_DIR` variable consistently
- Verify all required files exist

### Debugging

Enable debug mode in modules:
```bash
# At top of module
set -x  # Enable debug output

# ... code ...

set +x  # Disable debug output
```

View system logs:
```bash
# Installation logs
tail -f /var/log/oziscript/ozi.log

# System logs
tail -f /var/log/apt/history.log

# Service logs
journalctl -xe
```

### Getting Help

- Check existing modules for patterns
- Review `core/helpers.sh` for available functions
- Consult `docs/IMPLEMENTATION_PLAN.md` for architecture
- Test on actual Debian systems (not containers if possible)

## Contributing Guidelines

When contributing:

1. **Follow coding standards** in this guide
2. **Test thoroughly** on Debian 12 and 13
3. **Document changes** in relevant .md files
4. **Update TESTING.md** with test cases
5. **Update TASK.md** task tracker
6. **Ensure backward compatibility**
7. **Get code review** before merging

## Resources

- [Bash Scripting Guide](https://www.gnu.org/software/bash/manual/)
- [ShellCheck](https://www.shellcheck.net/) - Static analysis tool
- [Debian Documentation](https://www.debian.org/doc/)
- [SystemD Documentation](https://systemd.io/)

---

**Version:** 1.0.0  
**Last Updated:** 2026-01-23  
**Maintained by:** Ozi DevOps Team
