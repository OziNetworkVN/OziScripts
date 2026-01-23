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
    
    # Create SSL directory
    local ssl_dir="$SSL_DIR/$domain"
    mkdir -p "$ssl_dir"
    
    # Ask for custom key/CSR or auto-generate
    echo ""
    echo "  ${BOLD_WHITE}Chọn phương thức:${NC}"
    echo "  ${CYAN}[1]${NC} Tự động tạo (Cloudflare generate)"
    echo "  ${CYAN}[2]${NC} Sử dụng Private Key và CSR có sẵn"
    echo ""
    
    local method
    read -p "$(echo -e "${BOLD_WHITE}Chọn phương thức [1-2]: ${NC}")" method
    
    local payload
    local private_key=""
    
    if [[ "$method" == "2" ]]; then
        # Custom key and CSR
        echo ""
        print_info "Nhập Private Key (paste toàn bộ, kết thúc bằng Ctrl+D):"
        echo "  Bao gồm cả -----BEGIN PRIVATE KEY----- và -----END PRIVATE KEY-----"
        echo ""
        
        private_key=$(cat)
        
        echo ""
        print_info "Nhập Certificate Signing Request (CSR):"
        echo "  Bao gồm cả -----BEGIN CERTIFICATE REQUEST----- và -----END CERTIFICATE REQUEST-----"
        echo ""
        
        local csr=$(cat)
        
        # Validate inputs
        if [[ ! "$private_key" =~ "BEGIN" ]] || [[ ! "$csr" =~ "BEGIN" ]]; then
            print_error "Private Key hoặc CSR không hợp lệ"
            return 1
        fi
        
        # Save private key first
        echo "$private_key" > "$ssl_dir/key.pem"
        chmod 600 "$ssl_dir/key.pem"
        
        # Escape newlines for JSON
        csr=$(echo "$csr" | sed ':a;N;$!ba;s/\n/\\n/g')
        
        payload=$(cat << EOF
{
    "hostnames": ["$domain", "*.${domain}"],
    "requested_validity": 5475,
    "request_type": "origin-rsa",
    "csr": "$csr"
}
EOF
)
    else
        # Auto-generate
        payload=$(cat << EOF
{
    "hostnames": ["$domain", "*.${domain}"],
    "requested_validity": 5475,
    "request_type": "origin-rsa"
}
EOF
)
    fi
    
    print_info "Đang yêu cầu certificate từ Cloudflare..."
    
    # Use correct Origin CA Certificates endpoint (no zone_id needed)
    local response=$(curl -s -X POST "${CF_API_URL}/certificates" \
        -H "Authorization: Bearer ${token}" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    # Debug: Log response
    echo "$(date): Certificate request for $domain" >> /var/log/oziscript/cloudflare_ssl.log
    echo "Response: $response" >> /var/log/oziscript/cloudflare_ssl.log
    
    # Check if success
    if echo "$response" | grep -q '"success":true'; then
        # Extract certificate
        local cert=$(echo "$response" | grep -o '"certificate":"[^"]*"' | head -1 | cut -d'"' -f4 | sed 's/\\n/\n/g')
        
        # If auto-generate, also extract private key
        if [[ "$method" != "2" ]]; then
            private_key=$(echo "$response" | grep -o '"private_key":"[^"]*"' | head -1 | cut -d'"' -f4 | sed 's/\\n/\n/g')
            
            if [[ -z "$private_key" ]]; then
                print_error "Không thể trích xuất private key từ response"
                return 1
            fi
            
            # Save private key
            echo -e "$private_key" > "$ssl_dir/key.pem"
            chmod 600 "$ssl_dir/key.pem"
        fi
        
        if [[ -z "$cert" ]]; then
            print_error "Không thể trích xuất certificate"
            return 1
        fi
        
        # Save certificate
        echo -e "$cert" > "$ssl_dir/cert.pem"
        chmod 644 "$ssl_dir/cert.pem"
        
        # Get certificate ID and expiry
        local cert_id=$(echo "$response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
        local expires_on=$(echo "$response" | grep -o '"expires_on":"[^"]*"' | head -1 | cut -d'"' -f4)
        
        print_success "Certificate đã được tạo thành công!"
        echo ""
        echo -e "  ${BOLD_CYAN}Certificate:${NC} $ssl_dir/cert.pem"
        echo -e "  ${BOLD_CYAN}Private Key:${NC} $ssl_dir/key.pem"
        echo -e "  ${BOLD_CYAN}Hiệu lực:${NC}    15 năm"
        echo -e "  ${BOLD_CYAN}Hostnames:${NC}   $domain, *.${domain}"
        [[ -n "$cert_id" ]] && echo -e "  ${BOLD_CYAN}Cert ID:${NC}     $cert_id"
        [[ -n "$expires_on" ]] && echo -e "  ${BOLD_CYAN}Hết hạn:${NC}     $expires_on"
        echo ""
        
        log_info "Created Cloudflare Origin Certificate for: $domain"
        return 0
    else
        print_error "Không thể tạo certificate"
        echo ""
        
        # Parse error details
        local error_msg=$(echo "$response" | grep -o '"message":"[^"]*"' | head -1 | cut -d'"' -f4)
        local error_code=$(echo "$response" | grep -o '"code":[0-9]*' | head -1 | cut -d':' -f2)
        
        if [[ -n "$error_msg" ]]; then
            echo "  ${RED}Lỗi:${NC} $error_msg"
            [[ -n "$error_code" ]] && echo "  ${RED}Code:${NC} $error_code"
        else
            echo "  ${RED}Response:${NC} $response"
        fi
        
        echo ""
        
        # Common error troubleshooting
        if echo "$response" | grep -qi "authentication\|token"; then
            print_warning "Lỗi xác thực token"
            echo ""
            echo "  Kiểm tra:"
            echo "  • Token có đúng không?"
            echo "  • Token có quyền: SSL and Certificates → Edit?"
            echo "  • Token đã active chưa?"
        elif echo "$response" | grep -qi "invalid\|csr"; then
            print_warning "CSR không hợp lệ"
            echo "  Đảm bảo CSR đúng định dạng PEM"
        fi
        
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
