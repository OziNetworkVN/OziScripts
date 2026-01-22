#!/bin/bash
#================================================================
# Ozi Script - Module: Cloudflare SSL
# Mô tả: Tạo SSL 15 năm từ Cloudflare Origin Certificate
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"
source "$OZI_DIR/core/config.sh"

#================================================================
# CLOUDFLARE API
#================================================================
CF_API_URL="https://api.cloudflare.com/client/v4"

# Cấu hình Cloudflare API Token
configure_cloudflare_api() {
    print_header "CẤU HÌNH CLOUDFLARE API"
    
    echo "  Để tạo SSL 15 năm, bạn cần Cloudflare API Token."
    echo ""
    echo "  Hướng dẫn lấy token:"
    echo "  1. Đăng nhập https://dash.cloudflare.com/"
    echo "  2. Click avatar → My Profile → API Tokens"
    echo "  3. Create Token → Create Custom Token"
    echo "  4. Quyền cần thiết:"
    echo "     - SSL and Certificates → Origin Certificates → Edit"
    echo "     - Zone → Zone → Read"
    echo ""
    
    local token=$(read_secret "Nhập API Token")
    
    if [[ -z "$token" ]]; then
        print_error "Token không được để trống"
        return 1
    fi
    
    # Verify token
    print_info "Đang xác thực token..."
    
    local response=$(curl -s -X GET "${CF_API_URL}/user/tokens/verify" \
        -H "Authorization: Bearer ${token}" \
        -H "Content-Type: application/json")
    
    if echo "$response" | grep -q '"success":true'; then
        save_cloudflare_token "$token"
        print_success "Token đã được lưu thành công!"
    else
        print_error "Token không hợp lệ"
        echo "$response" | grep -o '"message":"[^"]*"' | head -1
        return 1
    fi
}

# Lấy Zone ID từ domain
get_zone_id() {
    local domain="$1"
    local token="$2"
    
    # Extract root domain
    local root_domain=$(echo "$domain" | awk -F. '{print $(NF-1)"."$NF}')
    
    local response=$(curl -s -X GET "${CF_API_URL}/zones?name=${root_domain}" \
        -H "Authorization: Bearer ${token}" \
        -H "Content-Type: application/json")
    
    echo "$response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4
}

# Tạo Origin Certificate
create_origin_certificate() {
    local domain="$1"
    local token="$2"
    
    print_info "Đang tạo Origin Certificate cho $domain..."
    
    # Create CSR and private key
    local ssl_dir="$SSL_DIR/$domain"
    mkdir -p "$ssl_dir"
    
    # Request certificate from Cloudflare (15 years = 5475 days)
    local payload=$(cat << EOF
{
    "hostnames": ["$domain", "*.$domain"],
    "requested_validity": 5475,
    "request_type": "origin-rsa",
    "csr": ""
}
EOF
)
    
    local response=$(curl -s -X POST "${CF_API_URL}/certificates" \
        -H "Authorization: Bearer ${token}" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    if echo "$response" | grep -q '"success":true'; then
        # Extract certificate and key
        local cert=$(echo "$response" | grep -o '"certificate":"[^"]*"' | head -1 | cut -d'"' -f4 | sed 's/\\n/\n/g')
        local key=$(echo "$response" | grep -o '"private_key":"[^"]*"' | head -1 | cut -d'"' -f4 | sed 's/\\n/\n/g')
        
        # Save files
        echo -e "$cert" > "$ssl_dir/cert.pem"
        echo -e "$key" > "$ssl_dir/key.pem"
        
        # Set permissions
        chmod 600 "$ssl_dir/key.pem"
        chmod 644 "$ssl_dir/cert.pem"
        
        print_success "Certificate đã được tạo!"
        echo ""
        echo -e "  ${BOLD_CYAN}Certificate:${NC} $ssl_dir/cert.pem"
        echo -e "  ${BOLD_CYAN}Private Key:${NC} $ssl_dir/key.pem"
        echo -e "  ${BOLD_CYAN}Hết hạn:${NC} 15 năm"
        echo ""
        
        return 0
    else
        print_error "Không thể tạo certificate"
        echo "$response" | grep -o '"message":"[^"]*"' | head -1
        return 1
    fi
}

# Cập nhật Nginx config với SSL
update_nginx_ssl() {
    local domain="$1"
    local ssl_dir="$SSL_DIR/$domain"
    local nginx_conf="$NGINX_SITES_AVAILABLE/$domain"
    local template_file="$OZI_DIR/templates/nginx/cloudflare-ssl.conf"
    
    if [[ ! -f "$nginx_conf" ]]; then
        print_error "Nginx config cho $domain không tồn tại"
        return 1
    fi
    
    if [[ ! -f "$template_file" ]]; then
        print_error "Không tìm thấy template: cloudflare-ssl.conf"
        return 1
    fi
    
    print_info "Đang cập nhật Nginx config..."
    
    # Backup original
    cp "$nginx_conf" "${nginx_conf}.backup"
    
    # Lấy thông số từ config cũ
    local root_dir=$(grep -oP 'root \K[^;]+' "$nginx_conf" | head -1 | sed 's|/public||')
    local php_version=$(grep -oP 'php\K[0-9.]+' "$nginx_conf" | head -1)
    [[ -z "$php_version" ]] && php_version="8.3"
    
    # Replace markers in template
    sed "s|{domain}|$domain|g; 
         s|{root}|${root_dir:-$WWW_DIR/$domain}|g;
         s|{php_version}|$php_version|g;
         s|{ssl_dir}|$ssl_dir|g" "$template_file" > "$nginx_conf"
    
    # Test and reload
    if nginx -t 2>/dev/null; then
        systemctl reload nginx
        print_success "Nginx đã được cập nhật với SSL!"
    else
        mv "${nginx_conf}.backup" "$nginx_conf"
        print_error "Nginx config không hợp lệ, đã khôi phục backup"
        return 1
    fi
}

# Interactive SSL installation
install_cloudflare_ssl_interactive() {
    print_header "CÀI SSL CLOUDFLARE (15 NĂM)"
    
    # Check token
    local token=$(get_cloudflare_token)
    
    if [[ -z "$token" ]]; then
        print_warning "Chưa có Cloudflare API Token"
        if confirm "Bạn có muốn cấu hình token ngay không?"; then
            configure_cloudflare_api
            token=$(get_cloudflare_token)
        else
            return 1
        fi
    fi
    
    # Get domain
    echo ""
    local domain=$(read_input "Nhập domain (vd: example.com)")
    
    if [[ -z "$domain" ]]; then
        print_error "Domain không được để trống"
        return 1
    fi
    
    # Create certificate
    if create_origin_certificate "$domain" "$token"; then
        # Ask to update nginx
        if [[ -f "$NGINX_SITES_AVAILABLE/$domain" ]]; then
            if confirm "Cập nhật Nginx config với SSL?"; then
                update_nginx_ssl "$domain"
            fi
        fi
        
        print_success "SSL Cloudflare đã được cài đặt cho $domain!"
        print_info "Lưu ý: Domain phải được proxy qua Cloudflare (orange cloud ON)"
        
        log_info "Installed Cloudflare SSL for: $domain"
    fi
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-}" in
        config)
            configure_cloudflare_api
            ;;
        create)
            token=$(get_cloudflare_token)
            create_origin_certificate "${2:-}" "$token"
            ;;
        *)
            install_cloudflare_ssl_interactive
            ;;
    esac
fi
