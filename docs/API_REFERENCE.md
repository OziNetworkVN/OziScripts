# Ozi Script - Core Functions API Reference

## Overview

This document lists all available helper functions in the Ozi Script core library. These functions can be used in any module.

## Print Functions

### `print_header [title]`

Display a formatted header with borders.

**Usage:**
```bash
print_header "Installation Complete"
```

**Output:**
```
╔══════════════════════════════════════════════════════════════╗
║              Installation Complete
╚══════════════════════════════════════════════════════════════╝
```

---

### `print_subheader [title]`

Display a smaller subheader.

**Usage:**
```bash
print_subheader "Database Configuration"
```

**Output:**
```
━━━ Database Configuration ━━━
```

---

### `print_success [message]`

Print a green success message with checkmark.

**Usage:**
```bash
print_success "Installation successful"
```

**Output:**
```
✓ Installation successful
```

---

### `print_error [message]`

Print a red error message with cross mark.

**Usage:**
```bash
print_error "Failed to install package"
```

**Output:**
```
✗ Failed to install package
```

---

### `print_warning [message]`

Print a yellow warning message.

**Usage:**
```bash
print_warning "This action is irreversible"
```

**Output:**
```
⚠ This action is irreversible
```

---

### `print_info [message]`

Print a blue informational message.

**Usage:**
```bash
print_info "Starting installation process"
```

**Output:**
```
ℹ Starting installation process
```

---

### `print_menu_item [number] [text]`

Print a menu item with number and description.

**Usage:**
```bash
print_menu_item "1" "Install PHP"
print_menu_item "2" "Configure Nginx"
```

**Output:**
```
  [1] Install PHP
  [2] Configure Nginx
```

---

### `print_menu_back`

Print a "back" menu option.

**Usage:**
```bash
print_menu_back
```

**Output:**
```

  [0] ← Quay lại
```

---

### `print_menu_exit`

Print an "exit" menu option.

**Usage:**
```bash
print_menu_exit
```

**Output:**
```

  [0] Thoát
```

---

### `print_separator`

Print a separator line.

**Usage:**
```bash
print_separator
```

**Output:**
```
────────────────────────────────────────────────────────────────
```

---

## Input Functions

### `read_choice [prompt] [max]`

Read a numeric choice from user within range 0 to max.

**Parameters:**
- `prompt` - Prompt message to display
- `max` - Maximum allowed choice number

**Usage:**
```bash
if read_choice "Select option" 5; then
    choice=$?
fi
```

**Returns:**
- 0-max: User's choice
- 1: Invalid input

---

### `read_input [prompt] [default]`

Read text input from user.

**Parameters:**
- `prompt` - Prompt message to display
- `default` - Default value if user presses Enter

**Usage:**
```bash
read_input "Enter domain name" "example.com"
domain_name="$?"
```

---

### `confirm [prompt]`

Ask user for yes/no confirmation.

**Parameters:**
- `prompt` - Question to ask user

**Usage:**
```bash
if confirm "Delete all files?"; then
    delete_files
else
    echo "Cancelled"
fi
```

**Returns:**
- 0: User confirmed
- 1: User declined

---

## Validation Functions

### `require_root`

Exit script if not running as root.

**Usage:**
```bash
require_root  # Exits with error if not root
```

**Exit Code:** 1 (if not root)

---

### `validate_os`

Exit script if not on Debian 12+.

**Usage:**
```bash
validate_os  # Exits with error if not Debian 12+
```

**Exit Code:** 1 (if not Debian 12+)

---

### `is_installed [package]`

Check if a package is installed.

**Parameters:**
- `package` - Package name to check

**Usage:**
```bash
if is_installed "nginx"; then
    echo "Nginx is installed"
fi
```

**Returns:**
- 0: Package is installed
- 1: Package not found

---

### `check_port_available [port]`

Check if a port is available (not in use).

**Parameters:**
- `port` - Port number to check

**Usage:**
```bash
if check_port_available 80; then
    echo "Port 80 is available"
else
    echo "Port 80 is in use"
fi
```

**Returns:**
- 0: Port is available
- 1: Port is in use

---

### `validate_domain [domain]`

Validate domain name format.

**Parameters:**
- `domain` - Domain to validate

**Usage:**
```bash
if validate_domain "example.com"; then
    echo "Valid domain"
fi
```

**Returns:**
- 0: Valid domain
- 1: Invalid domain

---

### `validate_email [email]`

Validate email address format.

**Parameters:**
- `email` - Email to validate

**Usage:**
```bash
if validate_email "user@example.com"; then
    echo "Valid email"
fi
```

**Returns:**
- 0: Valid email
- 1: Invalid email

---

## System Information Functions

### `get_public_ip`

Get server's public IP address.

**Usage:**
```bash
ip=$(get_public_ip)
echo "Server IP: $ip"
```

**Returns:** IP address or "Unknown"

---

### `get_debian_info`

Get Debian version information.

**Usage:**
```bash
info=$(get_debian_info)
echo "System: $info"
```

**Returns:** "Debian GNU/Linux 12 (bookworm)" or similar

---

### `get_installed_php_versions`

Get list of installed PHP versions.

**Usage:**
```bash
versions=$(get_installed_php_versions)
echo "Installed: $versions"
```

**Returns:** Space-separated list like "7.4 8.1 8.3"

---

### `get_default_php_version`

Get the default PHP version.

**Usage:**
```bash
php_version=$(get_default_php_version)
echo "Default PHP: $php_version"
```

**Returns:** Version number like "8.3" or empty

---

### `get_system_memory`

Get total system memory in MB.

**Usage:**
```bash
memory=$(get_system_memory)
echo "Memory: ${memory}MB"
```

**Returns:** Integer (MB)

---

### `get_free_memory`

Get available memory in MB.

**Usage:**
```bash
free=$(get_free_memory)
echo "Free: ${free}MB"
```

**Returns:** Integer (MB)

---

### `get_disk_space`

Get disk usage information.

**Usage:**
```bash
space=$(get_disk_space /)
echo "Space: $space"
```

**Returns:** Formatted string with usage percentage

---

### `get_cpu_info`

Get CPU information.

**Usage:**
```bash
cpu=$(get_cpu_info)
echo "CPU: $cpu"
```

**Returns:** CPU description and core count

---

## Package Management Functions

### `apt_update`

Update package lists safely.

**Usage:**
```bash
apt_update
```

---

### `apt_install [packages...]`

Install one or more packages.

**Parameters:**
- `packages` - Package names to install

**Usage:**
```bash
apt_install nginx php8.3 mysql-server
```

---

### `apt_remove [packages...]`

Remove one or more packages.

**Parameters:**
- `packages` - Package names to remove

**Usage:**
```bash
apt_remove apache2 nginx
```

---

### `apt_purge [packages...]`

Remove packages with configuration files.

**Parameters:**
- `packages` - Package names to purge

**Usage:**
```bash
apt_purge nginx
```

---

## Service Management Functions

### `service_start [service]`

Start a service.

**Parameters:**
- `service` - Service name

**Usage:**
```bash
service_start nginx
```

---

### `service_stop [service]`

Stop a service.

**Parameters:**
- `service` - Service name

**Usage:**
```bash
service_stop nginx
```

---

### `service_restart [service]`

Restart a service.

**Parameters:**
- `service` - Service name

**Usage:**
```bash
service_restart nginx
```

---

### `service_reload [service]`

Reload service configuration.

**Parameters:**
- `service` - Service name

**Usage:**
```bash
service_reload nginx
```

---

### `service_enable [service]`

Enable service to start on boot.

**Parameters:**
- `service` - Service name

**Usage:**
```bash
service_enable nginx
```

---

### `service_disable [service]`

Disable service from starting on boot.

**Parameters:**
- `service` - Service name

**Usage:**
```bash
service_disable nginx
```

---

### `service_status [service]`

Check if service is running.

**Parameters:**
- `service` - Service name

**Usage:**
```bash
if service_status nginx; then
    echo "Nginx is running"
fi
```

**Returns:**
- 0: Service is running
- 1: Service is not running

---

## File Operations

### `file_exists [path]`

Check if file exists.

**Parameters:**
- `path` - File path

**Usage:**
```bash
if file_exists "/etc/nginx/nginx.conf"; then
    echo "Config exists"
fi
```

**Returns:**
- 0: File exists
- 1: File not found

---

### `dir_exists [path]`

Check if directory exists.

**Parameters:**
- `path` - Directory path

**Usage:**
```bash
if dir_exists "/var/www/sites"; then
    echo "Directory exists"
fi
```

**Returns:**
- 0: Directory exists
- 1: Directory not found

---

### `backup_file [source] [destination]`

Create a backup copy of file.

**Parameters:**
- `source` - Original file path
- `destination` - Backup file path

**Usage:**
```bash
backup_file "/etc/nginx/nginx.conf" "/etc/nginx/nginx.conf.bak"
```

---

### `append_file [file] [content]`

Append content to file.

**Parameters:**
- `file` - File path
- `content` - Content to append

**Usage:**
```bash
append_file "/etc/hosts" "127.0.0.1 localhost"
```

---

## Configuration Functions

### `config_set [key] [value]`

Set configuration value.

**Parameters:**
- `key` - Configuration key
- `value` - Configuration value

**Usage:**
```bash
config_set "ADMIN_EMAIL" "admin@example.com"
```

---

### `config_get [key]`

Get configuration value.

**Parameters:**
- `key` - Configuration key

**Usage:**
```bash
email=$(config_get "ADMIN_EMAIL")
echo "Admin: $email"
```

---

### `config_has [key]`

Check if configuration key exists.

**Parameters:**
- `key` - Configuration key

**Usage:**
```bash
if config_has "ADMIN_EMAIL"; then
    echo "Admin email is configured"
fi
```

**Returns:**
- 0: Key exists
- 1: Key not found

---

### `config_delete [key]`

Delete configuration value.

**Parameters:**
- `key` - Configuration key

**Usage:**
```bash
config_delete "ADMIN_EMAIL"
```

---

## Database Functions

### `mysql_check_connection [host] [user] [password]`

Check MySQL/MariaDB connection.

**Parameters:**
- `host` - Database host
- `user` - Database user
- `password` - Database password

**Usage:**
```bash
if mysql_check_connection "localhost" "root" "password"; then
    echo "MySQL is accessible"
fi
```

**Returns:**
- 0: Connection successful
- 1: Connection failed

---

### `postgresql_check_connection [host] [user]`

Check PostgreSQL connection.

**Parameters:**
- `host` - Database host
- `user` - Database user

**Usage:**
```bash
if postgresql_check_connection "localhost" "postgres"; then
    echo "PostgreSQL is accessible"
fi
```

**Returns:**
- 0: Connection successful
- 1: Connection failed

---

## Text Processing Functions

### `trim [string]`

Remove leading and trailing whitespace.

**Parameters:**
- `string` - String to trim

**Usage:**
```bash
result=$(trim "  hello world  ")
echo "$result"  # Outputs: hello world
```

---

### `contains [string] [substring]`

Check if string contains substring.

**Parameters:**
- `string` - String to check
- `substring` - Substring to find

**Usage:**
```bash
if contains "example.com" "example"; then
    echo "Found"
fi
```

**Returns:**
- 0: Substring found
- 1: Substring not found

---

### `starts_with [string] [prefix]`

Check if string starts with prefix.

**Parameters:**
- `string` - String to check
- `prefix` - Prefix to find

**Usage:**
```bash
if starts_with "laravel-project" "laravel"; then
    echo "It's a Laravel project"
fi
```

**Returns:**
- 0: Starts with prefix
- 1: Doesn't start with prefix

---

### `ends_with [string] [suffix]`

Check if string ends with suffix.

**Parameters:**
- `string` - String to check
- `suffix` - Suffix to find

**Usage:**
```bash
if ends_with "index.php" ".php"; then
    echo "It's a PHP file"
fi
```

**Returns:**
- 0: Ends with suffix
- 1: Doesn't end with suffix

---

## Date/Time Functions

### `get_timestamp`

Get current Unix timestamp.

**Usage:**
```bash
timestamp=$(get_timestamp)
echo "Current time: $timestamp"
```

**Returns:** Unix timestamp

---

### `get_date [format]`

Get current date in specified format.

**Parameters:**
- `format` - Date format (default: YYYY-MM-DD)

**Usage:**
```bash
date=$(get_date "%Y-%m-%d %H:%M:%S")
echo "Date: $date"
```

**Returns:** Formatted date string

---

### `get_formatted_date [format]`

Alias for `get_date`.

---

## Color Constants

Available in `core/colors.sh`:

```bash
RED='\033[0;31m'          # Red text
GREEN='\033[0;32m'        # Green text
YELLOW='\033[1;33m'       # Yellow text
BLUE='\033[0;34m'         # Blue text
MAGENTA='\033[0;35m'      # Magenta text
CYAN='\033[0;36m'         # Cyan text
BOLD_WHITE='\033[1;37m'   # Bold white
NC='\033[0m'              # Reset color
```

---

## Usage Example: Complete Module

```bash
#!/bin/bash
#================================================================
# Ozi Script - Module: Cache
# Mô tả: Redis cache management
#================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/helpers.sh"
source "$SCRIPT_DIR/../../core/colors.sh"

#================================================================
# FUNCTIONS
#================================================================

cmd_install() {
    print_header "Redis Installation"
    require_root
    
    if is_installed "redis-server"; then
        print_info "Redis already installed"
        return 0
    fi
    
    print_info "Installing Redis..."
    if ! apt_install redis-server; then
        print_error "Failed to install Redis"
        return 1
    fi
    
    service_enable redis-server
    service_start redis-server
    
    if service_status redis-server; then
        print_success "Redis installed and running"
    else
        print_error "Redis failed to start"
        return 1
    fi
}

cmd_status() {
    print_header "Redis Status"
    
    if is_installed "redis-server"; then
        if service_status redis-server; then
            print_success "Redis is running"
            redis-cli ping
        else
            print_error "Redis is not running"
        fi
    else
        print_error "Redis is not installed"
    fi
}

show_help() {
    cat << 'EOF'
Usage: ozi cache {command}

Commands:
    install     Install Redis
    status      Check status
EOF
}

main() {
    local cmd="${1:-help}"
    case "$cmd" in
        install) cmd_install ;;
        status) cmd_status ;;
        help|--help|-h) show_help ;;
        *) print_error "Unknown command: $cmd"; show_help; return 1 ;;
    esac
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && main "$@"
```

---

**Version:** 1.0.0  
**Last Updated:** 2026-01-23
