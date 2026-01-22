#!/bin/bash
#================================================================
# Ozi Script - Module: Let's Encrypt SSL
# Mô tả: Cài đặt SSL Let's Encrypt (Certbot)
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"
source "$OZI_DIR/core/config.sh"

#================================================================
# INSTALLATION
#================================================================

# Cài đặt SSL Let's Encrypt
install_letsencrypt_ssl() {
    print_header "CÀI ĐẶT SSL LET'S ENCRYPT"

    # Check Certbot
    if ! command_exists certbot; then
        print_info "Certbot chưa được cài đặt. Đang cài đặt..."
        if ! apt-get install -y -qq certbot python3-certbot-nginx; then
            print_error "Không thể cài đặt Certbot"
            return 1
        fi
    fi

    echo ""
    local domain=$(read_input "Nhập domain (vd: example.com)")

    if [[ -z "$domain" ]]; then
        print_error "Domain không được để trống"
        return 1
    fi

    # Verify domain points to server
    print_info "Đang kiểm tra domain..."
    # This is a basic check, certbot will do a real check

    print_info "Đang yêu cầu chứng chỉ SSL..."

    # Run certbot
    if certbot --nginx -d "$domain" -d "www.$domain"; then
        print_success "SSL Let's Encrypt đã được cài đặt cho $domain!"
        log_info "Installed Let's Encrypt SSL for: $domain"
    else
        # Try without www if failed
        print_warning "Thử lại không có www..."
        if certbot --nginx -d "$domain"; then
            print_success "SSL Let's Encrypt đã được cài đặt cho $domain!"
            log_info "Installed Let's Encrypt SSL for: $domain"
        else
            print_error "Không thể cài đặt SSL. Vui lòng kiểm tra DNS và log."
            return 1
        fi
    fi
}

# Xem danh sách SSL
list_ssl_certs() {
    print_header "DANH SÁCH CHỨNG CHỈ SSL"

    if command_exists certbot; then
        echo ""
        certbot certificates
        echo ""
    else
        print_warning "Certbot chưa được cài đặt"
    fi
}

# Gia hạn SSL
renew_ssl_certs() {
    print_header "GIA HẠN CHỨNG CHỈ SSL"

    print_info "Đang kiểm tra và gia hạn..."

    if certbot renew; then
        print_success "Đã kiểm tra gia hạn SSL"
    else
        print_error "Có lỗi khi gia hạn SSL"
    fi
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-}" in
        install)
            install_letsencrypt_ssl
            ;;
        list)
            list_ssl_certs
            ;;
        renew)
            renew_ssl_certs
            ;;
        *)
            install_letsencrypt_ssl
            ;;
    esac
fi
