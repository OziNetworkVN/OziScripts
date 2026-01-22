#!/bin/bash
#================================================================
# Ozi Script - Module: Certbot
# Mô tả: Cài đặt Certbot (Let's Encrypt Client)
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"

#================================================================
# INSTALLATION
#================================================================

# Cài đặt Certbot
install_certbot() {
    print_header "CÀI ĐẶT CERTBOT"

    if command_exists certbot; then
        print_warning "Certbot đã được cài đặt"
        print_info "Version: $(certbot --version 2>&1)"
        return 0
    fi

    print_info "Đang cài đặt Certbot..."

    if apt-get install -y -qq certbot python3-certbot-nginx; then
        print_success "Certbot đã được cài đặt"
        log_info "Installed Certbot"
    else
        print_error "Không thể cài đặt Certbot"
        return 1
    fi
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    install_certbot
fi
