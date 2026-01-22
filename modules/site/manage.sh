#!/bin/bash
#================================================================
# Ozi Script - Module: Site Management
# Mô tả: Tạo và quản lý website
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"
source "$OZI_DIR/core/config.sh"

#================================================================
# SITE CREATION
#================================================================

# Tạo website mới
create_site() {
    local site_type="$1"
    local domain="$2"
    local php_version="${3:-8.3}"
    
    if [[ -z "$domain" ]]; then
        print_error "Vui lòng nhập tên domain"
        return 1
    fi
    
    print_header "TẠO WEBSITE: $domain"
    
    # Create directories
    local site_root="$WWW_DIR/$domain"
    mkdir -p "$site_root/public"
    mkdir -p "$site_root/logs"
    
    # Create test index file
    echo "<?php phpinfo();" > "$site_root/public/index.php"
    
    # Generate Nginx config based on type
    case "$site_type" in
        laravel)
            create_laravel_nginx_config "$domain" "$php_version"
            ;;
        wordpress)
            create_wordpress_nginx_config "$domain" "$php_version"
            ;;
        nodejs)
            create_nodejs_nginx_config "$domain"
            ;;
        static)
            create_static_nginx_config "$domain"
            ;;
        *)
            create_laravel_nginx_config "$domain" "$php_version"
            ;;
    esac
    
    # Set permissions
    chown -R www-data:www-data "$site_root"
    chmod -R 755 "$site_root"
    
    # Enable site
    ln -sf "$NGINX_SITES_AVAILABLE/$domain" "$NGINX_SITES_ENABLED/$domain"
    
    # Test and reload nginx
    if nginx -t 2>/dev/null; then
        systemctl reload nginx
        print_success "Website đã được tạo!"
        echo ""
        echo -e "  ${BOLD_CYAN}Domain:${NC}     $domain"
        echo -e "  ${BOLD_CYAN}Root:${NC}       $site_root"
        echo -e "  ${BOLD_CYAN}Public:${NC}     $site_root/public"
        echo -e "  ${BOLD_CYAN}Logs:${NC}       $site_root/logs"
        echo ""
        print_info "Hãy trỏ DNS của domain về IP server này."
        log_info "Created site: $domain ($site_type)"
    else
        print_error "Nginx config có lỗi"
        rm -f "$NGINX_SITES_AVAILABLE/$domain"
        rm -f "$NGINX_SITES_ENABLED/$domain"
        return 1
    fi
}

# Tạo Nginx config cho Laravel
create_laravel_nginx_config() {
    local domain="$1"
    local php_version="$2"
    
    cat > "$NGINX_SITES_AVAILABLE/$domain" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;
    
    root $WWW_DIR/$domain/public;
    index index.php index.html;
    
    access_log $WWW_DIR/$domain/logs/access.log;
    error_log $WWW_DIR/$domain/logs/error.log;
    
    # Security headers
    include snippets/security-headers.conf;
    
    # Max upload
    client_max_body_size 100M;
    
    # Gzip
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location ~ \.php\$ {
        fastcgi_pass unix:/run/php/php${php_version}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }
    
    # Static files
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff2|woff|ttf|svg|webp)\$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    # Block sensitive files
    location ~ /\.(?!well-known) {
        deny all;
    }
}
EOF
}

# Tạo Nginx config cho WordPress
create_wordpress_nginx_config() {
    local domain="$1"
    local php_version="$2"
    
    cat > "$NGINX_SITES_AVAILABLE/$domain" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;
    
    root $WWW_DIR/$domain/public;
    index index.php index.html;
    
    access_log $WWW_DIR/$domain/logs/access.log;
    error_log $WWW_DIR/$domain/logs/error.log;
    
    client_max_body_size 100M;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    location ~ \.php\$ {
        fastcgi_pass unix:/run/php/php${php_version}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    # WP Admin protection
    location /wp-admin {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    # Block xmlrpc
    location = /xmlrpc.php {
        deny all;
    }
    
    # Static files
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff2)\$ {
        expires 30d;
    }
    
    location ~ /\.(?!well-known) {
        deny all;
    }
}
EOF
}

# Tạo Nginx config cho Node.js
create_nodejs_nginx_config() {
    local domain="$1"
    local port="${2:-3000}"
    
    cat > "$NGINX_SITES_AVAILABLE/$domain" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;
    
    access_log $WWW_DIR/$domain/logs/access.log;
    error_log $WWW_DIR/$domain/logs/error.log;
    
    location / {
        proxy_pass http://127.0.0.1:${port};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
}

# Tạo Nginx config cho Static
create_static_nginx_config() {
    local domain="$1"
    
    cat > "$NGINX_SITES_AVAILABLE/$domain" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;
    
    root $WWW_DIR/$domain/public;
    index index.html;
    
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff2)\$ {
        expires 30d;
    }
}
EOF
}

# Interactive create site
create_site_interactive() {
    print_header "TẠO WEBSITE MỚI"
    
    echo "  Loại website:"
    echo ""
    print_menu_item "1" "Laravel / PHP"
    print_menu_item "2" "WordPress"
    print_menu_item "3" "Node.js"
    print_menu_item "4" "Static (HTML/React/Vue)"
    echo ""
    echo -e "  ${BOLD_YELLOW}[0]${NC} Quay lại"
    echo ""
    
    read -p "$(echo -e "${BOLD_WHITE}Chọn loại website [0-4]: ${NC}")" type_choice
    
    [[ "$type_choice" == "0" ]] && return 0
    
    local site_type
    case "$type_choice" in
        1) site_type="laravel" ;;
        2) site_type="wordpress" ;;
        3) site_type="nodejs" ;;
        4) site_type="static" ;;
        *) print_error "Lựa chọn không hợp lệ"; return 1 ;;
    esac
    
    echo ""
    local domain=$(read_input "Nhập domain (vd: example.com)")
    
    if [[ -z "$domain" ]]; then
        print_error "Domain không được để trống"
        return 1
    fi
    
    # Check if site exists
    if [[ -f "$NGINX_SITES_AVAILABLE/$domain" ]]; then
        print_error "Website '$domain' đã tồn tại"
        return 1
    fi
    
    local php_version="8.3"
    if [[ "$site_type" == "laravel" ]] || [[ "$site_type" == "wordpress" ]]; then
        php_version=$(read_input "PHP version" "8.3")
    fi
    
    create_site "$site_type" "$domain" "$php_version"
}

#================================================================
# LISTING & MANAGEMENT
#================================================================

# Liệt kê websites
list_sites() {
    print_header "DANH SÁCH WEBSITE"
    
    local sites=$(ls -1 "$NGINX_SITES_AVAILABLE" 2>/dev/null | grep -v default)
    
    if [[ -z "$sites" ]]; then
        print_warning "Chưa có website nào"
        return 0
    fi
    
    echo ""
    for site in $sites; do
        local status="${RED}disabled${NC}"
        if [[ -L "$NGINX_SITES_ENABLED/$site" ]]; then
            status="${GREEN}enabled${NC}"
        fi
        
        echo -e "  ${BOLD_CYAN}▸${NC} $site [$status]"
    done
    echo ""
}

# Xoá website
delete_site() {
    local domain="$1"
    
    if [[ ! -f "$NGINX_SITES_AVAILABLE/$domain" ]]; then
        print_error "Website '$domain' không tồn tại"
        return 1
    fi
    
    if ! confirm "Bạn có chắc muốn xoá website '$domain'?"; then
        return 0
    fi
    
    # Remove nginx config
    rm -f "$NGINX_SITES_AVAILABLE/$domain"
    rm -f "$NGINX_SITES_ENABLED/$domain"
    
    # Ask about removing files
    if confirm "Xoá cả thư mục website ($WWW_DIR/$domain)?"; then
        rm -rf "$WWW_DIR/$domain"
    fi
    
    nginx -t && systemctl reload nginx
    
    print_success "Website '$domain' đã được xoá"
    log_info "Deleted site: $domain"
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-}" in
        create)
            create_site "${2:-laravel}" "${3:-}" "${4:-8.3}"
            ;;
        list)
            list_sites
            ;;
        delete)
            delete_site "${2:-}"
            ;;
        *)
            create_site_interactive
            ;;
    esac
fi
