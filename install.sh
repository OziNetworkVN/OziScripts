#!/bin/bash
#================================================================
# Ozi Script - Installer
# Mô tả: Script cài đặt Ozi Script vào hệ thống
# Sử dụng: sudo bash install.sh
# Phiên bản: 2.0.0
#================================================================

set -euo pipefail

#================================================================
# CONFIGURATION
#================================================================
OZI_VERSION="1.0.0"
INSTALL_DIR="/opt/oziscript"
BIN_LINK="/usr/local/bin/ozi"
CONFIG_DIR="/etc/oziscript"
LOG_DIR="/var/log/oziscript"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#================================================================
# COLORS
#================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

#================================================================
# FUNCTIONS
#================================================================

print_banner() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${GREEN}OZI SCRIPT INSTALLER${NC}                           ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}              Phiên bản: ${YELLOW}${OZI_VERSION}${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Script này cần quyền root. Vui lòng chạy với sudo."
        exit 1
    fi
}

check_debian() {
    if [[ ! -f /etc/debian_version ]]; then
        print_error "Ozi Script chỉ hỗ trợ Debian Linux."
        exit 1
    fi
    
    local version=$(cat /etc/debian_version | cut -d. -f1)
    
    if [[ "$version" -lt 12 ]]; then
        print_error "Cần Debian 12 (Bookworm) trở lên."
        print_info "Phiên bản hiện tại: Debian $version"
        exit 1
    fi
    
    print_success "Hệ điều hành: Debian $version"
}

install_dependencies() {
    print_info "Đang cài đặt các thành phần phụ thuộc..."
    
    apt-get update -qq
    apt-get install -y -qq curl git gnupg2 ca-certificates lsb-release tar gzip
    
    print_success "Các thành phần phụ thuộc đã được cài đặt"
}

install_files() {
    print_info "Đang cài đặt Ozi Script..."
    
    # Kiểm tra nếu đang chạy từ thư mục cài đặt đích
    if [[ "$SCRIPT_DIR" == "$INSTALL_DIR" ]]; then
        print_warning "Script đang chạy từ thư mục cài đặt."
        print_info "Tiến hành cài đặt tại chỗ..."
        
        # Tạo các thư mục cần thiết
        mkdir -p "$CONFIG_DIR"
        mkdir -p "$LOG_DIR"
        
        # Set permissions for in-place installation
        chmod +x "$INSTALL_DIR/ozi"
        find "$INSTALL_DIR" -name "*.sh" -exec chmod +x {} \;
        
        print_success "Cài đặt tại chỗ hoàn tất"
        return 0
    fi
    
    # Xoá cài đặt cũ nếu có
    if [[ -d "$INSTALL_DIR" ]]; then
        print_info "Xoá phiên bản cũ..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Tạo thư mục
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOG_DIR"
    
    # Copy files
    cp -r "$SCRIPT_DIR/core" "$INSTALL_DIR/"
    cp -r "$SCRIPT_DIR/modules" "$INSTALL_DIR/" 2>/dev/null || mkdir -p "$INSTALL_DIR/modules"
    cp -r "$SCRIPT_DIR/templates" "$INSTALL_DIR/" 2>/dev/null || mkdir -p "$INSTALL_DIR/templates"
    cp "$SCRIPT_DIR/ozi" "$INSTALL_DIR/"
    
    # Tạo các thư mục module nếu chưa có
    mkdir -p "$INSTALL_DIR/modules/system"
    mkdir -p "$INSTALL_DIR/modules/security"
    mkdir -p "$INSTALL_DIR/modules/stack"
    mkdir -p "$INSTALL_DIR/modules/site"
    mkdir -p "$INSTALL_DIR/modules/database"
    mkdir -p "$INSTALL_DIR/modules/backup"
    mkdir -p "$INSTALL_DIR/modules/deploy"
    mkdir -p "$INSTALL_DIR/templates/nginx"
    
    print_success "Files đã được copy vào $INSTALL_DIR"
}

set_permissions() {
    print_info "Đang thiết lập quyền..."
    
    # Set executable
    chmod +x "$INSTALL_DIR/ozi"
    find "$INSTALL_DIR" -name "*.sh" -exec chmod +x {} \;
    
    # Secure config
    chmod 700 "$CONFIG_DIR"
    chmod 755 "$LOG_DIR"
    
    print_success "Quyền đã được thiết lập"
}

create_symlink() {
    print_info "Tạo symlink..."
    
    # Xoá link cũ nếu có
    rm -f "$BIN_LINK"
    
    # Tạo symlink mới
    ln -s "$INSTALL_DIR/ozi" "$BIN_LINK"
    
    print_success "Symlink: $BIN_LINK -> $INSTALL_DIR/ozi"
}

setup_git_hooks() {
    print_info "Cài đặt Git hooks..."
    
    if [[ -d "$INSTALL_DIR/.git/hooks" ]]; then
        # Create post-merge hook
        cat > "$INSTALL_DIR/.git/hooks/post-merge" << 'HOOK_EOF'
#!/bin/bash
# Auto-set permissions after git pull/merge
echo "🔧 Setting file permissions..."
chmod +x /opt/oziscript/ozi 2>/dev/null || chmod +x ozi 2>/dev/null || true
find /opt/oziscript -name "*.sh" -exec chmod +x {} \; 2>/dev/null || find . -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
echo "✓ Permissions updated"
HOOK_EOF
        
        chmod +x "$INSTALL_DIR/.git/hooks/post-merge"
        
        # Test hook
        if [[ -x "$INSTALL_DIR/.git/hooks/post-merge" ]]; then
            print_success "Git hooks đã được cài đặt (auto-fix permissions sau git pull)"
        else
            print_warning "Git hook cài đặt nhưng chưa executable"
        fi
    else
        print_warning "Không tìm thấy .git/hooks (không phải Git repo)"
    fi
}

verify_installation() {
    print_info "Kiểm tra cài đặt..."
    
    if [[ -x "$BIN_LINK" ]]; then
        print_success "Lệnh 'ozi' đã sẵn sàng!"
    else
        print_error "Cài đặt thất bại!"
        exit 1
    fi
}

print_complete() {
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}       ✓ CÀI ĐẶT THÀNH CÔNG!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Để bắt đầu, gõ: ${YELLOW}ozi${NC}"
    echo ""
    echo -e "  Đường dẫn cài đặt: ${BLUE}$INSTALL_DIR${NC}"
    echo -e "  Cấu hình: ${BLUE}$CONFIG_DIR${NC}"
    echo -e "  Logs: ${BLUE}$LOG_DIR${NC}"
    echo ""
}

#================================================================
# MAIN
#================================================================
main() {
    print_banner
    check_root
    check_debian
    install_dependencies
    echo ""
    install_files
    set_permissions
    create_symlink
    setup_git_hooks
    verify_installation
    print_complete
}

main "$@"
