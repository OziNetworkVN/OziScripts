#!/bin/bash
#================================================================
# Ozi Script - Unified Site Manager
# Mô tả: Quản lý site tập trung với CLI thống nhất
# Phiên bản: 2.0.0
#================================================================

set -euo pipefail

# Load dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"
source "$OZI_DIR/core/colors.sh"
source "$OZI_DIR/core/site-db.sh"
source "$OZI_DIR/core/nginx.sh"
source "$OZI_DIR/core/ssl-manager.sh"

#================================================================
# CREATE SITE
#================================================================

cmd_create() {
    require_root
    
    print_header "Tạo Website Mới"
    
    # Step 1: Select site type
    echo
    print_subheader "Chọn loại website"
    print_menu_item "1" "Laravel (PHP Framework)"
    print_menu_item "2" "WordPress (CMS)"
    print_menu_item "3" "Node.js (JavaScript)"
    print_menu_item "4" "Static HTML (Trang tĩnh)"
    echo
    
    read -p "$(echo -e "${BOLD_WHITE}Chọn loại [1-4]: ${NC}")" type_choice
    
    local site_type=""
    case "$type_choice" in
        1) site_type="laravel" ;;
        2) site_type="wordpress" ;;
        3) site_type="nodejs" ;;
        4) site_type="static" ;;
        *)
            print_error "Lựa chọn không hợp lệ"
            return 1
            ;;
    esac
    
    # Step 2: Get domain
    echo
    read -p "$(echo -e "${BOLD_WHITE}Tên miền (VD: example.com): ${NC}")" domain
    
    if [[ -z "$domain" ]]; then
        print_error "Tên miền không được để trống"
        return 1
    fi
    
    # Check if site already exists
    if site_exists "$domain"; then
        print_error "Website $domain đã tồn tại"
        return 1
    fi
    
    # Step 3: Get document root
    local default_root="/var/www/$domain"
    read -p "$(echo -e "${BOLD_WHITE}Đường dẫn thư mục [$default_root]: ${NC}")" root
    root="${root:-$default_root}"
    
    # Load type-specific handler
    source "$SCRIPT_DIR/types/${site_type}.sh"
    
    # Call type-specific create function
    if declare -f "create_${site_type}_site" >/dev/null; then
        "create_${site_type}_site" "$domain" "$root"
    else
        print_error "Handler cho loại $site_type chưa được triển khai"
        return 1
    fi
}

#================================================================
# LIST SITES
#================================================================

cmd_list() {
    print_header "Danh Sách Website"
    
    local sites=$(list_all_sites)
    
    if [[ -z "$sites" ]]; then
        print_info "Chưa có website nào"
        return 0
    fi
    
    printf "${BOLD_WHITE}%-30s %-12s %-10s %-8s %-15s${NC}\n" \
        "Domain" "Type" "PHP" "SSL" "Status"
    print_separator
    
    while read -r domain; do
        local site_data=$(get_site "$domain")
        local type=$(echo "$site_data" | jq -r '.type')
        local php=$(echo "$site_data" | jq -r '.php_version // "-"')
        local ssl=$(echo "$site_data" | jq -r '.ssl.enabled')
        local status=$(echo "$site_data" | jq -r '.status')
        
        local ssl_icon="✗"
        local ssl_color="${RED}"
        if [[ "$ssl" == "true" ]]; then
            ssl_icon="✓"
            ssl_color="${GREEN}"
        fi
        
        local status_color="${GREEN}"
        [[ "$status" != "active" ]] && status_color="${YELLOW}"
        
        printf "%-30s %-12s %-10s ${ssl_color}%-8s${NC} ${status_color}%-15s${NC}\n" \
            "$domain" "$type" "$php" "$ssl_icon" "$status"
    done <<< "$sites"
    
    echo
    print_info "Tổng số: $(echo "$sites" | wc -l) website"
}

#================================================================
# SITE INFO
#================================================================

cmd_info() {
    local domain="${1:-}"
    
    if [[ -z "$domain" ]]; then
        print_error "Vui lòng cung cấp tên miền"
        echo "Sử dụng: ozi site info <domain>"
        return 1
    fi
    
    if ! site_exists "$domain"; then
        print_error "Website không tồn tại: $domain"
        return 1
    fi
    
    local site_data=$(get_site "$domain")
    
    print_header "Thông Tin Website: $domain"
    
    # Basic info
    print_subheader "Thông Tin Cơ Bản"
    echo "Domain: $(echo "$site_data" | jq -r '.domain')"
    echo "Type: $(echo "$site_data" | jq -r '.type')"
    echo "Status: $(echo "$site_data" | jq -r '.status')"
    echo "Root: $(echo "$site_data" | jq -r '.root')"
    
    local php=$(echo "$site_data" | jq -r '.php_version')
    [[ "$php" != "null" && "$php" != "" ]] && echo "PHP Version: $php"
    
    # Aliases
    local aliases=$(echo "$site_data" | jq -r '.aliases[]?' 2>/dev/null)
    if [[ -n "$aliases" ]]; then
        echo
        print_subheader "Domain Aliases"
        while read -r alias; do
            echo "  - $alias"
        done <<< "$aliases"
    fi
    
    # SSL info
    local ssl_enabled=$(echo "$site_data" | jq -r '.ssl.enabled')
    if [[ "$ssl_enabled" == "true" ]]; then
        echo
        print_subheader "SSL Certificate"
        echo "Type: $(echo "$site_data" | jq -r '.ssl.type')"
        echo "Certificate: $(echo "$site_data" | jq -r '.ssl.cert_path')"
        echo "Expires: $(echo "$site_data" | jq -r '.ssl.expires_at')"
        echo "Auto-renew: $(echo "$site_data" | jq -r '.ssl.auto_renew')"
    fi
    
    # Database
    local db_type=$(echo "$site_data" | jq -r '.database.type')
    if [[ "$db_type" != "none" && "$db_type" != "null" ]]; then
        echo
        print_subheader "Database"
        echo "Type: $db_type"
        echo "Database: $(echo "$site_data" | jq -r '.database.name')"
        echo "User: $(echo "$site_data" | jq -r '.database.user')"
    fi
    
    # Features
    local features=$(echo "$site_data" | jq -r '.features | keys[]?' 2>/dev/null)
    if [[ -n "$features" ]]; then
        echo
        print_subheader "Features"
        while read -r feature; do
            local enabled=$(echo "$site_data" | jq -r ".features.\"$feature\"")
            [[ "$enabled" == "true" ]] && echo "  ✓ $feature"
        done <<< "$features"
    fi
    
    # Timestamps
    echo
    print_subheader "Timestamps"
    echo "Created: $(echo "$site_data" | jq -r '.created_at')"
    echo "Updated: $(echo "$site_data" | jq -r '.updated_at')"
}

#================================================================
# SSL MANAGEMENT
#================================================================

cmd_ssl() {
    require_root
    
    local action="${1:-}"
    shift || true
    
    case "$action" in
        install)
            ssl_install_wizard "$@"
            ;;
        remove)
            ssl_remove_cmd "$@"
            ;;
        renew)
            ssl_renew_cmd "$@"
            ;;
        status)
            ssl_status_cmd "$@"
            ;;
        list)
            list_all_ssl
            ;;
        auto-renew)
            auto_renew_expiring_ssl
            ;;
        *)
            show_ssl_help
            ;;
    esac
}

ssl_install_wizard() {
    local domain="${1:-}"
    
    if [[ -z "$domain" ]]; then
        read -p "$(echo -e "${BOLD_WHITE}Tên miền: ${NC}")" domain
    fi
    
    if ! site_exists "$domain"; then
        print_error "Website không tồn tại: $domain"
        return 1
    fi
    
    print_header "Cài Đặt SSL: $domain"
    
    echo
    print_menu_item "1" "Let's Encrypt (Free, Auto-renew)"
    print_menu_item "2" "Cloudflare Origin Certificate (15 years)"
    print_menu_item "3" "Custom SSL (Upload cert/key)"
    echo
    
    read -p "$(echo -e "${BOLD_WHITE}Chọn loại SSL [1-3]: ${NC}")" ssl_choice
    
    case "$ssl_choice" in
        1)
            # Let's Encrypt
            read -p "$(echo -e "${BOLD_WHITE}Email (tùy chọn): ${NC}")" email
            
            print_info "Đang cài đặt Let's Encrypt SSL..."
            if install_letsencrypt_ssl "$domain" "$email"; then
                print_success "✓ SSL đã được cài đặt thành công"
            else
                print_error "✗ Cài đặt SSL thất bại"
                return 1
            fi
            ;;
        2)
            # Cloudflare
            print_info "Nhập certificate (Ctrl+D khi hoàn thành):"
            local cert_content=$(cat)
            
            print_info "Nhập private key (Ctrl+D khi hoàn thành):"
            local key_content=$(cat)
            
            print_info "Đang cài đặt Cloudflare SSL..."
            if install_cloudflare_ssl "$domain" "$cert_content" "$key_content"; then
                print_success "✓ SSL đã được cài đặt thành công"
            else
                print_error "✗ Cài đặt SSL thất bại"
                return 1
            fi
            ;;
        3)
            # Custom
            print_info "Nhập certificate (Ctrl+D khi hoàn thành):"
            local cert_content=$(cat)
            
            print_info "Nhập private key (Ctrl+D khi hoàn thành):"
            local key_content=$(cat)
            
            print_info "Đang cài đặt Custom SSL..."
            if install_custom_ssl "$domain" "$cert_content" "$key_content"; then
                print_success "✓ SSL đã được cài đặt thành công"
            else
                print_error "✗ Cài đặt SSL thất bại"
                return 1
            fi
            ;;
        *)
            print_error "Lựa chọn không hợp lệ"
            return 1
            ;;
    esac
}

ssl_remove_cmd() {
    local domain="${1:-}"
    
    if [[ -z "$domain" ]]; then
        print_error "Vui lòng cung cấp tên miền"
        return 1
    fi
    
    if ! site_exists "$domain"; then
        print_error "Website không tồn tại: $domain"
        return 1
    fi
    
    if confirm "Xóa SSL cho $domain?"; then
        remove_ssl "$domain"
        print_success "✓ Đã xóa SSL"
    fi
}

ssl_renew_cmd() {
    local domain="${1:-}"
    
    if [[ -z "$domain" ]]; then
        print_error "Vui lòng cung cấp tên miền"
        return 1
    fi
    
    renew_letsencrypt_ssl "$domain"
}

ssl_status_cmd() {
    local domain="${1:-}"
    
    if [[ -z "$domain" ]]; then
        list_all_ssl
    else
        check_ssl_status "$domain"
    fi
}

show_ssl_help() {
    cat << 'EOF'
Sử dụng: ozi site ssl {command} [options]

Commands:
    install <domain>       Cài đặt SSL cho domain
    remove <domain>        Xóa SSL
    renew <domain>         Gia hạn Let's Encrypt SSL
    status [domain]        Kiểm tra trạng thái SSL
    list                   Liệt kê tất cả SSL
    auto-renew             Tự động gia hạn SSL sắp hết hạn

Examples:
    ozi site ssl install example.com
    ozi site ssl status example.com
    ozi site ssl list
EOF
}

#================================================================
# ALIAS MANAGEMENT
#================================================================

cmd_alias() {
    require_root
    
    local action="${1:-}"
    local domain="${2:-}"
    local alias="${3:-}"
    
    case "$action" in
        add)
            [[ -z "$domain" || -z "$alias" ]] && {
                print_error "Sử dụng: ozi site alias add <domain> <alias>"
                return 1
            }
            
            if ! site_exists "$domain"; then
                print_error "Website không tồn tại: $domain"
                return 1
            fi
            
            print_info "Thêm alias $alias cho $domain..."
            
            # Add to database
            add_site_alias "$domain" "$alias"
            
            # Add to Nginx config
            add_alias_to_config "$domain" "$alias"
            
            # Reload Nginx
            if test_nginx_config >/dev/null 2>&1; then
                reload_nginx
                print_success "✓ Đã thêm alias thành công"
            else
                print_error "✗ Nginx config test failed"
                return 1
            fi
            ;;
        remove)
            [[ -z "$domain" || -z "$alias" ]] && {
                print_error "Sử dụng: ozi site alias remove <domain> <alias>"
                return 1
            }
            
            if ! site_exists "$domain"; then
                print_error "Website không tồn tại: $domain"
                return 1
            fi
            
            # Remove from database
            remove_site_alias "$domain" "$alias"
            
            # Remove from Nginx config
            remove_alias_from_config "$domain" "$alias"
            
            # Reload Nginx
            test_nginx_config >/dev/null 2>&1 && reload_nginx
            
            print_success "✓ Đã xóa alias"
            ;;
        list)
            [[ -z "$domain" ]] && {
                print_error "Sử dụng: ozi site alias list <domain>"
                return 1
            }
            
            if ! site_exists "$domain"; then
                print_error "Website không tồn tại: $domain"
                return 1
            fi
            
            print_subheader "Aliases cho $domain"
            local aliases=$(get_site_aliases "$domain")
            if [[ -z "$aliases" ]]; then
                print_info "Không có alias nào"
            else
                while read -r alias; do
                    echo "  - $alias"
                done <<< "$aliases"
            fi
            ;;
        *)
            cat << 'EOF'
Sử dụng: ozi site alias {command} <domain> [alias]

Commands:
    add <domain> <alias>       Thêm domain alias
    remove <domain> <alias>    Xóa domain alias
    list <domain>              Liệt kê aliases

Examples:
    ozi site alias add example.com www.example.com
    ozi site alias list example.com
EOF
            ;;
    esac
}

#================================================================
# DELETE SITE
#================================================================

cmd_delete() {
    require_root
    
    local domain="${1:-}"
    
    if [[ -z "$domain" ]]; then
        print_error "Vui lòng cung cấp tên miền"
        echo "Sử dụng: ozi site delete <domain>"
        return 1
    fi
    
    if ! site_exists "$domain"; then
        print_error "Website không tồn tại: $domain"
        return 1
    fi
    
    print_warning "⚠ CẢNH BÁO: Hành động này sẽ xóa:"
    echo "  - Cấu hình Nginx"
    echo "  - Thư mục website"
    echo "  - Database (nếu có)"
    echo "  - SSL certificates"
    echo
    
    if ! confirm "Bạn có chắc chắn muốn xóa $domain?"; then
        print_info "Đã hủy"
        return 0
    fi
    
    print_info "Đang xóa $domain..."
    
    # Get site info
    local root=$(get_site "$domain" | jq -r '.root')
    local db_name=$(get_site "$domain" | jq -r '.database.name')
    local db_type=$(get_site "$domain" | jq -r '.database.type')
    
    # Remove SSL
    local ssl_enabled=$(get_site "$domain" | jq -r '.ssl.enabled')
    if [[ "$ssl_enabled" == "true" ]]; then
        print_info "Xóa SSL..."
        remove_ssl "$domain" 2>/dev/null || true
    fi
    
    # Remove Nginx config
    print_info "Xóa Nginx config..."
    delete_site_config "$domain"
    
    # Remove website directory
    if [[ -d "$root" ]]; then
        print_info "Xóa thư mục website..."
        rm -rf "$root"
    fi
    
    # Remove database
    if [[ "$db_type" == "mysql" && -n "$db_name" ]]; then
        print_info "Xóa database..."
        mysql -e "DROP DATABASE IF EXISTS \`$db_name\`;" 2>/dev/null || true
    fi
    
    # Remove from site database
    delete_site_entry "$domain"
    
    # Reload Nginx
    reload_nginx 2>/dev/null || true
    
    print_success "✓ Đã xóa $domain thành công"
}

#================================================================
# HELP
#================================================================

show_help() {
    cat << 'EOF'
Ozi Site Manager - Quản lý website tập trung

Sử dụng: ozi site {command} [options]

Commands:
    create              Tạo website mới
    list                Liệt kê tất cả website
    info <domain>       Xem thông tin chi tiết
    delete <domain>     Xóa website
    
    ssl                 Quản lý SSL certificates
    alias               Quản lý domain aliases

Examples:
    ozi site create
    ozi site list
    ozi site info example.com
    ozi site ssl install example.com
    ozi site alias add example.com www.example.com
    ozi site delete example.com
EOF
}

#================================================================
# MAIN
#================================================================

function main() {
    local cmd="${1:-help}"
    shift || true
    
    case "$cmd" in
        create)
            cmd_create "$@"
            ;;
        list)
            cmd_list "$@"
            ;;
        info)
            cmd_info "$@"
            ;;
        ssl)
            cmd_ssl "$@"
            ;;
        alias)
            cmd_alias "$@"
            ;;
        delete)
            cmd_delete "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $cmd"
            show_help
            return 1
            ;;
    esac
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
