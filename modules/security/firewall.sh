#!/bin/bash
#================================================================
# Ozi Script - Module: Firewall (UFW)
# Mô tả: Quản lý firewall UFW
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"

#================================================================
# INSTALLATION
#================================================================

# Cài đặt và cấu hình UFW
install_firewall() {
    print_header "CÀI ĐẶT FIREWALL (UFW)"
    
    if ! is_installed "ufw"; then
        print_info "Đang cài đặt UFW..."
        apt-get install -y -qq ufw
    fi
    
    print_info "Đang cấu hình firewall..."
    
    # Reset to default
    ufw --force reset > /dev/null 2>&1
    
    # Default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow essential services
    ufw allow ssh
    ufw allow 'Nginx Full'
    
    # Allow common ports
    ufw allow 22/tcp    # SSH
    ufw allow 80/tcp    # HTTP
    ufw allow 443/tcp   # HTTPS
    
    # Enable UFW
    ufw --force enable
    
    print_success "Firewall đã được cấu hình!"
    echo ""
    show_firewall_status
    
    log_info "Configured UFW firewall"
}

# Hiển thị trạng thái
show_firewall_status() {
    print_header "TRẠNG THÁI FIREWALL"
    
    if ! is_installed "ufw"; then
        print_error "UFW chưa được cài đặt"
        return 1
    fi
    
    echo ""
    ufw status verbose
    echo ""
}

#================================================================
# PORT MANAGEMENT
#================================================================

# Mở port
open_port() {
    local port="$1"
    local protocol="${2:-tcp}"
    
    if [[ -z "$port" ]]; then
        print_error "Vui lòng nhập số port"
        return 1
    fi
    
    ufw allow ${port}/${protocol}
    print_success "Đã mở port ${port}/${protocol}"
    log_info "Opened port: ${port}/${protocol}"
}

# Đóng port
close_port() {
    local port="$1"
    local protocol="${2:-tcp}"
    
    if [[ -z "$port" ]]; then
        print_error "Vui lòng nhập số port"
        return 1
    fi
    
    ufw delete allow ${port}/${protocol}
    print_success "Đã đóng port ${port}/${protocol}"
    log_info "Closed port: ${port}/${protocol}"
}

# Interactive port management
manage_ports_interactive() {
    print_header "QUẢN LÝ PORT"
    
    echo ""
    print_menu_item "1" "Mở port"
    print_menu_item "2" "Đóng port"
    print_menu_item "3" "Xem danh sách port đang mở"
    print_menu_back
    echo ""
    
    read -p "$(echo -e "${BOLD_WHITE}Nhập lựa chọn [0-3]: ${NC}")" choice
    
    case "$choice" in
        1)
            local port=$(read_input "Nhập port muốn mở")
            open_port "$port"
            ;;
        2)
            local port=$(read_input "Nhập port muốn đóng")
            close_port "$port"
            ;;
        3)
            show_firewall_status
            ;;
        0)
            return 0
            ;;
    esac
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-}" in
        install)
            install_firewall
            ;;
        status)
            show_firewall_status
            ;;
        open)
            open_port "${2:-}" "${3:-tcp}"
            ;;
        close)
            close_port "${2:-}" "${3:-tcp}"
            ;;
        *)
            manage_ports_interactive
            ;;
    esac
fi
