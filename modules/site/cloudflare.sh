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
    
    echo ""
    echo "  ${BOLD_WHITE}Để tạo SSL 15 năm, bạn cần Cloudflare API Token với đầy đủ quyền.${NC}"
    echo ""
    echo "  ${BOLD_CYAN}Hướng dẫn lấy token:${NC}"
    echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  1. Truy cập: ${CYAN}https://dash.cloudflare.com/${NC}"
    echo "  2. Click avatar → ${BOLD_WHITE}My Profile${NC} → ${BOLD_WHITE}API Tokens${NC}"
    echo "  3. ${BOLD_WHITE}Create Token${NC} → ${BOLD_WHITE}Create Custom Token${NC}"
    echo ""
    echo "  ${BOLD_YELLOW}Permissions (Quyền cần thiết):${NC}"
    echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  • Zone - ${CYAN}Zone${NC} - ${GREEN}Read${NC}"
    echo "  • Zone - ${CYAN}Zone${NC} - ${GREEN}Edit${NC}"
    echo "  • Zone - ${CYAN}Zone Settings${NC} - ${GREEN}Edit${NC}"
    echo "  • Zone - ${CYAN}SSL and Certificates${NC} - ${GREEN}Edit${NC}"
    echo "  • Zone - ${CYAN}SSL and Certificates${NC} - ${GREEN}Read${NC}"
    echo "  • Zone - ${CYAN}DNS${NC} - ${GREEN}Edit${NC}"
    echo "  • Zone - ${CYAN}Cache Purge${NC} - ${GREEN}Purge${NC}"
    echo ""
    echo "  ${BOLD_YELLOW}Zone Resources:${NC}"
    echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  • Include: ${GREEN}All zones${NC}"
    echo ""
    echo "  ${YELLOW}⚠${NC}  ${BOLD_WHITE}LƯU Ý:${NC} Token phải có đầy đủ các quyền trên!"
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
        # Check permissions
        local status=$(echo "$response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        
        if [[ "$status" == "active" ]]; then
            save_cloudflare_token "$token"
            print_success "Token hợp lệ và đã được lưu!"
            echo ""
            print_info "Token đã được lưu tại: /etc/oziscript/"
            log_info "Configured Cloudflare API Token"
            return 0
        else
            print_error "Token không active hoặc thiếu quyền"
            return 1
        fi
    else
        print_error "Token không hợp lệ hoặc thiếu quyền cần thiết"
        echo ""
        local error_msg=$(echo "$response" | grep -o '"message":"[^"]*"' | head -1 | cut -d'"' -f4)
        if [[ -n "$error_msg" ]]; then
            echo "  ${RED}Lỗi:${NC} $error_msg"
        fi
        echo ""
        print_warning "Vui lòng kiểm tra lại token và đảm bảo đầy đủ quyền!"
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
    
    if [[ -z "$domain" ]] || [[ -z "$token" ]]; then
        print_error "Thiếu domain hoặc token"
        return 1
    fi
    
    print_info "Đang tạo Origin Certificate cho $domain..."
    
    # Get Zone ID first
    local root_domain=$(echo "$domain" | awk -F. '{print $(NF-1)"."$NF}')
    print_info "Đang lấy Zone ID cho $root_domain..."
    
    local zone_response=$(curl -s -X GET "${CF_API_URL}/zones?name=${root_domain}" \
        -H "Authorization: Bearer ${token}" \
        -H "Content-Type: application/json")
    
    local zone_id=$(echo "$zone_response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    if [[ -z "$zone_id" ]]; then
        print_error "Không tìm thấy Zone cho domain $root_domain"
        print_warning "Domain phải được thêm vào Cloudflare trước"
        return 1
    fi
    
    print_info "Zone ID: $zone_id"
    
    # Create SSL directory
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
    
    print_info "Đang yêu cầu certificate..."
    
    # Use zone-specific endpoint for origin certificates
    local response=$(curl -s -X POST "${CF_API_URL}/zones/${zone_id}/origin_tls_client_auth/hostnames/certificates" \
        -H "Authorization: Bearer ${token}" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    # Check if success
    if echo "$response" | grep -q '"success":true'; then
        # Extract certificate and key
        local cert=$(echo "$response" | grep -o '"certificate":"[^"]*"' | head -1 | cut -d'"' -f4 | sed 's/\\n/\n/g')
        local key=$(echo "$response" | grep -o '"private_key":"[^"]*"' | head -1 | cut -d'"' -f4 | sed 's/\\n/\n/g')
        
        if [[ -z "$cert" ]] || [[ -z "$key" ]]; then
            print_error "Không thể trích xuất certificate hoặc key"
            echo "Response: $response" >> /var/log/oziscript/cloudflare_ssl.log
            return 1
        fi
        
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
        echo -e "  ${BOLD_CYAN}Hiệu lực:${NC}    15 năm"
        echo -e "  ${BOLD_CYAN}Hostnames:${NC}   $domain, *.$domain"
        echo ""
        
        log_info "Created Cloudflare Origin Certificate for: $domain"
        return 0
    else
        print_error "Không thể tạo certificate"
        echo ""
        local error_msg=$(echo "$response" | grep -o '"message":"[^"]*"' | head -1 | cut -d'"' -f4)
        local error_code=$(echo "$response" | grep -o '"code":[0-9]*' | head -1 | cut -d':' -f2)
        
        if [[ -n "$error_msg" ]]; then
            echo "  ${RED}Lỗi:${NC} $error_msg ${RED}(Code: $error_code)${NC}"
        fi
        
        # Common error messages
        if echo "$response" | grep -q "authentication"; then
            print_warning "Token không có quyền tạo Origin Certificate"
            print_info "Kiểm tra lại quyền: Zone → SSL and Certificates → Edit"
        elif echo "$response" | grep -q "zone"; then
            print_warning "Không tìm thấy zone hoặc không có quyền truy cập"
        fi
        
        # Log full response for debugging
        echo "$(date): Failed to create certificate for $domain" >> /var/log/oziscript/cloudflare_ssl.log
        echo "$response" >> /var/log/oziscript/cloudflare_ssl.log
        
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
