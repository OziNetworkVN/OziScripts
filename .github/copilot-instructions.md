# GitHub Copilot Instructions for Ozi Script

## Project Overview

**Ozi Script** is a command-line VPS management tool for Debian 12+ systems with a Vietnamese interface.

- **CLI Command:** `ozi`
- **Installation Directory:** `/opt/oziscript`
- **Language:** Bash script
- **Supported OS:** Debian 12 (Bookworm), Debian 13 (Trixie)
- **Configuration:** `/etc/oziscript/`
- **Logs:** `/var/log/oziscript/`

## Project Structure

```
packages/oziDebianScript/
├── ozi                      # Main CLI entry point
├── install.sh               # Installation script
├── uninstall.sh             # Uninstallation script
├── README.md                # Project documentation
├── TESTING.md               # Testing guide
├── core/                    # Core libraries
│   ├── colors.sh            # Terminal color utilities
│   ├── helpers.sh           # Helper functions (print, input, validation)
│   ├── config.sh            # Configuration management
│   ├── menu.sh              # Menu system and display
│   └── os.sh                # OS detection and validation
├── modules/                 # Feature modules
│   ├── system/              # System info and management
│   │   ├── info.sh          # System information display
│   │   └── swap.sh          # Swap space management
│   ├── stack/               # Infrastructure stack
│   │   ├── php.sh           # Multi-PHP installation (7.4, 8.1, 8.2, 8.3, 8.4)
│   │   ├── nginx.sh         # Nginx web server
│   │   ├── mysql.sh         # MySQL/MariaDB database
│   │   ├── postgresql.sh    # PostgreSQL database
│   │   ├── redis.sh         # Redis cache
│   │   ├── nodejs.sh        # Node.js (multi-version via NVM)
│   │   ├── composer.sh      # PHP Composer
│   │   └── supervisor.sh    # Process supervisor
│   ├── security/            # Security modules
│   │   ├── firewall.sh      # UFW firewall configuration
│   │   ├── ssh.sh           # SSH hardening
│   │   └── fail2ban.sh      # Fail2ban intrusion prevention
│   ├── site/                # Website management
│   │   ├── manage.sh        # Create/delete/list websites
│   │   └── cloudflare.sh    # Cloudflare SSL integration
│   ├── database/            # Database administration
│   │   └── admin.sh         # Adminer installation
│   ├── backup/              # Backup and restore
│   │   └── local.sh         # Local backup functionality
│   └── deploy/              # Application deployment
│       ├── laravel.sh       # Laravel deployment
│       ├── nodejs.sh        # Node.js app deployment
│       └── wordpress.sh     # WordPress deployment
├── templates/               # Configuration templates
│   └── nginx/               # Nginx configuration templates
│       ├── laravel.conf     # Laravel Nginx config
│       ├── laravel-octane.conf  # Laravel Octane config
│       ├── wordpress.conf   # WordPress Nginx config
│       └── nodejs.conf      # Node.js Nginx config
├── docs/                    # Documentation
│   ├── IMPLEMENTATION_PLAN.md   # Implementation details
│   └── TASK.md              # Task tracker
└── .agent/                  # Agent configuration
    ├── skills/              # Development skills
    └── workflows/           # Development workflows
```

## Coding Standards

### 1. File Headers
Every script file must start with a header:
```bash
#!/bin/bash
#================================================================
# Ozi Script - Module: [Module Name]
# Mô tả: [Brief Description]
# Tác giả: Ozi DevOps
# Phiên bản: 1.0.0
#================================================================
```

### 2. Strict Mode
Always enable strict mode at the beginning:
```bash
set -euo pipefail
IFS=$'\n\t'
```

### 3. Module Structure
```bash
#!/bin/bash
#================================================================
# Ozi Script - Module: Example
# Mô tả: Description
#================================================================

set -euo pipefail

# Load core modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/helpers.sh"
source "$SCRIPT_DIR/../../core/colors.sh"
source "$SCRIPT_DIR/../../core/config.sh"

#================================================================
# CONFIGURATION
#================================================================
MODULE_NAME="example"
MODULE_VERSION="1.0.0"

#================================================================
# FUNCTIONS
#================================================================

function cmd_list() {
    print_header "List Items"
    # Implementation
}

function cmd_create() {
    local name="${1:-}"
    [[ -z "$name" ]] && {
        print_error "Please provide a name"
        return 1
    }
    # Implementation
}

function show_help() {
    cat << 'EOF'
Usage: ozi example {command} [options]

Commands:
    list        List items
    create      Create new item
    help        Show this help

Examples:
    ozi example list
    ozi example create my-item
EOF
}

#================================================================
# MAIN
#================================================================

function main() {
    local cmd="${1:-help}"
    shift || true
    
    case "$cmd" in
        list)
            cmd_list "$@"
            ;;
        create)
            cmd_create "$@"
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

# Run if called directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
```

### 4. Core Helper Functions

#### Print Functions (from `core/helpers.sh`)
```bash
print_header "Title"           # Display header with border
print_subheader "Subtitle"     # Display subheader
print_success "Message"        # ✓ Green success message
print_error "Message"          # ✗ Red error message
print_warning "Message"        # ⚠ Yellow warning message
print_info "Message"           # ℹ Blue info message
print_menu_item "1" "Option"   # Menu option
print_separator                # Display separator line
```

#### Input Functions
```bash
read_choice "prompt" max_value        # Read numeric choice from user
read_input "prompt" default_value     # Read text input
confirm "prompt"                      # Ask yes/no question
```

#### Validation Functions
```bash
require_root                          # Exit if not running as root
validate_os                           # Verify Debian 12+
is_installed "package_name"           # Check if package is installed
check_port_available "port_number"    # Check if port is available
```

#### System Functions
```bash
get_public_ip                         # Get server public IP
get_debian_info                       # Get Debian version info
get_installed_php_versions            # List installed PHP versions
get_default_php_version               # Get default PHP version
```

### 5. Color Usage
Available colors from `core/colors.sh`:
```bash
RED='\033[0;31m'          # Red text
GREEN='\033[0;32m'        # Green text
YELLOW='\033[1;33m'       # Yellow text
BLUE='\033[0;34m'         # Blue text
MAGENTA='\033[0;35m'      # Magenta text
CYAN='\033[0;36m'         # Cyan text
BOLD_WHITE='\033[1;37m'   # Bold white
NC='\033[0m'              # No color (reset)
```

### 6. Command Structure
The CLI uses subcommand structure:
```bash
ozi {category} {action} [options]
```

Examples:
- `ozi system info` - Show system information
- `ozi php install 8.3` - Install PHP 8.3
- `ozi site create laravel mysite.com` - Create Laravel site
- `ozi backup create --db-only` - Create database-only backup
- `ozi nginx restart` - Restart Nginx

### 7. Error Handling
```bash
# Proper error handling pattern
if ! command_that_might_fail; then
    print_error "Operation failed"
    return 1
fi

# With error message
if ! command_that_might_fail 2>/dev/null; then
    print_error "Specific error message"
    return 1
fi

# With try-catch pattern
{
    command1
    command2
} || {
    print_error "One of the commands failed"
    cleanup_function  # If needed
    return 1
}
```

### 8. Variable Naming
- Use UPPER_CASE for constants and global variables
- Use lower_case for function local variables
- Use descriptive names that explain purpose
- Prefix local variables with underscore if needed

```bash
# Global constants
OZI_DIR="/opt/oziscript"
OZI_VERSION="1.0.0"

# Function variables
local site_name="$1"
local db_user="admin"
```

### 9. Function Naming
- Use descriptive names with underscore separator
- Prefix internal functions with underscore
- Use `cmd_` prefix for CLI commands

```bash
function cmd_list() { }         # CLI command
function cmd_create() { }       # CLI command
function _validate_input() { }  # Internal function
function setup_environment() { }  # Helper function
```

### 10. Logging and Output
```bash
# Use these patterns for consistent output

# For status messages
print_info "Starting installation..."
print_info "Installing PHP 8.3..."
print_success "PHP 8.3 installed successfully"

# For errors
print_error "Failed to install PHP"
print_error "Port 80 is already in use"

# For warnings
print_warning "This action cannot be undone"
print_warning "The service will be restarted"

# For confirmations
if confirm "Are you sure?"; then
    perform_action
fi
```

## Menu System

The menu system is defined in `core/menu.sh`. When adding new features:

1. Add menu item to appropriate submenu function
2. Define corresponding command handler in the module
3. Call module from main menu handler
4. Update `ozi` CLI script with new command path

Example menu item:
```bash
print_menu_item "1" "Create Website"
```

## Configuration Management

Configuration files are stored in `/etc/oziscript/`:
- Read/write operations handled by `core/config.sh`
- Use `config_set` and `config_get` functions
- Config format: `KEY=value` (bash-compatible)

## Testing Guidelines

1. **Manual Testing:** See `TESTING.md` for step-by-step testing
2. **Environment:** Test on both Debian 12 and Debian 13
3. **Integration:** Test with actual systems, not just syntax
4. **Documentation:** Update TESTING.md for new features

### Testing Checklist
- [ ] Feature works on Debian 12
- [ ] Feature works on Debian 13
- [ ] All error cases handled
- [ ] Help/documentation output correct
- [ ] Color output displays properly
- [ ] No unintended side effects
- [ ] Logs are generated correctly

## Important Notes

### Language
- All user-facing text must be in Vietnamese
- Comments can be in Vietnamese or English
- Function documentation in English is acceptable
- Help text (`show_help`) in Vietnamese

### Debian Compatibility
- Test on both Debian 12 (Bookworm) and Debian 13 (Trixie)
- Use `check_debian` for version validation
- Avoid version-specific features without fallback

### Dependencies
- Minimize external dependencies
- Use standard Unix tools (grep, sed, awk, etc.)
- For packages: use `apt-get` (Debian standard)

### Performance
- Keep operations interactive for long tasks
- Show progress for installations
- Avoid unnecessary system calls
- Optimize loops and file operations

## Adding New Modules

### Step 1: Plan the Module
- Define clear responsibilities
- List required functions
- Identify configuration needs
- Plan user interactions

### Step 2: Create Module File
```bash
# Create file: modules/{category}/{module_name}.sh
touch modules/category/module_name.sh
```

### Step 3: Implement Module
- Follow standard template structure
- Use core helper functions
- Add error handling
- Include help text

### Step 4: Integrate into CLI
Edit `ozi` script to add:
```bash
case "$1" in
    {category})
        case "${2:-}" in
            {action})
                source "$OZI_DIR/modules/{category}/{module_name}.sh"
                main "${@:3}"
                ;;
        esac
        ;;
esac
```

### Step 5: Add Menu Entry
Edit `core/menu.sh`:
```bash
function menu_{name}() {
    show_submenu_header "MODULE TITLE"
    print_menu_item "1" "Action 1"
    print_menu_item "2" "Action 2"
    print_menu_back
}
```

### Step 6: Document
- Add entry to `docs/TASK.md`
- Update `README.md` if needed
- Add testing steps to `TESTING.md`

### Step 7: Test
- Test on Debian 12 and 13
- Verify all commands
- Check help text
- Verify error handling

## Common Patterns

### Pattern: Check if Package Installed
```bash
if is_installed "nginx"; then
    print_info "Nginx is already installed"
else
    print_info "Installing Nginx..."
    apt-get install -y nginx
fi
```

### Pattern: Ask for Confirmation
```bash
if confirm "Do you want to proceed?"; then
    perform_action
    print_success "Operation completed"
else
    print_info "Operation cancelled"
fi
```

### Pattern: Get User Input
```bash
print_info "Enter website name:"
read -p "$(echo -e "${BOLD_WHITE}Domain: ${NC}")" domain_name

[[ -z "$domain_name" ]] && {
    print_error "Domain name cannot be empty"
    return 1
}
```

### Pattern: Check if Port Available
```bash
if check_port_available 80; then
    print_info "Port 80 is available"
else
    print_error "Port 80 is already in use"
    return 1
fi
```

### Pattern: Service Management
```bash
# Start service
systemctl start nginx
print_success "Nginx started"

# Check status
if systemctl is-active nginx >/dev/null; then
    print_info "Nginx is running"
fi

# Reload config
systemctl reload nginx
print_success "Nginx config reloaded"
```

## Troubleshooting for Developers

### Issue: Scripts not executable
```bash
chmod +x /opt/oziscript/ozi
chmod +x /opt/oziscript/modules/**/*.sh
chmod +x /opt/oziscript/core/*.sh
```

### Issue: Command not found
```bash
# Ensure symlink exists
ln -sf /opt/oziscript/ozi /usr/local/bin/ozi

# Check it
which ozi
ozi --version
```

### Issue: Color output not showing
- Verify terminal supports ANSI colors
- Check that functions use color variables correctly
- Use `${COLOR}text${NC}` pattern

### Issue: Config not persisting
- Verify `/etc/oziscript/` directory exists
- Check file permissions
- Use `config_set` and `config_get` functions

## Version Control

Current version: **1.0.0**

When modifying:
- Update version in:
  - `ozi` script header
  - `install.sh` header
  - Module headers if significant changes
  - `README.md` version section

## References

- **Main CLI:** [ozi](./ozi)
- **Core Helpers:** [core/helpers.sh](./core/helpers.sh)
- **Colors Module:** [core/colors.sh](./core/colors.sh)
- **Menu System:** [core/menu.sh](./core/menu.sh)
- **Implementation Plan:** [docs/IMPLEMENTATION_PLAN.md](./docs/IMPLEMENTATION_PLAN.md)
- **Testing Guide:** [TESTING.md](./TESTING.md)
- **Task Tracker:** [docs/TASK.md](./docs/TASK.md)
