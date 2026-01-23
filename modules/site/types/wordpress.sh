#!/bin/bash
#================================================================
# Ozi Script - WordPress Site Handler
# Mô tả: Xử lý tạo và quản lý WordPress sites
# Phiên bản: 2.0.0
#================================================================

set -euo pipefail

#================================================================
# CREATE WORDPRESS SITE
#================================================================

create_wordpress_site() {
    local domain="$1"
    local root="$2"
    
    print_subheader "WordPress Configuration"
    
    # Select PHP version
    local installed_php=$(get_installed_php_versions 2>/dev/null || echo "")
    
    if [[ -z "$installed_php" ]]; then
        print_error "Không tìm thấy PHP. Vui lòng cài đặt PHP trước."
        return 1
    fi
    
    echo
    print_info "PHP versions available:"
    local php_array=($installed_php)
    local i=1
    for php in "${php_array[@]}"; do
        print_menu_item "$i" "PHP $php"
        ((i++))
    done
    echo
    
    read -p "$(echo -e "${BOLD_WHITE}Chọn PHP version [1-${#php_array[@]}]: ${NC}")" php_choice
    local php_version="${php_array[$((php_choice-1))]}"
    
    # Database configuration
    local db_name="wp_$(echo $domain | tr '.' '_')"
    local db_user="wp_$(echo $domain | tr '.' '_' | cut -c1-16)"
    local db_pass="$(openssl rand -base64 16)"
    
    print_info "Đang tạo database..."
    mysql -e "CREATE DATABASE IF NOT EXISTS \`$db_name\`;" 2>/dev/null || true
    mysql -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass';" 2>/dev/null || true
    mysql -e "GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$db_user'@'localhost';" 2>/dev/null || true
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true
    
    print_success "✓ Database created: $db_name"
    
    # Create site entry
    print_info "Đang tạo site entry..."
    create_site_entry "$domain" "wordpress" "$php_version" "$root"
    
    # Update database info
    update_site_database "$domain" "$db_name" "$db_user" "mysql"
    
    # Create directory
    print_info "Đang tạo thư mục..."
    mkdir -p "$root"
    
    # Download WordPress
    if confirm "Tải WordPress tự động?"; then
        print_info "Đang tải WordPress..."
        
        # Install WP-CLI if not exists
        if ! command -v wp >/dev/null 2>&1; then
            print_info "Installing WP-CLI..."
            curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
            chmod +x wp-cli.phar
            mv wp-cli.phar /usr/local/bin/wp
        fi
        
        # Download WordPress
        cd "$root"
        sudo -u www-data wp core download --allow-root 2>/dev/null || {
            print_warning "WP-CLI download failed, using curl..."
            curl -sO https://wordpress.org/latest.tar.gz
            tar -xzf latest.tar.gz --strip-components=1
            rm latest.tar.gz
        }
        
        print_success "✓ WordPress downloaded"
    fi
    
    # Generate Nginx config
    print_info "Đang tạo Nginx config..."
    generate_nginx_config "$domain" "wordpress" "$root" "$php_version"
    
    # Test and reload Nginx
    if test_nginx_config >/dev/null 2>&1; then
        reload_nginx
        print_success "✓ Nginx config loaded"
    else
        print_error "✗ Nginx config test failed"
        return 1
    fi
    
    # Set permissions
    print_info "Đang thiết lập quyền..."
    chown -R www-data:www-data "$root"
    find "$root" -type d -exec chmod 755 {} \;
    find "$root" -type f -exec chmod 644 {} \;
    
    # Save credentials
    mkdir -p "/root/.oziscript/db-credentials"
    cat > "/root/.oziscript/db-credentials/$domain.txt" <<EOF
Database: $db_name
User: $db_user
Password: $db_pass
EOF
    chmod 600 "/root/.oziscript/db-credentials/$domain.txt"
    
    print_separator
    print_success "✓ WordPress site created successfully!"
    echo
    print_info "Domain: $domain"
    print_info "Root: $root"
    print_info "PHP: $php_version"
    
    echo
    print_subheader "Database Credentials"
    print_info "Database: $db_name"
    print_info "User: $db_user"
    print_info "Password: $db_pass"
    print_info "Saved to: /root/.oziscript/db-credentials/$domain.txt"
    
    echo
    print_subheader "Next Steps"
    echo "1. Visit: http://$domain"
    echo "2. Complete WordPress installation"
    echo "3. Use database credentials above"
    echo "4. Install SSL: ozi site ssl install $domain"
}

#================================================================
# EXPORT
#================================================================

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    export -f create_wordpress_site
fi
