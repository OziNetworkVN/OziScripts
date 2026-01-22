#!/bin/bash
#================================================================
# Ozi Script - Uninstaller
# Mô tả: Gỡ cài đặt Ozi Script
# Sử dụng: sudo bash uninstall.sh
# Phiên bản: 1.0.0
#================================================================

set -euo pipefail

INSTALL_DIR="/opt/oziscript"
BIN_LINK="/usr/local/bin/ozi"
CONFIG_DIR="/etc/oziscript"
LOG_DIR="/var/log/oziscript"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

# Check root
if [[ $EUID -ne 0 ]]; then
    print_error "Script này cần quyền root. Vui lòng chạy với sudo."
    exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "                    GỠ CÀI ĐẶT OZI SCRIPT"
echo "═══════════════════════════════════════════════════════════════"
echo ""

print_warning "Thao tác này sẽ xoá Ozi Script khỏi hệ thống."
echo ""
read -p "Bạn có chắc chắn? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Đã huỷ."
    exit 0
fi

echo ""

# Remove symlink
if [[ -L "$BIN_LINK" ]]; then
    rm -f "$BIN_LINK"
    print_success "Đã xoá symlink: $BIN_LINK"
fi

# Remove install directory
if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
    print_success "Đã xoá thư mục: $INSTALL_DIR"
fi

# Ask about config
if [[ -d "$CONFIG_DIR" ]]; then
    echo ""
    read -p "Xoá cấu hình ($CONFIG_DIR)? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$CONFIG_DIR"
        print_success "Đã xoá cấu hình"
    else
        print_warning "Giữ lại cấu hình"
    fi
fi

# Ask about logs
if [[ -d "$LOG_DIR" ]]; then
    echo ""
    read -p "Xoá logs ($LOG_DIR)? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$LOG_DIR"
        print_success "Đã xoá logs"
    else
        print_warning "Giữ lại logs"
    fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
print_success "Ozi Script đã được gỡ cài đặt!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
