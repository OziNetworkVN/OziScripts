#!/bin/bash
#================================================================
# Ozi Script - Module: Swap Management
# Mô tả: Quản lý Swap
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"

#================================================================
# SWAP MANAGEMENT
#================================================================

# Hiển thị thông tin swap
show_swap_info() {
    print_header "THÔNG TIN SWAP"
    
    local swap_total=$(free -m | awk 'NR==3{print $2}')
    local swap_used=$(free -m | awk 'NR==3{print $3}')
    local swap_free=$(free -m | awk 'NR==3{print $4}')
    
    echo ""
    if [[ "$swap_total" -eq 0 ]]; then
        print_warning "Chưa có Swap"
    else
        echo -e "  ${BOLD_CYAN}▸ Swap Total:${NC}  ${swap_total} MB"
        echo -e "  ${BOLD_CYAN}▸ Swap Used:${NC}   ${swap_used} MB"
        echo -e "  ${BOLD_CYAN}▸ Swap Free:${NC}   ${swap_free} MB"
        echo ""
        
        # Show swap file location
        if [[ -f /swapfile ]]; then
            local swapfile_size=$(du -h /swapfile | cut -f1)
            echo -e "  ${BOLD_CYAN}▸ Swapfile:${NC}    /swapfile ($swapfile_size)"
        fi
    fi
    echo ""
    
    # Show swappiness
    local swappiness=$(cat /proc/sys/vm/swappiness)
    echo -e "  ${BOLD_CYAN}▸ Swappiness:${NC}  $swappiness"
    echo ""
}

# Tạo swap
create_swap() {
    local size="${1:-2}"  # Default 2GB
    
    print_header "TẠO SWAP"
    
    # Check existing swap
    if [[ -f /swapfile ]]; then
        print_warning "Swapfile đã tồn tại"
        if ! confirm "Bạn có muốn tạo lại swap không?"; then
            return 0
        fi
        # Remove old swap
        swapoff /swapfile 2>/dev/null
        rm -f /swapfile
    fi
    
    print_info "Đang tạo swapfile ${size}GB..."
    
    # Create swapfile
    fallocate -l ${size}G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    
    # Add to fstab if not exists
    if ! grep -q "/swapfile" /etc/fstab; then
        echo "/swapfile none swap sw 0 0" >> /etc/fstab
    fi
    
    # Set swappiness
    sysctl vm.swappiness=10
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    
    print_success "Swap ${size}GB đã được tạo!"
    log_info "Created ${size}GB swap"
}

# Xoá swap
remove_swap() {
    print_header "XOÁ SWAP"
    
    if [[ ! -f /swapfile ]]; then
        print_warning "Không có swapfile để xoá"
        return 0
    fi
    
    if ! confirm "Bạn có chắc muốn xoá swap?"; then
        return 0
    fi
    
    swapoff /swapfile
    rm -f /swapfile
    sed -i '/\/swapfile/d' /etc/fstab
    
    print_success "Swap đã được xoá"
    log_info "Removed swap"
}

# Interactive swap management
manage_swap_interactive() {
    show_swap_info
    
    echo "  Tuỳ chọn:"
    echo ""
    print_menu_item "1" "Tạo Swap mới"
    print_menu_item "2" "Xoá Swap"
    print_menu_item "3" "Đổi Swappiness"
    print_menu_back
    echo ""
    
    read -p "$(echo -e "${BOLD_WHITE}Nhập lựa chọn [0-3]: ${NC}")" choice
    
    case "$choice" in
        1)
            local size=$(read_input "Nhập kích thước swap (GB)" "2")
            create_swap "$size"
            ;;
        2)
            remove_swap
            ;;
        3)
            local new_swappiness=$(read_input "Nhập swappiness (0-100)" "10")
            sysctl vm.swappiness=$new_swappiness
            sed -i "s/vm.swappiness=.*/vm.swappiness=$new_swappiness/" /etc/sysctl.conf
            print_success "Swappiness đã được đổi thành $new_swappiness"
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
        create)
            create_swap "${2:-2}"
            ;;
        remove)
            remove_swap
            ;;
        info)
            show_swap_info
            ;;
        *)
            manage_swap_interactive
            ;;
    esac
fi
