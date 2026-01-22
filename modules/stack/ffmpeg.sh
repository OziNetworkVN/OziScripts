#!/bin/bash
#================================================================
# Ozi Script - Module: FFmpeg
# Mô tả: Cài đặt FFmpeg
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"

#================================================================
# INSTALLATION
#================================================================

# Cài đặt FFmpeg
install_ffmpeg() {
    print_header "CÀI ĐẶT FFMPEG"

    if command_exists ffmpeg; then
        print_warning "FFmpeg đã được cài đặt"
        print_info "Version: $(ffmpeg -version | head -n 1)"
        return 0
    fi

    print_info "Đang cài đặt FFmpeg..."

    if apt-get install -y -qq ffmpeg; then
        print_success "FFmpeg đã được cài đặt"
        log_info "Installed FFmpeg"
    else
        print_error "Không thể cài đặt FFmpeg"
        return 1
    fi
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    install_ffmpeg
fi
