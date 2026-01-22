# Ozi Script - Frequently Asked Questions (FAQ)

## Installation & Setup

### Q: How do I install Ozi Script?

**A:** Follow these steps:

```bash
# 1. SSH into your Debian 12/13 VPS
ssh root@your-vps-ip

# 2. Upload the script (from your local machine)
scp -r oziDebianScript root@your-vps-ip:/opt/oziscript

# 3. SSH back and run installer
ssh root@your-vps-ip
cd /opt/oziscript
bash install.sh

# 4. Start using
ozi
```

See `TESTING.md` for detailed testing guide.

---

### Q: What are the system requirements?

**A:** Ozi Script requires:
- **OS:** Debian 12 (Bookworm) or Debian 13 (Trixie)
- **User:** Root access (sudo won't work)
- **Architecture:** x86_64 (64-bit)
- **Disk:** 5GB minimum free space
- **RAM:** 512MB minimum (1GB+ recommended)
- **Network:** Active internet connection for package installation

---

### Q: I'm getting "Permission denied" error. What's wrong?

**A:** You need to run the script with proper permissions:

```bash
# Check if you have root access
whoami
# Should output: root

# If not root, use sudo to become root
sudo -i
# or
sudo su -

# Then try again
cd /opt/oziscript
bash install.sh
```

Ozi Script requires full root privileges and cannot run with `sudo` prefix on individual commands.

---

### Q: The `ozi` command is not found after installation. How do I fix it

**A:** The installer should create a symlink automatically. If it doesn't work:

```bash
# Check if /opt/oziscript/ozi exists
ls -l /opt/oziscript/ozi

# Make it executable
chmod +x /opt/oziscript/ozi

# Create symlink manually
ln -sf /opt/oziscript/ozi /usr/local/bin/ozi

# Verify
which ozi
ozi --version
```

---

### Q: Can I uninstall Ozi Script?

**A:** Yes, run the uninstall script:

```bash
cd /opt/oziscript
bash uninstall.sh
```

This will:
- Remove symlinks
- Remove installation directory
- Remove configuration directory
- Remove logs directory

**Warning:** This will NOT uninstall services installed through Ozi Script (Nginx, PHP, etc.). Those must be removed manually if needed.

---

## PHP Management

### Q: How do I install multiple PHP versions?

**A:** Ozi Script supports PHP 7.4, 8.1, 8.2, 8.3, and 8.4. Install them individually:

```bash
# Install PHP 8.3
ozi php install 8.3

# Install PHP 8.1
ozi php install 8.1

# List installed versions
ozi php list
# Output: PHP 7.4 PHP 8.1 PHP 8.3 (default)
```

All versions run side-by-side. Each has its own FPM pool.

---

### Q: How do I switch the default PHP version?

**A:** Use the set-default command:

```bash
# Switch to PHP 8.1
ozi php set-default 8.1

# Verify
php -v
# Should show PHP 8.1

# Check CLI
php -v
# Check FPM (from Nginx config)
grep "php-fpm" /etc/nginx/sites-available/default
```

---

### Q: How do I use a specific PHP version for a website?

**A:** When creating a website, you can specify the PHP version in the Nginx config:

```bash
# Create site with default PHP
ozi site create laravel example.com

# Edit Nginx config to use specific version
# Edit: /etc/nginx/sites-available/example.com

# Find this line:
upstream php {
    server unix:/run/php/php-fpm.sock;
}

# Change to specific version (e.g., PHP 8.1):
upstream php {
    server unix:/run/php/php8.1-fpm.sock;
}

# Test and reload
nginx -t
systemctl reload nginx
```

---

### Q: Can I use Composer with multiple PHP versions?

**A:** Yes, Composer is installed globally and works with all PHP versions:

```bash
# Use with default PHP
composer create-project laravel/laravel myapp

# Use with specific PHP version
php8.1 /usr/local/bin/composer create-project laravel/laravel myapp

# Or change default first
ozi php set-default 8.1
composer create-project laravel/laravel myapp
```

---

## Database Management

### Q: How do I choose between PostgreSQL and MySQL?

**A:** Ozi Script installation prompts you to choose:

```bash
# During installation, you'll be asked:
# Choose database: (1) PostgreSQL (2) MySQL

# If you already installed one, install another:
ozi database postgresql install
ozi database mysql install

# Both can run simultaneously
```

Both databases are fully supported and can coexist on the same server.

---

### Q: How do I create a database?

**A:** Use the appropriate command for your database:

```bash
# PostgreSQL
sudo -u postgres createdb myapp_db
sudo -u postgres createuser myapp_user
sudo -u postgres psql -c "ALTER USER myapp_user WITH PASSWORD 'password';"

# MySQL/MariaDB
mysql -u root -p
CREATE DATABASE myapp_db;
CREATE USER 'myapp_user'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON myapp_db.* TO 'myapp_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

---

### Q: How do I access the database administration interface?

**A:** Install Adminer:

```bash
# Install Adminer
ozi database admin install

# Access via browser
# URL: http://your-vps-ip/adminer/
# Username: root or database_user
# Password: your database password
```

Adminer provides a web interface to manage both PostgreSQL and MySQL.

---

### Q: Can I backup my databases?

**A:** Yes, use the backup module:

```bash
# Full backup (files + databases)
ozi backup create full

# Database-only backup
ozi backup create db-only

# List backups
ozi backup list

# Restore
ozi backup restore oziscript-backup-YYYY-MM-DD-HH-MM-SS.tar.gz
```

---

## Website Management

### Q: How do I create a new website?

**A:** Use the site create command:

```bash
# Laravel
ozi site create laravel myapp.com

# WordPress
ozi site create wordpress myblog.com

# Node.js
ozi site create nodejs myapi.com

# Static HTML
ozi site create static mysite.com
```

This will:
- Create directory `/var/www/myapp.com`
- Generate Nginx config
- Create database (if applicable)
- Set proper permissions

---

### Q: How do I delete a website?

**A:** Use the site delete command:

```bash
# Delete website
ozi site delete myapp.com

# This will:
# - Remove Nginx config
# - Disable the site
# - Keep website files (in /var/www/)

# To also delete files:
rm -rf /var/www/myapp.com
```

---

### Q: How do I enable/disable a website?

**A:** Use the site manage commands:

```bash
# Disable (but keep files)
ozi site disable myapp.com

# Enable
ozi site enable myapp.com

# Verify
curl http://myapp.com
```

---

### Q: How do I set up SSL certificate?

**A:** Use Cloudflare Integration:

```bash
# 1. Configure Cloudflare API token
ozi ssl cloudflare configure
# (Provide your Cloudflare API token)

# 2. Generate Origin Certificate
ozi ssl cloudflare generate myapp.com

# 3. Install certificate
ozi ssl cloudflare install myapp.com

# 4. Verify HTTPS works
curl -I https://myapp.com
```

This creates a 15-year SSL certificate valid across all Cloudflare infrastructure.

---

## Security

### Q: How do I enable the firewall?

**A:** Use the firewall module:

```bash
# Enable firewall
ozi security firewall enable

# Allow specific port
ozi security firewall allow 8080

# Deny port
ozi security firewall deny 3000

# View all rules
ufw status numbered

# Disable rule
ufw delete 2
```

Default rules after enable:
- Deny all incoming (except allowed ports)
- Allow all outgoing
- Allow SSH (port 22)
- Allow HTTP (port 80)
- Allow HTTPS (port 443)

---

### Q: How do I harden SSH security?

**A:** Run the SSH hardening module:

```bash
# Apply SSH hardening
ozi security ssh harden

# This will:
# - Disable root login
# - Disable password authentication
# - Enable key-based auth only
# - Change security headers

# After this, you MUST use SSH keys to connect:
ssh -i ~/.ssh/id_rsa root@vps-ip
```

---

### Q: How do I generate SSH keys for authentication?

**A:** Create keys on your local machine:

```bash
# Generate key pair (on your local machine)
ssh-keygen -t ed25519 -C "your-email@example.com"
# Or for older systems:
# ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# Copy public key to server
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@vps-ip

# Verify key works
ssh -i ~/.ssh/id_ed25519 root@vps-ip
# Should not ask for password

# Then apply hardening
ozi security ssh harden
```

---

### Q: What does Fail2ban do?

**A:** Fail2ban automatically blocks IPs attempting brute-force attacks:

```bash
# Install Fail2ban
ozi security fail2ban install

# Check status
systemctl status fail2ban

# View banned IPs
fail2ban-client status sshd

# Unban specific IP
fail2ban-client set sshd unbanip 192.168.1.100

# View attempts
tail -f /var/log/fail2ban.log
```

It monitors login attempts and automatically bans IPs after failed attempts.

---

## Deployment

### Q: How do I deploy a Laravel application?

**A:** Use the deploy module:

```bash
# Deploy Laravel
ozi deploy laravel myapp.com

# This will:
# - Create website directory
# - Create Nginx config
# - Setup PHP-FPM

# Then manually:
cd /var/www/myapp.com

# Clone your app
git clone your-repo-url .

# Install dependencies
composer install

# Setup environment
cp .env.example .env
# Edit .env with your settings

# Generate app key
php artisan key:generate

# Setup database
php artisan migrate

# Set permissions
chmod -R 755 storage
chmod -R 755 bootstrap/cache
```

---

### Q: How do I deploy a Node.js application?

**A:** Use the deploy module:

```bash
# Deploy Node.js
ozi deploy nodejs myapi.com

# This will:
# - Create website directory
# - Create Nginx reverse proxy config
# - Setup PM2 process manager

# Then manually:
cd /var/www/myapi.com

# Clone your app
git clone your-repo-url .

# Install dependencies
npm install

# Setup environment
cp .env.example .env
# Edit .env with your settings

# Start with PM2
pm2 start index.js --name myapi

# Save PM2 config for auto-restart
pm2 save

# View logs
pm2 logs myapi
```

---

### Q: How do I deploy WordPress?

**A:** Use the deploy module:

```bash
# Deploy WordPress
ozi deploy wordpress myblog.com

# This will:
# - Create website directory
# - Create Nginx config
# - Download WordPress core
# - Create wp-config.php

# Then in browser:
# Open: http://myblog.com
# Follow the installation wizard
# Set admin username and password

# Or use wp-cli (if installed):
wp core install --url=myblog.com --title="My Blog" --admin_user=admin --admin_email=admin@example.com
```

---

## Monitoring & Maintenance

### Q: How do I monitor system resources?

**A:** Use the system info module:

```bash
# Check overall stats
ozi system info

# Check CPU info
ozi system cpu

# Check memory usage
ozi system memory

# Check disk usage
ozi system disk

# Or use system commands
top
htop (if installed)
df -h
free -h
```

---

### Q: How do I create a backup?

**A:** Use the backup module:

```bash
# Full backup (all files + databases)
ozi backup create full

# Website files only
ozi backup create files-only

# Databases only
ozi backup create db-only

# List all backups
ozi backup list

# Schedule daily backups
ozi backup schedule daily

# Restore from backup
ozi backup restore oziscript-backup-2026-01-23-14-30-00.tar.gz
```

Backups are stored in `/var/backups/oziscript/`.

---

### Q: How do I check service status?

**A:** Use system commands:

```bash
# Check Nginx
systemctl status nginx

# Check PHP-FPM
systemctl status php8.3-fpm

# Check MySQL
systemctl status mysql

# Check PostgreSQL
systemctl status postgresql

# Check all services
systemctl list-units --type service --state running
```

---

## Troubleshooting

### Q: Port 80/443 is already in use. What do I do?

**A:** Find and stop the conflicting service:

```bash
# Find what's using port 80
lsof -i :80
# or
netstat -tlnp | grep :80

# Stop the conflicting service
systemctl stop apache2

# Or change Nginx port:
# Edit: /etc/nginx/sites-available/default
# Change: listen 80; to listen 8080;

# Test and reload
nginx -t
systemctl reload nginx
```

---

### Q: Website returns "502 Bad Gateway" error

**A:** This usually means PHP-FPM is not responding. Troubleshoot:

```bash
# Check PHP-FPM status
systemctl status php8.3-fpm

# Restart PHP-FPM
systemctl restart php8.3-fpm

# Check Nginx config
nginx -t

# Check PHP-FPM socket
ls -l /run/php/php8.3-fpm.sock

# View error log
tail -f /var/log/nginx/error.log
```

---

### Q: Website is very slow. How do I optimize?

**A:** Try these optimizations:

```bash
# Enable gzip compression (Nginx config)
gzip on;
gzip_types text/plain text/css application/json;

# Enable caching (Nginx config)
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}

# Optimize PHP (php.ini)
memory_limit = 256M
max_execution_time = 60
opcache.enable = 1

# Use Redis for caching
ozi cache redis install

# Enable Gzip in application
# Laravel: config/app.php
# WordPress: plugins

# Check what's slow
top
atop
vmstat
```

---

### Q: Can't connect to database. What's wrong?

**A:** Check database connection and credentials:

```bash
# For PostgreSQL
sudo -u postgres psql -l
psql -h localhost -U postgres -d postgres -c "SELECT 1"

# For MySQL
mysql -u root -p
mysql -u myuser -p -h 127.0.0.1 mydb -e "SELECT 1"

# Check credentials in application
# Laravel: .env
# WordPress: wp-config.php

# Check database user permissions
# PostgreSQL:
sudo -u postgres psql -c "\\du"

# MySQL:
mysql -u root -p -e "SELECT user, host FROM mysql.user;"

# Check if database is listening
netstat -tlnp | grep mysql
netstat -tlnp | grep postgres
```

---

### Q: Colors are not displaying in terminal

**A:** This might be a terminal compatibility issue:

```bash
# Check if terminal supports colors
echo $TERM
# Should output: xterm-256color or similar

# If not, set it:
export TERM=xterm-256color

# Make permanent
echo 'export TERM=xterm-256color' >> ~/.bashrc
source ~/.bashrc
```

---

## Development

### Q: How do I create a new module?

**A:** Follow the development guide:

```bash
# 1. Create module file
touch modules/category/my_module.sh

# 2. Use the template from docs/DEVELOPER_GUIDE.md

# 3. Add menu entry to core/menu.sh

# 4. Add handler to ozi CLI script

# 5. Test thoroughly

# 6. Update TESTING.md with test cases

# 7. Update TASK.md

# 8. Submit pull request
```

See `DEVELOPER_GUIDE.md` for complete instructions.

---

### Q: How do I test my changes?

**A:** Use the testing procedure:

```bash
# 1. ShellCheck your code
shellcheck modules/category/my_module.sh

# 2. Deploy to test VPS
scp -r . root@test-vps:/opt/oziscript

# 3. Test on VPS
ssh root@test-vps 'ozi --version'

# 4. Follow TESTING.md checklist

# 5. Test on both Debian 12 and 13
```

---

### Q: How do I report a bug?

**A:** Open an issue with:

- Clear title
- Steps to reproduce
- Expected behavior
- Actual behavior
- Your environment (Debian version)
- Error messages/logs

Example:

```markdown
## Bug: Website returns 502 after creating with Laravel

### Steps to reproduce:
1. ozi site create laravel example.com
2. Browse to http://example.com

### Expected:
Should display Laravel welcome page

### Actual:
Shows "502 Bad Gateway"

### Environment:
- Debian: 13
- Ozi Script: 1.0.0

### Logs:
[Include relevant error logs]
```

---

## Performance & Best Practices

### Q: What are recommendations for production?

**A:** Follow these practices:

```bash
# 1. Security hardening
ozi security firewall enable
ozi security ssh harden
ozi security fail2ban install

# 2. Enable SSL
ozi ssl cloudflare configure
ozi ssl cloudflare install yourdomain.com

# 3. Database optimization
# PostgreSQL: enable logging
# MySQL: enable query cache
# Add indexes to frequently queried columns

# 4. PHP optimization
# Enable opcache
# Increase memory_limit
# Set max_execution_time

# 5. Backup strategy
ozi backup schedule daily
# Keep backups in multiple locations

# 6. Monitoring
# Use systemctl to monitor services
# Check logs regularly
# Monitor disk space

# 7. Update regularly
# apt update && apt upgrade
# Keep PHP updated
# Update security patches

# 8. Use Redis/Memcached
ozi cache redis install
# Use in application for session/query caching
```

---

### Q: Should I use one VPS or multiple?

**A:** Depends on traffic:

- **Small sites:** One VPS (Debian 12/13)
- **Medium sites:** One VPS with separate database server
- **Large sites:** Multiple app servers with load balancer
- **Very large:** Kubernetes or managed services

Ozi Script works best for small to medium deployments on a single VPS.

---

## Getting Help

### Q: Where can I find more information?

**A:** Check these resources:

- **README.md** - Project overview
- **TESTING.md** - Testing guide
- **DEVELOPER_GUIDE.md** - Development tutorial
- **API_REFERENCE.md** - Function documentation
- **MODULE_CATALOG.md** - Module reference
- **CONTRIBUTING.md** - Contribution guidelines
- **GitHub Issues** - Report bugs or request features
- **code comments** - Module source code comments

### Q: How do I get support?

**A:** Options:

1. Check this FAQ
2. Search GitHub issues
3. Open a new issue
4. Check documentation files
5. Review module source code comments

---

**Last Updated:** 2026-01-23  
**Version:** 1.0.0
