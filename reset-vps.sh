#!/bin/bash
#================================================================
# Ozi Script - VPS Complete Reset
# Mô tả: Xóa sạch toàn bộ cài đặt, đưa VPS về trạng thái mặc định
# Sử dụng: sudo bash reset-vps.sh
# CẢNH BÁO: Script này sẽ XÓA TẤT CẢ dữ liệu websites, databases!
#================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD_RED='\033[1;31m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

# Check root
if [[ $EUID -ne 0 ]]; then
    print_error "Script này cần quyền root. Vui lòng chạy với sudo."
    exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo -e "           ${BOLD_RED}RESET VPS VỀ TRẠNG THÁI MẶC ĐỊNH${NC}"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo -e "${BOLD_RED}CẢNH BÁO: Script này sẽ XÓA TẤT CẢ:${NC}"
echo ""
echo "  • Nginx và tất cả websites"
echo "  • PHP (tất cả versions)"
echo "  • MySQL/MariaDB và databases"
echo "  • PostgreSQL và databases"
echo "  • Redis"
echo "  • Node.js"
echo "  • Composer"
echo "  • Supervisor"
echo "  • SSL certificates"
echo "  • Firewall rules (UFW)"
echo "  • Fail2ban"
echo "  • Tất cả config trong /etc"
echo "  • Tất cả websites trong /var/www"
echo "  • Ozi Script"
echo ""
echo -e "${YELLOW}Dữ liệu sẽ KHÔNG THỂ KHÔI PHỤC!${NC}"
echo ""
read -p "Gõ 'YES' (viết hoa) để xác nhận xóa toàn bộ: " confirm

if [[ "$confirm" != "YES" ]]; then
    echo "Đã hủy."
    exit 0
fi

echo ""
echo "Bắt đầu reset VPS..."
echo ""

#================================================================
# 1. STOP ALL SERVICES
#================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Dừng tất cả services..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

services=("nginx" "php8.4-fpm" "php8.3-fpm" "php8.2-fpm" "php8.1-fpm" "php7.4-fpm" 
          "mysql" "mariadb" "postgresql" "redis" "redis-server" "supervisor" "fail2ban")

for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        systemctl stop "$service" 2>/dev/null || true
        print_success "Đã dừng $service"
    fi
done

#================================================================
# 2. REMOVE PACKAGES
#================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Gỡ cài đặt packages..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Nginx
if dpkg -l | grep -q nginx; then
    apt-get purge -y nginx nginx-common nginx-core 2>/dev/null || true
    print_success "Đã gỡ Nginx"
fi

# PHP (all versions)
for version in 7.4 8.1 8.2 8.3 8.4; do
    if dpkg -l | grep -q "php${version}"; then
        apt-get purge -y php${version}* 2>/dev/null || true
        print_success "Đã gỡ PHP ${version}"
    fi
done

# MySQL/MariaDB
if dpkg -l | grep -qE "mysql|mariadb"; then
    apt-get purge -y mysql-* mariadb-* 2>/dev/null || true
    print_success "Đã gỡ MySQL/MariaDB"
fi

# PostgreSQL
if dpkg -l | grep -q postgresql; then
    apt-get purge -y postgresql* 2>/dev/null || true
    print_success "Đã gỡ PostgreSQL"
fi

# Redis
if dpkg -l | grep -q redis; then
    apt-get purge -y redis-* 2>/dev/null || true
    print_success "Đã gỡ Redis"
fi

# Composer
if [[ -f /usr/local/bin/composer ]]; then
    rm -f /usr/local/bin/composer
    print_success "Đã gỡ Composer"
fi

# Node.js & NVM
if [[ -d /root/.nvm ]]; then
    rm -rf /root/.nvm
    sed -i '/NVM_DIR/d' /root/.bashrc 2>/dev/null || true
    print_success "Đã gỡ Node.js (NVM)"
fi

# Supervisor
if dpkg -l | grep -q supervisor; then
    apt-get purge -y supervisor 2>/dev/null || true
    print_success "Đã gỡ Supervisor"
fi

# Fail2ban
if dpkg -l | grep -q fail2ban; then
    apt-get purge -y fail2ban 2>/dev/null || true
    print_success "Đã gỡ Fail2ban"
fi

# UFW (reset rules only, keep package)
if command -v ufw >/dev/null 2>&1; then
    ufw --force reset 2>/dev/null || true
    print_success "Đã reset UFW firewall"
fi

# Certbot
if dpkg -l | grep -q certbot; then
    apt-get purge -y certbot python3-certbot-nginx 2>/dev/null || true
    print_success "Đã gỡ Certbot"
fi

#================================================================
# 3. REMOVE CONFIGURATION FILES
#================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Xóa configuration files..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

configs=(
    "/etc/nginx"
    "/etc/php"
    "/etc/mysql"
    "/etc/mariadb"
    "/etc/postgresql"
    "/etc/redis"
    "/etc/supervisor"
    "/etc/fail2ban"
    "/etc/letsencrypt"
    "/etc/oziscript"
)

for config in "${configs[@]}"; do
    if [[ -d "$config" ]]; then
        rm -rf "$config"
        print_success "Đã xóa $config"
    fi
done

#================================================================
# 4. REMOVE DATA DIRECTORIES
#================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Xóa data directories..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Websites
if [[ -d /var/www ]]; then
    # Keep default index.html
    rm -rf /var/www/*
    mkdir -p /var/www/html
    echo "<!DOCTYPE html><html><body><h1>It works!</h1></body></html>" > /var/www/html/index.html
    print_success "Đã xóa tất cả websites (giữ lại /var/www/html)"
fi

# Databases
data_dirs=(
    "/var/lib/mysql"
    "/var/lib/mariadb"
    "/var/lib/postgresql"
    "/var/lib/redis"
)

for dir in "${data_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        rm -rf "$dir"
        print_success "Đã xóa $dir"
    fi
done

# SSL Certificates
if [[ -d /etc/ssl/oziscript ]]; then
    rm -rf /etc/ssl/oziscript
    print_success "Đã xóa SSL certificates"
fi

# Logs
log_dirs=(
    "/var/log/nginx"
    "/var/log/php*"
    "/var/log/mysql"
    "/var/log/mariadb"
    "/var/log/postgresql"
    "/var/log/redis"
    "/var/log/supervisor"
    "/var/log/oziscript"
)

for log in "${log_dirs[@]}"; do
    rm -rf $log 2>/dev/null || true
done
print_success "Đã xóa logs"

#================================================================
# 5. REMOVE OZI SCRIPT
#================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Xóa Ozi Script..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ -L /usr/local/bin/ozi ]]; then
    rm -f /usr/local/bin/ozi
    print_success "Đã xóa symlink"
fi

if [[ -d /opt/oziscript ]]; then
    rm -rf /opt/oziscript
    print_success "Đã xóa /opt/oziscript"
fi

#================================================================
# 6. CLEANUP
#================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Cleanup..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

apt-get autoremove -y 2>/dev/null || true
apt-get autoclean -y 2>/dev/null || true
print_success "Đã cleanup packages"

# Remove users
for user in www-data nginx mysql postgres redis; do
    if id "$user" >/dev/null 2>&1; then
        userdel "$user" 2>/dev/null || true
    fi
done
print_success "Đã xóa service users"

# Remove PPA repositories
if [[ -f /etc/apt/sources.list.d/ondrej-ubuntu-php-*.list ]]; then
    rm -f /etc/apt/sources.list.d/ondrej-ubuntu-php-*.list
    print_success "Đã xóa PHP PPA"
fi

if [[ -f /etc/apt/sources.list.d/pgdg.list ]]; then
    rm -f /etc/apt/sources.list.d/pgdg.list
    print_success "Đã xóa PostgreSQL repo"
fi

apt-get update -qq 2>/dev/null || true

#================================================================
# DONE
#================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ HOÀN TẤT RESET VPS!${NC}"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "VPS đã được đưa về trạng thái Debian mặc định."
echo ""
echo "Bạn có thể cài đặt lại Ozi Script:"
echo "  bash <(curl -s https://raw.githubusercontent.com/OziNetworkVN/OziScripts/main/install.sh)"
echo ""
echo "Hoặc reboot VPS để clean hoàn toàn:"
echo "  reboot"
echo ""
