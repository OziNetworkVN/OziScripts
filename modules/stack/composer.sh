#!/bin/bash
#================================================================
# Ozi Script - Module: Composer
# Mô tả: Cài đặt Composer
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"

#================================================================
# INSTALLATION
#================================================================

# Cài đặt Composer
install_composer() {
    print_header "CÀI ĐẶT COMPOSER"
    
    if command_exists composer; then
        print_warning "Composer đã được cài đặt"
        print_info "Version: $(composer --version 2>/dev/null | awk '{print $3}')"
        
        if confirm "Bạn có muốn cập nhật Composer không?"; then
            composer self-update
            print_success "Composer đã được cập nhật"
        fi
        return 0
    fi
    
    # Check PHP
    if ! command_exists php; then
        print_error "PHP chưa được cài đặt. Vui lòng cài PHP trước."
        return 1
    fi
    
    print_info "Đang cài đặt Composer..."
    
    # Download installer
    local expected_sig="$(curl -fsSL https://composer.github.io/installer.sig)"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    local actual_sig="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
    
    if [[ "$expected_sig" != "$actual_sig" ]]; then
        rm composer-setup.php
        print_error "Chữ ký không hợp lệ. Cài đặt thất bại."
        return 1
    fi
    
    # Install
    php composer-setup.php --quiet --install-dir=/usr/local/bin --filename=composer
    rm composer-setup.php
    
    # Verify
    if command_exists composer; then
        print_success "Composer đã được cài đặt!"
        print_info "Version: $(composer --version 2>/dev/null | awk '{print $3}')"
        log_info "Installed Composer"
    else
        print_error "Cài đặt Composer thất bại"
        return 1
    fi
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    install_composer
fi
