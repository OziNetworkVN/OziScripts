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
    
    if ! is_installed "nginx"; then
        print_error "Nginx chưa được cài đặt. Vui lòng cài đặt Nginx trước."
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

# Tạo Nginx config từ template
generate_nginx_config() {
    local template_name="$1"
    local domain="$2"
    local php_version="${3:-}"
    local port="${4:-}"
    
    local template_file="$OZI_DIR/templates/nginx/${template_name}.conf"
    local target_file="$NGINX_SITES_AVAILABLE/$domain"
    
    if [[ ! -f "$template_file" ]]; then
        print_error "Không tìm thấy template: $template_name"
        return 1
    fi
    
    # Tạo slug cho domain (xoá dấu chấm)
    local domain_slug=$(echo "$domain" | sed 's/\./_/g')
    local site_root="$WWW_DIR/$domain"
    
    # Read template and replace markers
    sed "s|{domain}|$domain|g; 
         s|{domain_slug}|$domain_slug|g;
         s|{root}|$site_root|g;
         s|{php_version}|$php_version|g;
         s|{port}|$port|g" "$template_file" > "$target_file"
    
    return 0
}

# Tạo Nginx config cho Laravel
create_laravel_nginx_config() {
    generate_nginx_config "laravel" "$1" "$2"
}

# Tạo Nginx config cho WordPress
create_wordpress_nginx_config() {
    generate_nginx_config "wordpress" "$1" "$2"
}

# Tạo Nginx config cho Node.js
create_nodejs_nginx_config() {
    local port=$(read_input "Nhập port app đang chạy" "3000")
    generate_nginx_config "nodejs" "$1" "" "$port"
}

# Tạo Nginx config cho Static
create_static_nginx_config() {
    generate_nginx_config "static" "$1"
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

# Enable website
enable_site() {
    local domain="$1"

    if [[ ! -f "$NGINX_SITES_AVAILABLE/$domain" ]]; then
        print_error "Website '$domain' không tồn tại"
        return 1
    fi

    if [[ -L "$NGINX_SITES_ENABLED/$domain" ]]; then
        print_warning "Website '$domain' đã được enable"
        return 0
    fi

    ln -sf "$NGINX_SITES_AVAILABLE/$domain" "$NGINX_SITES_ENABLED/$domain"
    nginx -t && systemctl reload nginx

    print_success "Website '$domain' đã được enable"
}

# Disable website
disable_site() {
    local domain="$1"

    if [[ ! -L "$NGINX_SITES_ENABLED/$domain" ]]; then
        print_warning "Website '$domain' chưa được enable"
        return 0
    fi

    rm -f "$NGINX_SITES_ENABLED/$domain"
    nginx -t && systemctl reload nginx

    print_success "Website '$domain' đã được disable"
}

# Xem logs website
view_site_logs() {
    local domain="$1"
    local log_type="${2:-error}" # access or error

    if [[ -z "$domain" ]]; then
        # Interactive selection
        list_sites
        domain=$(read_input "Nhập domain")
    fi

    if [[ ! -d "$WWW_DIR/$domain/logs" ]]; then
        print_error "Không tìm thấy logs cho website '$domain'"
        return 1
    fi

    local log_file="$WWW_DIR/$domain/logs/${log_type}.log"

    if [[ ! -f "$log_file" ]]; then
        print_error "Không tìm thấy file log: $log_file"
        return 1
    fi

    print_header "WEBSITE LOGS: $domain ($log_type)"
    echo ""
    tail -f "$log_file"
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
        enable)
            enable_site "${2:-}"
            ;;
        disable)
            disable_site "${2:-}"
            ;;
        logs)
            view_site_logs "${2:-}" "${3:-error}"
            ;;
        *)
            create_site_interactive
            ;;
    esac
fi
