# Ozi Script V2 - Quick Start Guide

## 🚀 Installation & Upgrade

### Fresh Installation

```bash
# Clone repository
git clone https://github.com/OziNetworkVN/OziScripts.git
cd OziScripts

# Install
sudo bash install.sh

# Verify installation
ozi version
```

### Upgrade from V1 to V2

```bash
# Navigate to installation directory
cd /opt/oziscript

# Pull latest code
git pull origin main

# Run migration tool
sudo bash migrate-v2.sh

# Verify V2
ozi version  # Should show 2.0.0
```

## 📋 Essential Commands

### Create a New Website

```bash
# Start interactive wizard
ozi site create

# Follow prompts:
# 1. Select site type (Laravel/WordPress/Node.js/Static)
# 2. Enter domain name
# 3. Configure options (PHP version, database, etc.)
# 4. Done! Nginx + directories created automatically
```

### List All Websites

```bash
ozi site list

# Output shows:
# - Domain names
# - Site types
# - PHP versions
# - SSL status
# - Active/inactive status
```

### View Website Details

```bash
ozi site info example.com

# Shows complete information:
# - Basic info (domain, type, root)
# - SSL certificate details
# - Database credentials
# - Domain aliases
# - Feature flags
# - Timestamps
```

### Install SSL Certificate

```bash
# Interactive wizard
ozi site ssl install example.com

# Options:
# 1. Let's Encrypt (Free, auto-renews every 90 days)
# 2. Cloudflare Origin (15-year certificate)
# 3. Custom SSL (Upload your own cert/key)
```

### Manage Domain Aliases

```bash
# Add www subdomain
ozi site alias add example.com www.example.com

# Add multiple aliases
ozi site alias add example.com blog.example.com
ozi site alias add example.com shop.example.com

# List all aliases
ozi site alias list example.com

# Remove alias
ozi site alias remove example.com blog.example.com
```

### Delete a Website

```bash
ozi site delete example.com

# Removes:
# - Nginx configuration
# - Website files
# - Database (if created by Ozi)
# - SSL certificates
# - Site database entry
```

## 🔐 SSL Management

### Check SSL Status

```bash
# Single site
ozi site ssl status example.com

# All sites
ozi site ssl list
```

### Renew Let's Encrypt SSL

```bash
# Manual renewal
ozi site ssl renew example.com

# Auto-renew all expiring certificates (< 30 days)
ozi site ssl auto-renew
```

### SSL Auto-Renewal Cron

```bash
# Setup automatic renewal (runs daily at 2 AM)
echo "0 2 * * * /opt/oziscript/cron/ssl-auto-renew.sh" | sudo crontab -

# Verify cron
sudo crontab -l

# Check logs
tail -f /var/log/oziscript/ssl-auto-renew.log
```

## 🎯 Site Type Guides

### Laravel Site

```bash
# Create Laravel site
ozi site create
# Select: 1 (Laravel)
# Choose PHP version (8.3 recommended)
# Enable Octane? (Yes for high performance)
# Create database? (Yes)

# After creation:
cd /var/www/example.com
# Upload Laravel code or clone from git
git clone your-laravel-repo.git .

# Install dependencies
composer install

# Configure .env
nano .env
# Use database credentials from /root/.oziscript/db-credentials/example.com.txt

# Run migrations
php artisan migrate

# If using Octane:
php artisan octane:start --port=8000 --server=swoole

# Or setup with Supervisor:
# See docs/deployment/laravel.md
```

### WordPress Site

```bash
# Create WordPress site
ozi site create
# Select: 2 (WordPress)
# Choose PHP version (8.3 recommended)
# Auto-download WordPress? (Yes)

# WordPress will be automatically downloaded to /var/www/example.com

# Visit http://example.com
# Complete WordPress installation wizard
# Use database credentials from terminal or /root/.oziscript/db-credentials/

# Install SSL
ozi site ssl install example.com

# Now visit https://example.com
```

### Node.js Site

```bash
# Create Node.js site
ozi site create
# Select: 3 (Node.js)
# Enter port (3000 default)
# Create database? (Optional)

# Upload your Node.js app
cd /var/www/example.com
git clone your-nodejs-app.git .

# Install dependencies
npm install

# Start with PM2 (recommended)
pm2 start index.js --name example.com
pm2 save

# Or manual start
node index.js

# Nginx will reverse proxy to your app port
```

### Static HTML Site

```bash
# Create static site
ozi site create
# Select: 4 (Static HTML)

# Upload files
cd /var/www/example.com
# Upload your HTML/CSS/JS files

# Or use git
git clone your-static-site.git .

# Done! Visit http://example.com
```

## 📊 Monitoring & Maintenance

### View Site Statistics

```bash
# List all sites
ozi site list

# Check specific site
ozi site info example.com

# SSL status for all sites
ozi site ssl list
```

### Check Nginx Status

```bash
# Test configuration
sudo nginx -t

# Reload after manual changes
sudo systemctl reload nginx

# View error logs
sudo tail -f /var/log/nginx/error.log

# View access logs for specific site
sudo tail -f /var/log/nginx/example.com_access.log
```

### Database Credentials

```bash
# All database credentials are saved to:
/root/.oziscript/db-credentials/

# View credentials for a site
cat /root/.oziscript/db-credentials/example.com.txt
```

### Site Database Backup

```bash
# Site database is automatically backed up before changes
ls -lh /etc/oziscript/sites.db.backup.*

# Manual backup
sudo cp /etc/oziscript/sites.db /root/sites.db.backup.$(date +%Y%m%d)

# View site database
cat /etc/oziscript/sites.db | jq .
```

## 🔧 Troubleshooting

### Nginx Config Test Failed

```bash
# Test configuration
sudo nginx -t

# View specific site config
sudo nano /etc/nginx/sites-available/example.com.conf

# Regenerate config (V2 feature)
# Edit site in database, then regenerate with manager
```

### Site Not Accessible

```bash
# Check if Nginx is running
sudo systemctl status nginx

# Check if site is enabled
ls -l /etc/nginx/sites-enabled/

# Check DNS resolution
ping example.com

# Check firewall
sudo ufw status
```

### SSL Installation Failed

```bash
# Let's Encrypt issues:
# 1. Check if domain points to server IP
dig example.com +short

# 2. Check if port 80 is available
sudo netstat -tlnp | grep :80

# 3. Stop Nginx temporarily
sudo systemctl stop nginx
# Retry SSL installation
sudo systemctl start nginx

# Cloudflare issues:
# - Verify certificate format (PEM)
# - Check private key matches certificate
openssl x509 -noout -modulus -in cert.pem | openssl md5
openssl rsa -noout -modulus -in key.pem | openssl md5
# Modulus should match
```

### Database Connection Failed

```bash
# Check MySQL is running
sudo systemctl status mysql

# Verify credentials
cat /root/.oziscript/db-credentials/example.com.txt

# Test connection
mysql -u username -p database_name

# Reset password if needed
mysql -e "ALTER USER 'username'@'localhost' IDENTIFIED BY 'new_password';"
```

## 🎓 Advanced Usage

### Programmatic Site Management

```bash
# Load site database functions
source /opt/oziscript/core/site-db.sh

# Check if site exists
if site_exists "example.com"; then
    echo "Site exists"
fi

# Get site information (JSON)
site_data=$(get_site "example.com")
echo "$site_data" | jq '.ssl.expires_at'

# List sites by type
list_sites_by_type "laravel"

# Get expiring SSL certificates (30 days)
get_expiring_ssl_sites 30
```

### Custom Nginx Configuration

```bash
# Edit Nginx config directly
sudo nano /etc/nginx/sites-available/example.com.conf

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx

# Note: Manual edits won't sync to site database
# Regenerate from database will overwrite manual changes
```

### Backup & Restore

```bash
# Backup site database
sudo cp /etc/oziscript/sites.db /backup/sites.db.backup

# Backup website files
sudo tar -czf /backup/example.com.tar.gz /var/www/example.com

# Backup database
mysqldump -u username -p database_name > /backup/database.sql

# Restore site database
sudo cp /backup/sites.db.backup /etc/oziscript/sites.db

# Restore website files
sudo tar -xzf /backup/example.com.tar.gz -C /

# Restore database
mysql -u username -p database_name < /backup/database.sql
```

## 📚 Additional Resources

- **Full Documentation**: [README_V2.md](README_V2.md)
- **Architecture Details**: [docs/ARCHITECTURE_V2.md](docs/ARCHITECTURE_V2.md)
- **API Reference**: [docs/API_REFERENCE.md](docs/API_REFERENCE.md)
- **Developer Guide**: [docs/DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md)

## 🆘 Getting Help

### Community Support
- GitHub Issues: https://github.com/OziNetworkVN/OziScripts/issues
- Documentation: https://github.com/OziNetworkVN/OziScripts/tree/main/docs

### Common Questions

**Q: Can I use V1 and V2 together?**  
A: Yes! V2 is backward compatible. Old sites continue working, new sites use V2 features.

**Q: How to migrate existing sites?**  
A: Run `sudo bash migrate-v2.sh`. It scans Nginx configs and imports to V2 database.

**Q: Where are SSL certificates stored?**  
A: 
- Let's Encrypt: `/etc/letsencrypt/live/`
- Cloudflare: `/etc/oziscript/ssl/cloudflare/`
- Custom: `/etc/oziscript/ssl/custom/`

**Q: How to change PHP version for a site?**  
A: Currently requires manual Nginx config edit. Feature planned for V2.1.

**Q: Can I use PostgreSQL instead of MySQL?**  
A: Yes, but manual setup required. Auto-creation only supports MySQL in V2.0.

---

**Happy coding with Ozi Script V2! 🚀**
