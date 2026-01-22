#!/bin/bash
#================================================================
# Ozi Script - Module: WordPress Deploy
# Mô tả: Deploy WordPress
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"
source "$OZI_DIR/core/config.sh"

#================================================================
# DEPLOY FUNCTIONS
#================================================================

# Download và cài đặt WordPress mới
install_wordpress() {
    local domain="$1"
    local db_name="${2:-}"
    local db_user="${3:-}"
    local db_pass="${4:-}"
    
    if [[ -z "$domain" ]]; then
        print_error "Vui lòng nhập domain"
        return 1
    fi
    
    local app_dir="$WWW_DIR/$domain/public"
    
    print_header "CÀI ĐẶT WORDPRESS: $domain"
    
    # Create directory
    mkdir -p "$app_dir"
    cd "$app_dir"
    
    # Download WordPress
    print_info "Đang tải WordPress..."
    curl -fsSL https://wordpress.org/latest.tar.gz | tar -xz --strip-components=1
    
    # Copy wp-config
    if [[ -f "wp-config-sample.php" ]]; then
        cp wp-config-sample.php wp-config.php
        
        # Update database settings if provided
        if [[ -n "$db_name" ]]; then
            sed -i "s/database_name_here/$db_name/" wp-config.php
            sed -i "s/username_here/$db_user/" wp-config.php
            sed -i "s/password_here/$db_pass/" wp-config.php
            
            # Generate salts
            print_info "Đang tạo security keys..."
            local salts=$(curl -fsSL https://api.wordpress.org/secret-key/1.1/salt/)
            
            # Replace placeholder salts with real ones
            sed -i "/AUTH_KEY/d" wp-config.php
            sed -i "/SECURE_AUTH_KEY/d" wp-config.php
            sed -i "/LOGGED_IN_KEY/d" wp-config.php
            sed -i "/NONCE_KEY/d" wp-config.php
            sed -i "/AUTH_SALT/d" wp-config.php
            sed -i "/SECURE_AUTH_SALT/d" wp-config.php
            sed -i "/LOGGED_IN_SALT/d" wp-config.php
            sed -i "/NONCE_SALT/d" wp-config.php
            
            echo "$salts" >> wp-config.php
        fi
    fi
    
    # Set permissions
    chown -R www-data:www-data "$WWW_DIR/$domain"
    chmod -R 755 "$WWW_DIR/$domain"
    chmod 640 "$app_dir/wp-config.php"
    
    print_success "WordPress đã được cài đặt!"
    echo ""
    echo -e "  ${BOLD_CYAN}URL:${NC} http://$domain"
    echo -e "  ${BOLD_CYAN}Path:${NC} $app_dir"
    echo ""
    print_info "Truy cập http://$domain để hoàn tất cài đặt"
    
    log_info "Installed WordPress: $domain"
}

# Interactive install
install_wordpress_interactive() {
    print_header "CÀI ĐẶT WORDPRESS"
    
    local domain=$(read_input "Nhập domain")
    if [[ -z "$domain" ]]; then
        print_error "Domain không được để trống"
        return 1
    fi
    
    # Check if site exists
    if [[ -d "$WWW_DIR/$domain" ]]; then
        if ! confirm "Thư mục đã tồn tại. Ghi đè?"; then
            return 0
        fi
    fi
    
    echo ""
    print_info "Cấu hình Database (bỏ trống nếu muốn cấu hình sau)"
    local db_name=$(read_input "Database name" "")
    
    if [[ -n "$db_name" ]]; then
        local db_user=$(read_input "Database user" "$db_name")
        local db_pass=$(read_input "Database password" "")
    fi
    
    install_wordpress "$domain" "$db_name" "$db_user" "$db_pass"
}

# Update WordPress core
update_wordpress() {
    local domain="$1"
    local app_dir="$WWW_DIR/$domain/public"
    
    if [[ ! -f "$app_dir/wp-config.php" ]]; then
        print_error "Không tìm thấy WordPress tại: $domain"
        return 1
    fi
    
    print_header "CẬP NHẬT WORDPRESS: $domain"
    
    cd "$app_dir"
    
    # Install WP-CLI if not exists
    if ! command_exists wp; then
        print_info "Đang cài đặt WP-CLI..."
        curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp
        chmod +x /usr/local/bin/wp
    fi
    
    # Update WordPress
    print_info "Đang cập nhật WordPress core..."
    sudo -u www-data wp core update --path="$app_dir"
    
    print_info "Đang cập nhật plugins..."
    sudo -u www-data wp plugin update --all --path="$app_dir"
    
    print_info "Đang cập nhật themes..."
    sudo -u www-data wp theme update --all --path="$app_dir"
    
    print_success "WordPress đã được cập nhật!"
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-}" in
        install)
            install_wordpress_interactive
            ;;
        update)
            update_wordpress "${2:-}"
            ;;
        *)
            install_wordpress_interactive
            ;;
    esac
fi
