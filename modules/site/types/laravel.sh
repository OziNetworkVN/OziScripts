#!/bin/bash
#================================================================
# Ozi Script - Laravel Site Handler
# Mô tả: Xử lý tạo và quản lý Laravel sites
# Phiên bản: 2.0.0
#================================================================

set -euo pipefail

#================================================================
# CREATE LARAVEL SITE
#================================================================

create_laravel_site() {
    local domain="$1"
    local root="$2"
    
    print_subheader "Laravel Configuration"
    
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
    
    # Check if using Octane
    echo
    if confirm "Sử dụng Laravel Octane?"; then
        local use_octane="true"
        read -p "$(echo -e "${BOLD_WHITE}Octane port [8000]: ${NC}")" octane_port
        octane_port="${octane_port:-8000}"
    else
        local use_octane="false"
        local octane_port="8000"
    fi
    
    # Database configuration
    echo
    if confirm "Tạo MySQL database?"; then
        local db_name="db_$(echo $domain | tr '.' '_')"
        local db_user="user_$(echo $domain | tr '.' '_' | cut -c1-16)"
        local db_pass="$(openssl rand -base64 16)"
        
        print_info "Đang tạo database..."
        mysql -e "CREATE DATABASE IF NOT EXISTS \`$db_name\`;" 2>/dev/null || true
        mysql -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass';" 2>/dev/null || true
        mysql -e "GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$db_user'@'localhost';" 2>/dev/null || true
        mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true
        
        print_success "✓ Database created: $db_name"
        print_info "Database: $db_name"
        print_info "User: $db_user"
        print_info "Password: $db_pass"
        
        # Save password to file
        mkdir -p "/root/.oziscript/db-credentials"
        echo "Database: $db_name" > "/root/.oziscript/db-credentials/$domain.txt"
        echo "User: $db_user" >> "/root/.oziscript/db-credentials/$domain.txt"
        echo "Password: $db_pass" >> "/root/.oziscript/db-credentials/$domain.txt"
        chmod 600 "/root/.oziscript/db-credentials/$domain.txt"
    else
        local db_name=""
        local db_user=""
        local db_type="none"
    fi
    
    # Create site entry in database
    print_info "Đang tạo site entry..."
    create_site_entry "$domain" "laravel" "$php_version" "$root"
    
    # Update database info
    if [[ -n "$db_name" ]]; then
        update_site_database "$domain" "$db_name" "$db_user" "mysql"
    fi
    
    # Enable features
    if [[ "$use_octane" == "true" ]]; then
        enable_site_feature "$domain" "octane"
        update_site_field "$domain" "features.octane_port" "$octane_port"
    fi
    
    # Create directory structure
    print_info "Đang tạo thư mục..."
    mkdir -p "$root"
    
    # Generate Nginx config
    print_info "Đang tạo Nginx config..."
    generate_nginx_config "$domain" "laravel" "$root" "$php_version" "$use_octane" "$octane_port"
    
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
    
    print_separator
    print_success "✓ Laravel site created successfully!"
    echo
    print_info "Domain: $domain"
    print_info "Root: $root"
    print_info "PHP: $php_version"
    [[ "$use_octane" == "true" ]] && print_info "Octane: Enabled (Port $octane_port)"
    
    if [[ -n "$db_name" ]]; then
        echo
        print_subheader "Database Credentials"
        print_info "Database: $db_name"
        print_info "User: $db_user"
        print_info "Password: $db_pass"
        print_info "Saved to: /root/.oziscript/db-credentials/$domain.txt"
    fi
    
    echo
    print_subheader "Next Steps"
    echo "1. Upload Laravel code to: $root"
    echo "2. Configure .env file with database credentials"
    echo "3. Run: php artisan migrate"
    if [[ "$use_octane" == "true" ]]; then
        echo "4. Start Octane: php artisan octane:start --port=$octane_port"
    fi
    echo "5. Install SSL: ozi site ssl install $domain"
}

#================================================================
# EXPORT
#================================================================

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    export -f create_laravel_site
fi
