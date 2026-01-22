# Ozi Script - Module Catalog

Complete reference for all modules in Ozi Script with their commands, features, and implementation details.

## Table of Contents

1. [System Modules](#system-modules)
2. [Stack Modules](#stack-modules)
3. [Security Modules](#security-modules)
4. [Site Management Modules](#site-management-modules)
5. [Database Modules](#database-modules)
6. [Backup Modules](#backup-modules)
7. [Deployment Modules](#deployment-modules)

---

## System Modules

### info.sh - System Information

**File:** `modules/system/info.sh`  
**Purpose:** Display system information and statistics

**Commands:**
```bash
ozi system info              # Overall system statistics
ozi system cpu               # CPU information
ozi system memory            # RAM information
ozi system disk              # Disk usage
ozi system hostname          # Get hostname
ozi system timezone          # Get timezone
```

**Features:**
- Display CPU cores, model, and frequency
- Show memory (total, used, free) in MB
- Display disk usage with percentages
- Show system uptime and load average
- Display public IP address

**Configuration:**
- No configuration required
- Real-time data from system

**Dependencies:**
- None (uses built-in utilities)

---

### swap.sh - Swap Space Management

**File:** `modules/system/swap.sh`  
**Purpose:** Enable and manage swap space

**Commands:**
```bash
ozi system swap enable       # Enable swap
ozi system swap disable      # Disable swap
ozi system swap status       # Check swap status
ozi system swap resize       # Change swap size
```

**Features:**
- Create swap file with custom size
- Enable/disable swap
- Show current swap usage
- Configure swappiness

**Configuration:**
- Swap file location: `/swapfile`
- Default size: 2GB
- Configurable swappiness (0-100)

**Dependencies:**
- fallocate utility
- mkswap command

---

## Stack Modules

### php.sh - Multi-PHP Installation

**File:** `modules/stack/php.sh`  
**Purpose:** Install and manage multiple PHP versions

**Commands:**
```bash
ozi php install {version}           # Install specific version (7.4, 8.1, 8.2, 8.3, 8.4)
ozi php list                        # List installed versions
ozi php set-default {version}       # Set default version
ozi php enable {version}            # Enable version
ozi php disable {version}           # Disable version
ozi php info                        # Show PHP information
```

**Supported Versions:**
- PHP 7.4
- PHP 8.1
- PHP 8.2
- PHP 8.3
- PHP 8.4

**Features:**
- Install multiple PHP versions side-by-side
- Switch default CLI version
- Install PHP-FPM for web server
- Install common extensions automatically
- Manage PHP configurations

**Common Extensions:**
- bcmath, curl, gd, imagick
- intl, json, mbstring, xml
- zip, sqlite3, pdo

**Configuration:**
- FPM pools: `/etc/php/{version}/fpm/pool.d/`
- Config: `/etc/php/{version}/fpm/php.ini`

**Dependencies:**
- Ondrej DPA repository

**Usage Example:**
```bash
# Install PHP 8.3
ozi php install 8.3

# Set as default
ozi php set-default 8.3

# Check versions
ozi php list
# Output: PHP 7.4 PHP 8.1 PHP 8.3 (default)
```

---

### nginx.sh - Nginx Web Server

**File:** `modules/stack/nginx.sh`  
**Purpose:** Install and manage Nginx web server

**Commands:**
```bash
ozi nginx install              # Install Nginx
ozi nginx status               # Check status
ozi nginx restart              # Restart service
ozi nginx reload               # Reload config
ozi nginx test                 # Test configuration
ozi nginx enable-ssl           # Enable SSL support
```

**Features:**
- Install latest stable Nginx from official repo
- Enable HTTP/2 and gzip compression
- Configure security headers
- Enable SSL/TLS support
- Manage virtual hosts

**Configuration:**
- Main config: `/etc/nginx/nginx.conf`
- Sites enabled: `/etc/nginx/sites-enabled/`
- Sites available: `/etc/nginx/sites-available/`
- Logs: `/var/log/nginx/`

**Dependencies:**
- Nginx official repository
- OpenSSL for SSL support

**Usage Example:**
```bash
# Install Nginx
ozi nginx install

# Test configuration before reload
ozi nginx test

# Reload with new config
ozi nginx reload
```

---

### postgresql.sh - PostgreSQL Database

**File:** `modules/stack/postgresql.sh`  
**Purpose:** Install and configure PostgreSQL

**Commands:**
```bash
ozi database postgresql install     # Install PostgreSQL
ozi database postgresql status      # Check status
ozi database postgresql createdb    # Create new database
ozi database postgresql dropdb      # Drop database
ozi database postgresql password    # Change postgres password
```

**Features:**
- Install latest stable version
- Auto-start on boot
- Create databases
- Manage users and permissions
- Backup/restore support

**Configuration:**
- Main config: `/etc/postgresql/*/main/postgresql.conf`
- Data directory: `/var/lib/postgresql/`
- Log: `/var/log/postgresql/`

**Default User:**
- Username: postgres
- Password: (set during installation)

**Dependencies:**
- PostgreSQL server package
- postgresql-contrib (tools)

**Usage Example:**
```bash
# Install PostgreSQL
ozi database postgresql install

# Create database
ozi database postgresql createdb myapp

# Connect
psql -U postgres -d myapp
```

---

### mysql.sh - MySQL/MariaDB Database

**File:** `modules/stack/mysql.sh`  
**Purpose:** Install MySQL or MariaDB database

**Commands:**
```bash
ozi database mysql install          # Install MySQL/MariaDB
ozi database mysql status           # Check status
ozi database mysql createdb         # Create database
ozi database mysql dropdb           # Drop database
ozi database mysql password         # Change root password
```

**Features:**
- Choose between MySQL and MariaDB
- Auto-start on boot
- Secure installation (remove test DB, anonymous users)
- Create databases and users
- Backup/restore support

**Configuration:**
- Main config: `/etc/mysql/mysql.conf.d/mysqld.cnf`
- Data directory: `/var/lib/mysql/`

**Default User:**
- Username: root
- Password: (set during installation)

**Dependencies:**
- MySQL Server or MariaDB Server
- MySQL Client tools

---

### redis.sh - Redis Cache Server

**File:** `modules/stack/redis.sh`  
**Purpose:** Install and configure Redis

**Commands:**
```bash
ozi cache redis install             # Install Redis
ozi cache redis status              # Check status
ozi cache redis cli                 # Access Redis CLI
ozi cache redis flush               # Flush all data
```

**Features:**
- Install Redis server
- Configure port and password
- Memory management
- Persistence options (RDB, AOF)
- Automatic cleanup

**Configuration:**
- Config: `/etc/redis/redis.conf`
- Data directory: `/var/lib/redis/`
- Default port: 6379

**Dependencies:**
- redis-server package
- redis-tools (CLI)

**Usage Example:**
```bash
# Install Redis
ozi cache redis install

# Access CLI
redis-cli

# Check connection
redis-cli ping
# Output: PONG
```

---

### nodejs.sh - Node.js Installation

**File:** `modules/stack/nodejs.sh`  
**Purpose:** Install Node.js and NPM

**Commands:**
```bash
ozi node install {version}          # Install specific version (12, 14, 16, 18, 20, latest)
ozi node list                       # List installed versions
ozi node set-default {version}      # Set default version
ozi node npm update                 # Update NPM
```

**Installation Method:**
- Uses NVM (Node Version Manager) for multi-version support
- Installs Node.js and npm automatically

**Supported Versions:**
- LTS versions: 12, 14, 16, 18, 20
- Latest version

**Features:**
- Install multiple Node versions
- Switch between versions
- Automatic npm upgrade
- Global package management

**Configuration:**
- NVM location: `~/.nvm/`
- Node versions: `~/.nvm/versions/node/`

**Dependencies:**
- curl or wget (for NVM download)
- Build tools (for native modules)

**Usage Example:**
```bash
# Install Node.js 20
ozi node install 20

# List available
ozi node list

# Use specific version
nvm use 20
```

---

### composer.sh - PHP Composer

**File:** `modules/stack/composer.sh`  
**Purpose:** Install and manage PHP Composer

**Commands:**
```bash
ozi composer install                # Install Composer
ozi composer update                 # Update to latest version
ozi composer status                 # Check Composer version
ozi composer clear-cache            # Clear package cache
```

**Features:**
- Install PHP Composer globally
- Install to `/usr/local/bin/composer`
- Keep updated automatically
- Manage PHP dependencies
- Support for all PHP versions

**Usage Example:**
```bash
# Install Composer
ozi composer install

# Create new project
composer create-project laravel/laravel myapp

# Install dependencies
cd myapp && composer install
```

---

### supervisor.sh - Process Supervisor

**File:** `modules/stack/supervisor.sh`  
**Purpose:** Install and configure Supervisor process manager

**Commands:**
```bash
ozi supervisor install              # Install Supervisor
ozi supervisor status               # Check status
ozi supervisor start                # Start service
ozi supervisor stop                 # Stop service
ozi supervisor restart              # Restart service
```

**Features:**
- Process management
- Auto-restart failed processes
- Log management
- Process grouping
- Web UI (optional)

**Configuration:**
- Config directory: `/etc/supervisor/conf.d/`
- Log directory: `/var/log/supervisor/`

**Usage Example:**
```bash
# Install Supervisor
ozi supervisor install

# Create config for Laravel Queue
cat > /etc/supervisor/conf.d/laravel-queue.conf << 'EOF'
[program:laravel-queue]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/myapp/artisan queue:work
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/laravel-queue.err.log
stdout_logfile=/var/log/supervisor/laravel-queue.out.log
EOF

# Reload supervisor
supervisorctl reread
supervisorctl update
supervisorctl start laravel-queue:*
```

---

## Security Modules

### firewall.sh - UFW Firewall Configuration

**File:** `modules/security/firewall.sh`  
**Purpose:** Configure UFW firewall rules

**Commands:**
```bash
ozi security firewall enable        # Enable firewall
ozi security firewall disable       # Disable firewall
ozi security firewall allow {port}  # Allow port
ozi security firewall deny {port}   # Deny port
ozi security firewall status        # Show rules
```

**Features:**
- Enable/disable firewall
- Allow/deny ports
- Allow/deny protocols
- Default policies
- Rule management

**Configuration:**
- Config: `/etc/ufw/ufw.conf`
- Rules: `/etc/ufw/user.rules`

**Default Rules (after enable):**
- Deny incoming (default)
- Allow outgoing (default)
- Allow SSH (port 22)
- Allow HTTP (port 80)
- Allow HTTPS (port 443)

**Usage Example:**
```bash
# Enable firewall
ozi security firewall enable

# Allow specific port
ozi security firewall allow 8080

# Show all rules
ufw status numbered

# Delete rule
ufw delete 2
```

---

### ssh.sh - SSH Security Hardening

**File:** `modules/security/ssh.sh`  
**Purpose:** Secure SSH configuration

**Commands:**
```bash
ozi security ssh harden            # Apply hardening
ozi security ssh key-generate      # Generate SSH keys
ozi security ssh disable-root       # Disable root login
ozi security ssh disable-password   # Disable password auth
```

**Features:**
- Disable root login
- Change SSH port (optional)
- Disable password authentication
- Enable key-based auth
- Security headers

**Configuration:**
- Config: `/etc/ssh/sshd_config`
- Backup created: `/etc/ssh/sshd_config.bak`

**Changes Applied:**
```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
```

**Usage Example:**
```bash
# Generate SSH key on local machine
ssh-keygen -t ed25519 -C "user@example.com"

# Add public key to server
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server

# Apply hardening
ozi security ssh harden

# Verify no password login
ssh -i ~/.ssh/id_ed25519 user@server
```

---

### fail2ban.sh - Intrusion Prevention

**File:** `modules/security/fail2ban.sh`  
**Purpose:** Install and configure Fail2ban

**Commands:**
```bash
ozi security fail2ban install      # Install Fail2ban
ozi security fail2ban status       # Check status
ozi security fail2ban enable       # Enable service
ozi security fail2ban check        # View banned IPs
```

**Features:**
- Monitor log files for failed attempts
- Automatically ban malicious IPs
- Auto-unban after timeout
- Email notifications (optional)
- Rules for SSH, HTTP, FTP, etc.

**Configuration:**
- Config: `/etc/fail2ban/jail.local`
- Log: `/var/log/fail2ban.log`

**Default Jails:**
- sshd: Monitor SSH login attempts
- recidive: Ban repeat offenders

**Usage Example:**
```bash
# Install Fail2ban
ozi security fail2ban install

# Check status
systemctl status fail2ban

# View banned IPs
fail2ban-client status sshd

# Unban IP
fail2ban-client set sshd unbanip 192.168.1.100
```

---

## Site Management Modules

### manage.sh - Website Management

**File:** `modules/site/manage.sh`  
**Purpose:** Create and manage websites

**Commands:**
```bash
ozi site create {framework} {domain}    # Create new site
ozi site list                          # List all sites
ozi site delete {domain}               # Delete site
ozi site info {domain}                 # Show site info
ozi site enable {domain}               # Enable site
ozi site disable {domain}              # Disable site
```

**Supported Frameworks:**
- Laravel
- WordPress
- Node.js
- Static (HTML)

**Features:**
- Auto-create directory structure
- Generate Nginx config from templates
- Create database automatically
- Set permissions correctly
- Enable/disable sites

**Directory Structure Created:**
```
/var/www/{domain}/
├── public/           # Public files (web root)
├── .env              # Environment file
└── [framework files]
```

**Default User:**
- www-data (web server user)
- Permissions: 755 for directories, 644 for files

**Usage Example:**
```bash
# Create Laravel site
ozi site create laravel myapp.com

# Create WordPress site
ozi site create wordpress myblog.com

# List all sites
ozi site list

# Delete site
ozi site delete myapp.com
```

---

### cloudflare.sh - Cloudflare SSL Integration

**File:** `modules/site/cloudflare.sh`  
**Purpose:** Manage Cloudflare SSL certificates

**Commands:**
```bash
ozi ssl cloudflare configure        # Set up Cloudflare API token
ozi ssl cloudflare generate {domain}  # Generate Origin Certificate
ozi ssl cloudflare install {domain}   # Install cert for domain
ozi ssl cloudflare renew {domain}     # Renew certificate
ozi ssl cloudflare list               # List certificates
```

**Features:**
- Generate Cloudflare Origin Certificates (15 years)
- Auto-install certificates
- Configure Nginx for HTTPS
- Update Cloudflare DNS (optional)
- Certificate renewal

**Configuration:**
- API Token stored: `/etc/oziscript/cloudflare.conf`
- Certificates: `/etc/ssl/cloudflare/`

**Requirements:**
- Cloudflare account
- Domain managed by Cloudflare
- API Token with SSL permissions

**Getting API Token:**
1. Log in to Cloudflare (dash.cloudflare.com)
2. Avatar → My Profile → API Tokens
3. Create Custom Token with:
   - SSL and Certificates → Origin Certificates → Edit
   - Zone → Zone → Read

**Usage Example:**
```bash
# Configure API token
ozi ssl cloudflare configure

# Generate and install cert
ozi ssl cloudflare generate example.com
ozi ssl cloudflare install example.com

# Verify SSL
curl -I https://example.com
```

---

## Database Modules

### admin.sh - Database Administration

**File:** `modules/database/admin.sh`  
**Purpose:** Install Adminer database web interface

**Commands:**
```bash
ozi database admin install          # Install Adminer
ozi database admin status           # Check status
ozi database admin password         # Change access password
ozi database admin disable          # Disable access
```

**Features:**
- Web-based database management UI
- Support for MySQL, PostgreSQL, SQLite
- User-friendly interface
- Database browsing and editing
- SQL query execution

**Access:**
- URL: `http://your-server/adminer/`
- Default user: admin
- Password: (set during installation)

**Installation Location:**
- Files: `/var/www/adminer/`
- Nginx config: `/etc/nginx/sites-available/adminer`

**Usage Example:**
```bash
# Install Adminer
ozi database admin install

# Access via browser
# Open: http://your-vps-ip/adminer/

# Login with database credentials
# Username: root or database_user
# Password: your_password
```

---

## Backup Modules

### local.sh - Local Backup Management

**File:** `modules/backup/local.sh`  
**Purpose:** Create and restore local backups

**Commands:**
```bash
ozi backup create {type}              # Create backup (full, files-only, db-only)
ozi backup list                      # List backups
ozi backup restore {backup_file}     # Restore from backup
ozi backup delete {backup_file}      # Delete backup
ozi backup schedule {frequency}      # Schedule backups
ozi backup status                    # Show backup status
```

**Backup Types:**
- **full**: All files + all databases
- **files-only**: Website files only
- **db-only**: Databases only

**Backup Location:**
- Directory: `/var/backups/oziscript/`
- Naming: `oziscript-backup-YYYY-MM-DD-HH-MM-SS.tar.gz`

**Features:**
- Compress backups with tar.gz
- Exclude unnecessary files
- Database dumps (SQL format)
- Backup listing with size/date
- Automated scheduling (cron)
- Retention policies

**Default Behavior:**
- Includes: `/var/www/`, `/etc/oziscript/`, MySQL dumps
- Excludes: `/var/www/cache`, `/var/www/logs`, `/node_modules/`

**Usage Example:**
```bash
# Create full backup
ozi backup create full

# List backups
ozi backup list

# Restore from backup
ozi backup restore oziscript-backup-2026-01-23-14-30-00.tar.gz

# Schedule daily backups
ozi backup schedule daily

# Delete old backup
ozi backup delete oziscript-backup-2026-01-15-10-00-00.tar.gz
```

---

## Deployment Modules

### laravel.sh - Laravel Application Deployment

**File:** `modules/deploy/laravel.sh`  
**Purpose:** Deploy Laravel applications

**Commands:**
```bash
ozi deploy laravel {domain}           # Deploy Laravel app
ozi deploy laravel setup-db {domain}  # Setup database
ozi deploy laravel migrate {domain}   # Run migrations
ozi deploy laravel optimize {domain}  # Optimize cache
ozi deploy laravel queue {domain}     # Setup queue worker
ozi deploy laravel status {domain}    # Show deployment status
```

**Deployment Steps:**
1. Clone repository (via Git)
2. Install dependencies (Composer)
3. Create .env file
4. Generate app key
5. Run migrations
6. Set permissions
7. Configure Nginx
8. Enable SSL (optional)

**Features:**
- Auto-generate .env
- Database creation
- Migration execution
- Cache optimization
- Queue worker setup
- Storage directory setup
- Proper file permissions

**Requirements:**
- PHP with required extensions
- Composer
- Git (if deploying from repo)
- Database (MySQL or PostgreSQL)

**Usage Example:**
```bash
# Deploy new Laravel app
ozi deploy laravel example.com

# Setup database tables
ozi deploy laravel setup-db example.com

# Run migrations
ozi deploy laravel migrate example.com

# Setup queue processing
ozi deploy laravel queue example.com

# Optimize for production
ozi deploy laravel optimize example.com
```

---

### nodejs.sh - Node.js Application Deployment

**File:** `modules/deploy/nodejs.sh`  
**Purpose:** Deploy Node.js applications

**Commands:**
```bash
ozi deploy nodejs {domain}            # Deploy Node.js app
ozi deploy nodejs npm-install {domain}  # Install dependencies
ozi deploy nodejs start {domain}      # Start application
ozi deploy nodejs stop {domain}       # Stop application
ozi deploy nodejs status {domain}     # Check status
```

**Deployment Steps:**
1. Clone repository
2. Install npm dependencies
3. Create .env file
4. Setup PM2 process manager
5. Configure Nginx reverse proxy
6. Enable SSL

**Features:**
- Automatic npm installation
- PM2 process management
- Nginx reverse proxy configuration
- Environment variables
- Automatic restart on reboot
- Log management

**Process Manager:**
- Uses PM2 for process management
- Auto-restart on crash
- Log aggregation
- Monitoring capabilities

**Usage Example:**
```bash
# Deploy Node.js app
ozi deploy nodejs example.com

# Install dependencies
ozi deploy nodejs npm-install example.com

# Start application
ozi deploy nodejs start example.com

# Check status
pm2 status

# View logs
pm2 logs nodejs-example
```

---

### wordpress.sh - WordPress Deployment

**File:** `modules/deploy/wordpress.sh`  
**Purpose:** Deploy WordPress sites

**Commands:**
```bash
ozi deploy wordpress {domain}         # Deploy WordPress
ozi deploy wordpress setup {domain}   # Setup WordPress
ozi deploy wordpress plugins {domain}  # Manage plugins
ozi deploy wordpress themes {domain}   # Manage themes
ozi deploy wordpress backup {domain}   # Backup WordPress
```

**Deployment Steps:**
1. Create website directory
2. Download WordPress core
3. Create wp-config.php
4. Create database
5. Run installer
6. Configure Nginx
7. Setup SSL

**Features:**
- Automatic WordPress download
- Database creation
- wp-config generation
- Security headers
- Nginx optimized config
- SSL support

**Default Settings:**
- Database prefix: wp_
- Admin user: admin
- Password: (auto-generated)

**Usage Example:**
```bash
# Deploy WordPress
ozi deploy wordpress myblog.com

# Complete setup (DB, user, etc)
ozi deploy wordpress setup myblog.com

# Backup before updates
ozi deploy wordpress backup myblog.com

# Access WordPress admin
# URL: https://myblog.com/wp-admin/
# Username: admin
# Password: (from installation)
```

---

## Module Statistics

| Category | Count | Modules |
|----------|-------|---------|
| System | 2 | info, swap |
| Stack | 8 | php, nginx, mysql, postgresql, redis, nodejs, composer, supervisor |
| Security | 3 | firewall, ssh, fail2ban |
| Site | 2 | manage, cloudflare |
| Database | 1 | admin |
| Backup | 1 | local |
| Deploy | 3 | laravel, nodejs, wordpress |
| **Total** | **20** | - |

---

**Version:** 1.0.0  
**Last Updated:** 2026-01-23  
**Total Lines of Code:** ~5,000 (estimated)
