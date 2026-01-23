#!/bin/bash
#================================================================
# Ozi Script - Reinstall Nginx
# Mô tả: Cài lại Nginx từ đầu
#================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  CÀI LẠI NGINX${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Remove completely
echo -e "${YELLOW}→${NC} Xóa Nginx cũ hoàn toàn..."
systemctl stop nginx 2>/dev/null || true
apt-get remove --purge -y nginx nginx-common nginx-core 2>/dev/null || true
apt-get autoremove -y 2>/dev/null || true
rm -rf /etc/nginx
rm -rf /var/log/nginx
rm -rf /var/lib/nginx

# Install fresh
echo -e "${YELLOW}→${NC} Cài đặt Nginx mới..."
apt-get update
apt-get install -y nginx

# Create www-data user if not exists
if ! id -u www-data >/dev/null 2>&1; then
    echo -e "${YELLOW}→${NC} Tạo user www-data..."
    useradd -r -s /bin/false www-data || true
fi

# Setup directories
echo -e "${YELLOW}→${NC} Tạo thư mục cần thiết..."
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled
mkdir -p /var/www
chown -R www-data:www-data /var/www

# Test config
echo -e "${YELLOW}→${NC} Kiểm tra cấu hình..."
if nginx -t; then
    echo -e "${GREEN}✓${NC} Nginx config OK"
    
    # Start service
    systemctl enable nginx
    systemctl start nginx
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  CÀI ĐẶT THÀNH CÔNG!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "Status: $(systemctl is-active nginx)"
    echo -e "Version: $(nginx -v 2>&1 | cut -d'/' -f2)"
    echo ""
    echo -e "${BLUE}Bước tiếp theo:${NC}"
    echo -e "  1. Tạo lại các website: ${YELLOW}ozi site create${NC}"
    echo -e "  2. Cài lại SSL nếu cần: ${YELLOW}ozi ssl install${NC}"
    echo ""
else
    echo -e "${RED}✗${NC} Nginx config có lỗi"
    exit 1
fi
