#!/bin/bash
#================================================================
# Ozi Script - Module: SSH Security
# Mô tả: Bảo mật SSH
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"
source "$OZI_DIR/core/config.sh"

#================================================================
# SSH KEY MANAGEMENT
#================================================================

# Thêm SSH key
add_ssh_key() {
    print_header "THÊM SSH KEY"
    
    echo "  Paste public key của bạn (bắt đầu bằng ssh-rsa hoặc ssh-ed25519):"
    echo ""
    
    local key
    read -r key
    
    if [[ ! "$key" =~ ^ssh-(rsa|ed25519|ecdsa) ]]; then
        print_error "SSH key không hợp lệ"
        return 1
    fi
    
    # Create .ssh directory if not exists
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # Add key
    echo "$key" >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    
    print_success "SSH key đã được thêm!"
    log_info "Added SSH key"
}

# Liệt kê SSH keys
list_ssh_keys() {
    print_header "DANH SÁCH SSH KEYS"
    
    if [[ ! -f ~/.ssh/authorized_keys ]]; then
        print_warning "Chưa có SSH key nào"
        return 0
    fi
    
    echo ""
    local i=1
    while IFS= read -r line; do
        if [[ -n "$line" ]] && [[ ! "$line" =~ ^# ]]; then
            local key_type=$(echo "$line" | awk '{print $1}')
            local key_comment=$(echo "$line" | awk '{print $3}')
            echo -e "  ${BOLD_CYAN}[$i]${NC} $key_type - ${key_comment:-no comment}"
            ((i++))
        fi
    done < ~/.ssh/authorized_keys
    echo ""
}

#================================================================
# SSH HARDENING
#================================================================

# Tắt đăng nhập root
disable_root_login() {
    print_header "TẮT ĐĂNG NHẬP ROOT"
    
    print_warning "Sau khi tắt, bạn chỉ có thể đăng nhập bằng user thường + sudo"
    
    if ! confirm "Bạn có chắc muốn tắt đăng nhập root?"; then
        return 0
    fi
    
    # Check if there's at least one SSH key
    if [[ ! -f ~/.ssh/authorized_keys ]] || [[ ! -s ~/.ssh/authorized_keys ]]; then
        print_error "Chưa có SSH key nào. Vui lòng thêm SSH key trước!"
        return 1
    fi
    
    local sshd_config="/etc/ssh/sshd_config"
    
    # Backup
    cp "$sshd_config" "${sshd_config}.backup"
    
    # Disable root login
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' "$sshd_config"
    
    # Restart SSH
    systemctl restart sshd
    
    print_success "Đăng nhập root đã được tắt"
    log_info "Disabled root SSH login"
}

# Tắt đăng nhập bằng password
disable_password_auth() {
    print_header "TẮT ĐĂNG NHẬP BẰNG PASSWORD"
    
    print_warning "Sau khi tắt, bạn chỉ có thể đăng nhập bằng SSH key"
    
    # Check if there's at least one SSH key
    if [[ ! -f ~/.ssh/authorized_keys ]] || [[ ! -s ~/.ssh/authorized_keys ]]; then
        print_error "Chưa có SSH key nào. Vui lòng thêm SSH key trước!"
        return 1
    fi
    
    if ! confirm "Bạn có chắc muốn tắt đăng nhập bằng password?"; then
        return 0
    fi
    
    local sshd_config="/etc/ssh/sshd_config"
    
    # Backup
    cp "$sshd_config" "${sshd_config}.backup"
    
    # Disable password auth
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$sshd_config"
    sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$sshd_config"
    
    # Restart SSH
    systemctl restart sshd
    
    print_success "Đăng nhập bằng password đã được tắt"
    log_info "Disabled password authentication"
}

# Đổi port SSH
change_ssh_port() {
    print_header "ĐỔI PORT SSH"
    
    local current_port=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')
    [[ -z "$current_port" ]] && current_port="22"
    
    echo -e "  Port hiện tại: ${BOLD_CYAN}${current_port}${NC}"
    echo ""
    
    local new_port=$(read_input "Nhập port mới (1024-65535)")
    
    if [[ ! "$new_port" =~ ^[0-9]+$ ]] || [[ "$new_port" -lt 1024 ]] || [[ "$new_port" -gt 65535 ]]; then
        print_error "Port không hợp lệ (1024-65535)"
        return 1
    fi
    
    local sshd_config="/etc/ssh/sshd_config"
    
    # Backup
    cp "$sshd_config" "${sshd_config}.backup"
    
    # Change port
    if grep -q "^Port" "$sshd_config"; then
        sed -i "s/^Port.*/Port ${new_port}/" "$sshd_config"
    else
        echo "Port ${new_port}" >> "$sshd_config"
    fi
    
    # Update firewall
    if command_exists ufw && ufw status | grep -q "active"; then
        ufw allow ${new_port}/tcp
        ufw delete allow 22/tcp 2>/dev/null || true
    fi
    
    # Test config
    if sshd -t 2>/dev/null; then
        systemctl restart sshd
        print_success "Port SSH đã được đổi thành ${new_port}"
        print_warning "Nhớ dùng: ssh -p ${new_port} user@host"
        log_info "Changed SSH port to: $new_port"
    else
        mv "${sshd_config}.backup" "$sshd_config"
        print_error "Cấu hình không hợp lệ, đã khôi phục backup"
    fi
}

#================================================================
# FULL HARDENING
#================================================================

# Hardening tự động
auto_harden_ssh() {
    print_header "HARDENING SSH TỰ ĐỘNG"
    
    echo "  Các bước sẽ thực hiện:"
    echo "  1. Tắt đăng nhập root"
    echo "  2. Tắt đăng nhập bằng password"
    echo "  3. Cài đặt Fail2ban"
    echo ""
    
    if ! confirm "Tiếp tục?"; then
        return 0
    fi
    
    # Check SSH key first
    if [[ ! -f ~/.ssh/authorized_keys ]] || [[ ! -s ~/.ssh/authorized_keys ]]; then
        print_error "Chưa có SSH key. Vui lòng thêm SSH key trước!"
        return 1
    fi
    
    local sshd_config="/etc/ssh/sshd_config"
    
    # Backup original
    cp "$sshd_config" "${sshd_config}.original"
    
    print_info "Đang cấu hình SSH hardening..."
    
    # Apply all hardening settings
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' "$sshd_config"
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$sshd_config"
    sed -i 's/^#*X11Forwarding.*/X11Forwarding no/' "$sshd_config"
    sed -i 's/^#*MaxAuthTries.*/MaxAuthTries 3/' "$sshd_config"
    sed -i 's/^#*ClientAliveInterval.*/ClientAliveInterval 300/' "$sshd_config"
    sed -i 's/^#*ClientAliveCountMax.*/ClientAliveCountMax 2/' "$sshd_config"
    
    # Test and restart
    if sshd -t 2>/dev/null; then
        systemctl restart sshd
        print_success "SSH đã được hardening"
    else
        mv "${sshd_config}.original" "$sshd_config"
        print_error "Cấu hình không hợp lệ"
        return 1
    fi
    
    # Install fail2ban
    print_info "Đang cài đặt Fail2ban..."
    
    if apt-get install -y -qq fail2ban; then
        systemctl enable fail2ban
        systemctl start fail2ban
        print_success "Fail2ban đã được cài đặt"
    fi
    
    print_success "SSH Hardening hoàn tất!"
    log_info "Applied SSH hardening"
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-}" in
        add-key)
            add_ssh_key
            ;;
        list-keys)
            list_ssh_keys
            ;;
        disable-root)
            disable_root_login
            ;;
        disable-password)
            disable_password_auth
            ;;
        change-port)
            change_ssh_port
            ;;
        harden)
            auto_harden_ssh
            ;;
        *)
            echo "Sử dụng: $0 {add-key|list-keys|disable-root|disable-password|change-port|harden}"
            ;;
    esac
fi
