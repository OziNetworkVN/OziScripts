#!/bin/bash
#================================================================
# Ozi Script - Module: Nginx
# Mô tả: Cài đặt và quản lý Nginx
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"
source "$OZI_DIR/core/config.sh"

#================================================================
# INSTALLATION
#================================================================

# Cài đặt Nginx
install_nginx() {
    print_header "CÀI ĐẶT NGINX"
    
    if is_installed "nginx"; then
        print_warning "Nginx đã được cài đặt"
        
        if is_service_running "nginx"; then
            print_success "Nginx đang chạy"
        else
            print_info "Đang khởi động Nginx..."
            systemctl start nginx
            print_success "Nginx đã được khởi động"
        fi
        return 0
    fi
    
    print_info "Đang cài đặt Nginx..."
    
    apt-get update -qq
    
    if apt-get install -y -qq nginx; then
        print_success "Nginx đã được cài đặt"
        log_info "Installed Nginx"
    else
        print_error "Không thể cài đặt Nginx"
        log_error "Failed to install Nginx"
        return 1
    fi
    
    # Enable and start
    systemctl enable nginx
    systemctl start nginx
    
    # Optimize nginx.conf
    optimize_nginx
    
    print_success "Nginx đã sẵn sàng!"
}

# Tối ưu cấu hình Nginx
optimize_nginx() {
    local nginx_conf="/etc/nginx/nginx.conf"
    
    if [[ ! -f "$nginx_conf" ]]; then
        return 0
    fi
    
    print_info "Đang tối ưu cấu hình Nginx..."
    
    # Backup
    cp "$nginx_conf" "${nginx_conf}.backup"
    
    # Set worker processes
    sed -i "s/worker_processes .*/worker_processes auto;/" "$nginx_conf"
    
    # Set worker connections
    sed -i "s/worker_connections .*/worker_connections 2048;/" "$nginx_conf"
    
    # Enable gzip (uncomment)
    sed -i 's/# gzip/gzip/' "$nginx_conf"
    
    # Create snippets directory
    mkdir -p /etc/nginx/snippets
    
    # Create common SSL snippet
    cat > /etc/nginx/snippets/ssl-params.conf << 'EOF'
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers off;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 1d;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;
EOF

    # Create security headers snippet
    cat > /etc/nginx/snippets/security-headers.conf << 'EOF'
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
EOF

    # Test config
    if nginx -t 2>/dev/null; then
        systemctl reload nginx
        print_success "Đã tối ưu cấu hình Nginx"
    else
        # Restore backup if test fails
        mv "${nginx_conf}.backup" "$nginx_conf"
        print_error "Cấu hình không hợp lệ, đã khôi phục backup"
    fi
}

#================================================================
# STATUS & MANAGEMENT
#================================================================

# Xem trạng thái Nginx
show_nginx_status() {
    print_header "TRẠNG THÁI NGINX"
    
    if ! is_installed "nginx"; then
        print_error "Nginx chưa được cài đặt"
        return 1
    fi
    
    echo ""
    systemctl status nginx --no-pager
    echo ""
}

# Khởi động lại Nginx
restart_nginx() {
    if ! is_installed "nginx"; then
        print_error "Nginx chưa được cài đặt"
        return 1
    fi
    
    print_info "Đang khởi động lại Nginx..."
    
    if systemctl restart nginx; then
        print_success "Nginx đã được khởi động lại"
    else
        print_error "Không thể khởi động lại Nginx"
        return 1
    fi
}

# Test cấu hình Nginx
test_nginx_config() {
    print_header "TEST CẤU HÌNH NGINX"
    
    if ! is_installed "nginx"; then
        print_error "Nginx chưa được cài đặt"
        return 1
    fi
    
    echo ""
    if nginx -t; then
        print_success "Cấu hình Nginx hợp lệ"
    else
        print_error "Cấu hình Nginx có lỗi"
    fi
    echo ""
}

# Reload Nginx
reload_nginx() {
    if nginx -t 2>/dev/null; then
        systemctl reload nginx
        print_success "Nginx đã được reload"
    else
        print_error "Cấu hình không hợp lệ, không thể reload"
        return 1
    fi
}

# Xem logs Nginx
view_nginx_logs() {
    local log_type="${1:-error}"
    local log_file="/var/log/nginx/${log_type}.log"

    if [[ ! -f "$log_file" ]]; then
        print_error "Không tìm thấy file log: $log_file"
        return 1
    fi

    print_header "NGINX ${log_type^^} LOGS (Ctrl+C để thoát)"
    echo ""
    tail -f "$log_file"
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-install}" in
        install)
            install_nginx
            ;;
        status)
            show_nginx_status
            ;;
        restart)
            restart_nginx
            ;;
        reload)
            reload_nginx
            ;;
        test)
            test_nginx_config
            ;;
        logs)
            view_nginx_logs "${2:-error}"
            ;;
        *)
            echo "Sử dụng: $0 {install|status|restart|reload|test|logs}"
            ;;
    esac
fi
