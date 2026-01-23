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
    echo -e "  ${BOLD_WHITE}Để tạo SSL 15 năm, bạn cần Cloudflare API Token với đầy đủ quyền.${NC}"
    echo ""
    echo -e "  ${BOLD_CYAN}Hướng dẫn lấy token:${NC}"
    echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  1. Truy cập: ${CYAN}https://dash.cloudflare.com/${NC}"
    echo -e "  2. Click avatar → ${BOLD_WHITE}My Profile${NC} → ${BOLD_WHITE}API Tokens${NC}"
    echo -e "  3. ${BOLD_WHITE}Create Token${NC} → ${BOLD_WHITE}Create Custom Token${NC}"
    echo ""
    echo -e "  ${BOLD_YELLOW}Permissions (Quyền cần thiết):${NC}"
    echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  • Zone - ${CYAN}Zone${NC} - ${GREEN}Read${NC}"
    echo -e "  • Zone - ${CYAN}Zone${NC} - ${GREEN}Edit${NC}"
    echo -e "  • Zone - ${CYAN}Zone Settings${NC} - ${GREEN}Edit${NC}"
    echo -e "  • Zone - ${CYAN}SSL and Certificates${NC} - ${GREEN}Edit${NC}"
    echo -e "  • Zone - ${CYAN}SSL and Certificates${NC} - ${GREEN}Read${NC}"
    echo -e "  • Zone - ${CYAN}DNS${NC} - ${GREEN}Edit${NC}"
    echo -e "  • Zone - ${CYAN}Cache Purge${NC} - ${GREEN}Purge${NC}"
    echo ""
    echo -e "  ${BOLD_YELLOW}Zone Resources:${NC}"
    echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  • Include: ${GREEN}All zones${NC}"
    echo ""
    echo -e "  ${YELLOW}⚠${NC}  ${BOLD_WHITE}LƯU Ý:${NC} Token phải có đầy đủ các quyền trên!"
    echo ""
    
    local token=$(read_secret "Nhập API Token")
    
    # Trim whitespace and newlines
    token=$(echo "$token" | tr -d '[:space:]')
    
    if [[ -z "$token" ]]; then
        print_error "Token không được để trống"
        return 1
    fi
    
    # Validate token format (basic check)
    if [[ ! "$token" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "Token có ký tự không hợp lệ"
        echo ""
        echo -e "  ${YELLOW}Token chỉ được chứa: a-z, A-Z, 0-9, _, -${NC}"
        return 1
    fi
    
    # Check internet connectivity first
    print_info "Kiểm tra kết nối internet..."
    if ! curl -s --connect-timeout 5 https://api.cloudflare.com/cdn-cgi/trace >/dev/null 2>&1; then
        print_error "Không thể kết nối đến Cloudflare API"
        echo ""
        echo -e "  ${RED}Vui lòng kiểm tra:${NC}"
        echo -e "  1. Kết nối internet của VPS"
        echo -e "  2. DNS resolver (cat /etc/resolv.conf)"
        echo -e "  3. Firewall không block HTTPS"
        echo ""
        echo -e "  ${YELLOW}Test thủ công:${NC}"
        echo -e "  curl -v https://api.cloudflare.com/cdn-cgi/trace"
        return 1
    fi
    
    # Verify token
    print_info "Đang xác thực token..."
    
    # Debug: Log token length (not the actual token for security)
    mkdir -p /var/log/oziscript 2>/dev/null
    echo "" >> /var/log/oziscript/cloudflare_api.log 2>/dev/null
    echo "$(date): Token verification attempt" >> /var/log/oziscript/cloudflare_api.log 2>/dev/null
    echo "Token length: ${#token}" >> /var/log/oziscript/cloudflare_api.log 2>/dev/null
    echo "Token first 10 chars: ${token:0:10}..." >> /var/log/oziscript/cloudflare_api.log 2>/dev/null
    
    local response=$(curl -s -X GET "${CF_API_URL}/user/tokens/verify" \
        -H "Authorization: Bearer ${token}" \
        -H "Content-Type: application/json" \
        -w "\nHTTP_STATUS:%{http_code}")
    
    local http_code=$(echo "$response" | grep "HTTP_STATUS:" | cut -d: -f2)
    local body=$(echo "$response" | sed '/HTTP_STATUS:/d')
    
    # Debug output
    echo "HTTP Code: $http_code" >> /var/log/oziscript/cloudflare_api.log 2>/dev/null
    echo "Response: $body" >> /var/log/oziscript/cloudflare_api.log 2>/dev/null
    
    if [[ -z "$http_code" || "$http_code" == "000" ]]; then
        print_error "Không nhận được response từ API (HTTP $http_code)"
        echo ""
        echo -e "  ${RED}Nguyên nhân có thể:${NC}"
        echo -e "  1. Timeout kết nối"
        echo -e "  2. SSL certificate error"
        echo -e "  3. Proxy/firewall block"
        echo ""
        echo -e "  ${YELLOW}Debug:${NC}"
        echo -e "  curl -v ${CF_API_URL}/user/tokens/verify"
        return 1
    fi
    
    if [[ "$http_code" != "200" ]]; then
        print_error "Kết nối API thất bại (HTTP $http_code)"
        echo ""
        echo -e "  ${RED}Vui lòng kiểm tra:${NC}"
        echo -e "  1. Kết nối internet"
        echo -e "  2. Token đúng định dạng (không có khoảng trắng)"
        echo -e "  3. Token chưa bị xóa trên Cloudflare"
        echo ""
        echo -e "  ${YELLOW}Log:${NC} /var/log/oziscript/cloudflare_api.log"
        return 1
    fi
    
    if echo "$body" | grep -q '"success":true'; then
        local status=$(echo "$body" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        
        if [[ "$status" == "active" ]]; then
            save_cloudflare_token "$token"
            print_success "Token hợp lệ và đã được lưu!"
            echo ""
            print_info "Token đã được lưu tại: /etc/oziscript/cloudflare.conf"
            echo ""
            print_info "Bạn có thể tiếp tục tạo Origin Certificate cho domain."
            log_info "Configured Cloudflare API Token"
            return 0
        else
            print_error "Token không active: $status"
            echo ""
            echo -e "  ${YELLOW}Status:${NC} $status"
            return 1
        fi
    else
        print_error "Token không hợp lệ hoặc thiếu quyền cần thiết"
        echo ""
        local error_msg=$(echo "$body" | grep -o '"message":"[^"]*"' | head -1 | cut -d'"' -f4)
        local error_code=$(echo "$body" | grep -o '"code":[0-9]*' | head -1 | cut -d: -f2)
        
        if [[ -n "$error_msg" ]]; then
            echo -e "  ${RED}Lỗi:${NC} $error_msg (Code: $error_code)"
        fi
        
        echo ""
        echo -e "  ${YELLOW}Gợi ý khắc phục:${NC}"
        echo -e "  1. Kiểm tra lại token từ Cloudflare Dashboard"
        echo -e "  2. Đảm bảo token có đầy đủ 7 quyền đã liệt kê"
        echo -e "  3. Token chưa hết hạn (check TTL)"
        echo -e "  4. Zone Resources = 'All zones'"
        echo ""
        echo -e "  ${CYAN}Log chi tiết:${NC} /var/log/oziscript/cloudflare_api.log"
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
    local csr=""
    
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
        
        csr=$(cat)
        
        # Validate inputs
        if [[ ! "$private_key" =~ "BEGIN" ]] || [[ ! "$csr" =~ "BEGIN" ]]; then
            print_error "Private Key hoặc CSR không hợp lệ"
            return 1
        fi
        
        # Save private key first
        echo "$private_key" > "$ssl_dir/key.pem"
        chmod 600 "$ssl_dir/key.pem"
        
    else
        # Auto-generate private key and CSR
        print_info "Đang tạo Private Key và CSR..."
        
        # Generate private key (2048-bit RSA)
        openssl genrsa -out "$ssl_dir/key.pem" 2048 2>/dev/null
        chmod 600 "$ssl_dir/key.pem"
        
        # Generate CSR
        openssl req -new -key "$ssl_dir/key.pem" -out "$ssl_dir/csr.pem" \
            -subj "/C=VN/ST=HCM/L=HoChiMinh/O=OziNetwork/CN=$domain" 2>/dev/null
        
        # Read CSR content
        csr=$(cat "$ssl_dir/csr.pem")
        
        print_success "Private Key và CSR đã được tạo"
    fi
    
    # Escape newlines for JSON
    csr=$(echo "$csr" | sed ':a;N;$!ba;s/\n/\\n/g')
    
    # Build payload with CSR
    payload=$(cat << EOF
{
    "hostnames": ["$domain", "*.${domain}"],
    "requested_validity": 5475,
    "request_type": "origin-rsa",
    "csr": "$csr"
}
EOF
)
    
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
        # Extract certificate from response
        local cert=$(echo "$response" | grep -o '"certificate":"[^"]*"' | head -1 | cut -d'"' -f4 | sed 's/\\n/\n/g')
        
        if [[ -z "$cert" ]]; then
            print_error "Không thể trích xuất certificate từ response"
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
