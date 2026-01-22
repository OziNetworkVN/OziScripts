#!/bin/bash
#================================================================
# Ozi Script - Module: Adminer
# Mô tả: Cài đặt Adminer (Database Manager)
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"
source "$OZI_DIR/core/config.sh"

#================================================================
# CONFIGURATION
#================================================================
ADMINER_VERSION="4.8.1"
ADMINER_DIR="$WWW_DIR/adminer"
ADMINER_DOMAIN="adminer.localhost"

#================================================================
# INSTALLATION
#================================================================

# Cài đặt Adminer
install_adminer() {
    print_header "CÀI ĐẶT ADMINER"
    
    if [[ -f "$ADMINER_DIR/index.php" ]]; then
        print_warning "Adminer đã được cài đặt"
        echo ""
        echo -e "  ${BOLD_CYAN}URL:${NC} http://YOUR_IP:8080"
        echo ""
        return 0
    fi
    
    print_info "Đang cài đặt Adminer..."
    
    # Create directory
    mkdir -p "$ADMINER_DIR"
    
    # Download Adminer
    curl -fsSL "https://github.com/vrana/adminer/releases/download/v${ADMINER_VERSION}/adminer-${ADMINER_VERSION}.php" \
        -o "$ADMINER_DIR/index.php"
    
    # Download CSS theme (optional but nice)
    curl -fsSL "https://raw.githubusercontent.com/vrana/adminer/master/designs/nette/adminer.css" \
        -o "$ADMINER_DIR/adminer.css" 2>/dev/null || true
    
    # Set permissions
    chown -R www-data:www-data "$ADMINER_DIR"
    chmod -R 755 "$ADMINER_DIR"
    
    # Create Nginx config on port 8080
    create_adminer_nginx_config
    
    print_success "Adminer đã được cài đặt!"
    echo ""
    echo -e "  ${BOLD_CYAN}URL:${NC} http://YOUR_IP:8080"
    echo -e "  ${BOLD_CYAN}Directory:${NC} $ADMINER_DIR"
    echo ""
    print_warning "Khuyến nghị: Bảo vệ Adminer bằng IP whitelist hoặc Basic Auth"
    
    log_info "Installed Adminer"
}

# Tạo Nginx config cho Adminer
create_adminer_nginx_config() {
    local php_version=$(get_default_php_version)
    [[ -z "$php_version" ]] && php_version="8.3"
    
    cat > "$NGINX_SITES_AVAILABLE/adminer" << EOF
# Adminer - Database Management
# ⚠️ Restrict access in production!

server {
    listen 8080;
    listen [::]:8080;
    server_name _;
    
    root $ADMINER_DIR;
    index index.php;
    
    # Restrict access (uncomment and modify as needed)
    # allow 192.168.1.0/24;
    # deny all;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location ~ \.php\$ {
        fastcgi_pass unix:/run/php/php${php_version}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF
    
    # Enable site
    ln -sf "$NGINX_SITES_AVAILABLE/adminer" "$NGINX_SITES_ENABLED/adminer"
    
    # Add port 8080 to firewall if UFW is enabled
    if command_exists ufw && ufw status | grep -q "active"; then
        ufw allow 8080/tcp
    fi
    
    # Test and reload nginx
    if nginx -t 2>/dev/null; then
        systemctl reload nginx
    fi
}

# Gỡ Adminer
remove_adminer() {
    if ! confirm "Bạn có chắc muốn gỡ Adminer?"; then
        return 0
    fi
    
    rm -rf "$ADMINER_DIR"
    rm -f "$NGINX_SITES_AVAILABLE/adminer"
    rm -f "$NGINX_SITES_ENABLED/adminer"
    
    nginx -t 2>/dev/null && systemctl reload nginx
    
    print_success "Adminer đã được gỡ"
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-install}" in
        install)
            install_adminer
            ;;
        remove)
            remove_adminer
            ;;
        *)
            echo "Sử dụng: $0 {install|remove}"
            ;;
    esac
fi
