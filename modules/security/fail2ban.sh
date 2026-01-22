#!/bin/bash
#================================================================
# Ozi Script - Module: Fail2ban
# Mô tả: Cài đặt và quản lý Fail2ban
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"

#================================================================
# INSTALLATION
#================================================================

# Cài đặt Fail2ban
install_fail2ban() {
    print_header "CÀI ĐẶT FAIL2BAN"
    
    if is_installed "fail2ban"; then
        print_warning "Fail2ban đã được cài đặt"
        if is_service_running "fail2ban"; then
            print_success "Fail2ban đang chạy"
        else
            systemctl start fail2ban
            print_success "Fail2ban đã được khởi động"
        fi
        return 0
    fi
    
    print_info "Đang cài đặt Fail2ban..."
    
    if apt-get install -y -qq fail2ban; then
        print_success "Fail2ban đã được cài đặt"
    else
        print_error "Không thể cài đặt Fail2ban"
        return 1
    fi
    
    # Create local config
    configure_fail2ban
    
    # Enable and start
    systemctl enable fail2ban
    systemctl start fail2ban
    
    print_success "Fail2ban đã sẵn sàng!"
    log_info "Installed Fail2ban"
}

# Cấu hình Fail2ban
configure_fail2ban() {
    print_info "Đang cấu hình Fail2ban..."
    
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 24h

[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 5

[nginx-botsearch]
enabled = true
port = http,https
filter = nginx-botsearch
logpath = /var/log/nginx/access.log
maxretry = 2
EOF
    
    print_success "Fail2ban đã được cấu hình"
}

# Xem trạng thái
show_fail2ban_status() {
    print_header "TRẠNG THÁI FAIL2BAN"
    
    if ! is_installed "fail2ban"; then
        print_error "Fail2ban chưa được cài đặt"
        return 1
    fi
    
    echo ""
    fail2ban-client status
    echo ""
    
    print_subheader "SSH Jail Status"
    fail2ban-client status sshd 2>/dev/null || echo "  SSH jail chưa được kích hoạt"
    echo ""
}

# Unban IP
unban_ip() {
    local ip="$1"
    local jail="${2:-sshd}"
    
    if [[ -z "$ip" ]]; then
        print_error "Vui lòng nhập IP"
        return 1
    fi
    
    fail2ban-client set "$jail" unbanip "$ip"
    print_success "Đã unban IP: $ip (jail: $jail)"
}

# Liệt kê IP bị ban
list_banned_ips() {
    print_header "DANH SÁCH IP BỊ BAN"
    
    echo ""
    for jail in $(fail2ban-client status | grep "Jail list" | sed 's/.*:\s*//;s/,/ /g'); do
        echo -e "  ${BOLD_CYAN}[$jail]${NC}"
        local banned=$(fail2ban-client status "$jail" | grep "Banned IP" | sed 's/.*:\s*//')
        if [[ -n "$banned" ]]; then
            echo "    $banned"
        else
            echo "    (không có)"
        fi
        echo ""
    done
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-install}" in
        install)
            install_fail2ban
            ;;
        status)
            show_fail2ban_status
            ;;
        banned)
            list_banned_ips
            ;;
        unban)
            unban_ip "${2:-}" "${3:-sshd}"
            ;;
        restart)
            systemctl restart fail2ban
            print_success "Fail2ban đã được khởi động lại"
            ;;
        *)
            echo "Sử dụng: $0 {install|status|banned|unban|restart}"
            ;;
    esac
fi
