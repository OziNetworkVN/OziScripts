#!/bin/bash
#================================================================
# Ozi Script - Module: Supervisor
# Mô tả: Cài đặt và quản lý Supervisor
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"

#================================================================
# INSTALLATION
#================================================================

# Cài đặt Supervisor
install_supervisor() {
    print_header "CÀI ĐẶT SUPERVISOR"
    
    if is_installed "supervisor"; then
        print_warning "Supervisor đã được cài đặt"
        
        if is_service_running "supervisor"; then
            print_success "Supervisor đang chạy"
        else
            systemctl start supervisor
            print_success "Supervisor đã được khởi động"
        fi
        return 0
    fi
    
    print_info "Đang cài đặt Supervisor..."
    
    if apt-get install -y -qq supervisor; then
        print_success "Supervisor đã được cài đặt"
        log_info "Installed Supervisor"
    else
        print_error "Không thể cài đặt Supervisor"
        return 1
    fi
    
    # Enable and start
    systemctl enable supervisor
    systemctl start supervisor
    
    # Create log directory
    mkdir -p /var/log/supervisor
    
    print_success "Supervisor đã sẵn sàng!"
}

# Xem trạng thái
show_supervisor_status() {
    print_header "TRẠNG THÁI SUPERVISOR"
    
    if ! is_installed "supervisor"; then
        print_error "Supervisor chưa được cài đặt"
        return 1
    fi
    
    echo ""
    supervisorctl status
    echo ""
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-install}" in
        install)
            install_supervisor
            ;;
        status)
            show_supervisor_status
            ;;
        restart)
            supervisorctl restart all
            ;;
        *)
            echo "Sử dụng: $0 {install|status|restart}"
            ;;
    esac
fi
