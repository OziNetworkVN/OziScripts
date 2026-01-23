#!/bin/bash
#================================================================
# Ozi Script - Config Module
# Mô tả: Quản lý cấu hình
# Phiên bản: 1.0.3
#================================================================

#================================================================
# CONFIGURATION PATHS
#================================================================
OZI_VERSION="1.0.3"
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
OZI_CONFIG_DIR="${OZI_CONFIG_DIR:-/etc/oziscript}"
OZI_LOG_DIR="${OZI_LOG_DIR:-/var/log/oziscript}"
OZI_LOG_FILE="$OZI_LOG_DIR/ozi.log"
OZI_CONFIG_FILE="$OZI_CONFIG_DIR/config"
OZI_CLOUDFLARE_CONFIG="$OZI_CONFIG_DIR/cloudflare.conf"

# Web directories
WWW_DIR="/var/www"
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
SSL_DIR="/etc/ssl/oziscript"

# Backup
BACKUP_DIR="/var/backups/oziscript"

#================================================================
# CONFIG FUNCTIONS
#================================================================

# Khởi tạo config
init_config() {
    # Tạo các thư mục cần thiết
    mkdir -p "$OZI_CONFIG_DIR"
    mkdir -p "$OZI_LOG_DIR"
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$WWW_DIR"
    mkdir -p "$SSL_DIR"
    
    # Tạo file config nếu chưa có
    if [[ ! -f "$OZI_CONFIG_FILE" ]]; then
        cat > "$OZI_CONFIG_FILE" << 'EOF'
# Ozi Script Configuration
# Generated automatically

# Default settings
DEFAULT_PHP_VERSION=8.3
DEFAULT_DB_TYPE=postgresql
TIMEZONE=Asia/Ho_Chi_Minh

# Cloudflare (set via ozi ssl cloudflare)
CF_API_TOKEN=

# Backup settings
BACKUP_RETENTION_DAYS=7
OFFSITE_BACKUP_ENABLED=false
EOF
    fi
    
    # Set permissions
    chmod 600 "$OZI_CONFIG_FILE"
    chmod 600 "$OZI_CLOUDFLARE_CONFIG" 2>/dev/null || true
}

# Đọc giá trị config
get_config() {
    local key="$1"
    local default="${2:-}"
    
    if [[ -f "$OZI_CONFIG_FILE" ]]; then
        local value=$(grep "^${key}=" "$OZI_CONFIG_FILE" | cut -d= -f2-)
        echo "${value:-$default}"
    else
        echo "$default"
    fi
}

# Ghi giá trị config
set_config() {
    local key="$1"
    local value="$2"
    
    if [[ ! -f "$OZI_CONFIG_FILE" ]]; then
        init_config
    fi
    
    # Nếu key đã tồn tại, update nó
    if grep -q "^${key}=" "$OZI_CONFIG_FILE"; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$OZI_CONFIG_FILE"
    else
        # Thêm mới
        echo "${key}=${value}" >> "$OZI_CONFIG_FILE"
    fi
}

# Load config vào environment
load_config() {
    if [[ -f "$OZI_CONFIG_FILE" ]]; then
        # Parse config file, ignore comments
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ "$key" =~ ^#.*$ ]] && continue
            [[ -z "$key" ]] && continue
            
            # Export to environment
            export "$key"="$value"
        done < <(grep -v '^#' "$OZI_CONFIG_FILE" | grep -v '^$')
    fi
}

#================================================================
# CLOUDFLARE CONFIG
#================================================================

# Lưu Cloudflare token
save_cloudflare_token() {
    local token="$1"
    
    cat > "$OZI_CLOUDFLARE_CONFIG" << EOF
# Cloudflare API Configuration
# ⚠️ Keep this file secure!
CF_API_TOKEN=$token
EOF
    
    chmod 600 "$OZI_CLOUDFLARE_CONFIG"
}

# Đọc Cloudflare token
get_cloudflare_token() {
    if [[ -f "$OZI_CLOUDFLARE_CONFIG" ]]; then
        grep "^CF_API_TOKEN=" "$OZI_CLOUDFLARE_CONFIG" | cut -d= -f2-
    else
        echo ""
    fi
}

#================================================================
# PHP VERSION MANAGEMENT
#================================================================

# Lấy danh sách PHP đã cài
get_installed_php_versions() {
    local versions=""
    
    for v in 7.4 8.0 8.1 8.2 8.3 8.4; do
        if is_installed "php${v}-fpm" 2>/dev/null; then
            versions="$versions $v"
        fi
    done
    
    echo "$versions" | xargs
}

# Lấy PHP version mặc định
get_default_php_version() {
    if command_exists php; then
        php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;"
    else
        echo ""
    fi
}

#================================================================
# DATABASE INFO
#================================================================

# Kiểm tra PostgreSQL đã cài
is_postgresql_installed() {
    is_installed "postgresql" && is_service_running "postgresql"
}

# Kiểm tra MySQL đã cài
is_mysql_installed() {
    (is_installed "mysql-server" || is_installed "mariadb-server") && \
    (is_service_running "mysql" || is_service_running "mariadb")
}
