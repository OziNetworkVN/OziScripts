#!/bin/bash
#================================================================
# Ozi Script - Helpers Module
# Mô tả: Các hàm tiện ích dùng chung
# Phiên bản: 1.0.0
#================================================================

# Đường dẫn đến thư mục core
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load colors
source "$CORE_DIR/colors.sh"

#================================================================
# PRINT FUNCTIONS
#================================================================

# In header đẹp với border
print_header() {
    local title="$1"
    local width=64
    local padding=$(( (width - ${#title} - 2) / 2 ))
    
    echo ""
    echo -e "${CYAN}${BOX_TL}$(printf '%0.s═' $(seq 1 $width))${BOX_TR}${NC}"
    echo -e "${CYAN}${BOX_V}${NC}$(printf '%*s' $padding '')  ${BOLD_WHITE}${title}${NC}$(printf '%*s' $padding '')  ${CYAN}${BOX_V}${NC}"
    echo -e "${CYAN}${BOX_BL}$(printf '%0.s═' $(seq 1 $width))${BOX_BR}${NC}"
    echo ""
}

# In header nhỏ (submenu)
print_subheader() {
    local title="$1"
    echo ""
    echo -e "${BOLD_CYAN}━━━ ${title} ━━━${NC}"
    echo ""
}

# In thông báo thành công
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# In thông báo lỗi
print_error() {
    echo -e "${RED}✗${NC} $1"
}

# In thông báo cảnh báo
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# In thông tin
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# In dòng menu
print_menu_item() {
    local number="$1"
    local text="$2"
    echo -e "  ${BOLD_CYAN}[${number}]${NC} ${text}"
}

# In dòng menu (quay lại)
print_menu_back() {
    echo ""
    echo -e "  ${BOLD_YELLOW}[0]${NC} ← Quay lại"
}

# In dòng menu (thoát)
print_menu_exit() {
    echo ""
    echo -e "  ${BOLD_YELLOW}[0]${NC} Thoát"
}

# In separator
print_separator() {
    echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
}

#================================================================
# INPUT FUNCTIONS
#================================================================

# Đọc lựa chọn số từ user
read_choice() {
    local prompt="${1:-Nhập lựa chọn}"
    local max="${2:-10}"
    local choice
    
    echo ""
    read -p "$(echo -e "${BOLD_WHITE}${prompt} [0-${max}]: ${NC}")" choice
    
    # Validate input
    if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
        echo ""
        print_error "Vui lòng nhập số"
        return 1
    fi
    
    if [[ "$choice" -lt 0 ]] || [[ "$choice" -gt "$max" ]]; then
        echo ""
        print_error "Lựa chọn không hợp lệ (0-${max})"
        return 1
    fi
    
    echo "$choice"
    return 0
}

# Hỏi xác nhận y/n
confirm() {
    local prompt="${1:-Bạn có chắc chắn?}"
    local response
    
    read -p "$(echo -e "${BOLD_WHITE}${prompt} (y/n): ${NC}")" -n 1 -r response
    echo ""
    
    [[ "$response" =~ ^[Yy]$ ]]
}

# Đọc input text
read_input() {
    local prompt="$1"
    local default="${2:-}"
    local value
    
    if [[ -n "$default" ]]; then
        read -p "$(echo -e "${BOLD_WHITE}${prompt} [${default}]: ${NC}")" value
        echo "${value:-$default}"
    else
        read -p "$(echo -e "${BOLD_WHITE}${prompt}: ${NC}")" value
        echo "$value"
    fi
}

# Đọc input ẩn (password)
read_secret() {
    local prompt="$1"
    local value
    
    read -s -p "$(echo -e "${BOLD_WHITE}${prompt}: ${NC}")" value
    echo ""
    echo "$value"
}

#================================================================
# VALIDATION FUNCTIONS
#================================================================

# Kiểm tra quyền root
require_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Script này cần quyền root. Vui lòng chạy với sudo."
        exit 1
    fi
}

# Kiểm tra OS là Debian 12+
check_debian() {
    if [[ ! -f /etc/debian_version ]]; then
        print_error "Script này chỉ hỗ trợ Debian Linux."
        exit 1
    fi
    
    local version=$(cat /etc/debian_version | cut -d. -f1)
    
    if [[ "$version" -lt 12 ]]; then
        print_error "Cần Debian 12 trở lên. Phiên bản hiện tại: $version"
        exit 1
    fi
    
    return 0
}

# Kiểm tra package đã cài chưa
is_installed() {
    local package="$1"
    dpkg -l "$package" 2>/dev/null | grep -q "^ii"
}

# Kiểm tra command có tồn tại
command_exists() {
    command -v "$1" &> /dev/null
}

# Kiểm tra service đang chạy
is_service_running() {
    local service="$1"
    systemctl is-active --quiet "$service"
}

# Ensure www-data user exists (needed for Nginx/PHP-FPM)
ensure_www_data_user() {
    # Check if www-data user exists
    if id "www-data" &>/dev/null; then
        return 0
    fi
    
    print_info "Đang tạo user www-data..."
    
    # Create www-data group if not exists
    if ! getent group www-data >/dev/null 2>&1; then
        groupadd -r www-data
    fi
    
    # Create www-data user
    useradd -r -g www-data -s /usr/sbin/nologin -d /var/www -M www-data
    
    print_success "User www-data đã được tạo"
}

# Ensure jq is installed (required for JSON operations)
ensure_jq_installed() {
    if ! command -v jq >/dev/null 2>&1; then
        print_info "Đang cài đặt jq (JSON processor)..."
        apt-get update -qq 2>/dev/null
        apt-get install -y jq >/dev/null 2>&1
        
        if command -v jq >/dev/null 2>&1; then
            print_success "Đã cài đặt jq"
        else
            print_error "Không thể cài đặt jq"
            return 1
        fi
    fi
}

#================================================================
# SYSTEM INFO FUNCTIONS
#================================================================

# Lấy IP public
get_public_ip() {
    curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || \
    curl -s --connect-timeout 5 icanhazip.com 2>/dev/null || \
    echo "Không xác định"
}

# Lấy thông tin Debian
get_debian_info() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$PRETTY_NAME"
    else
        echo "Debian $(cat /etc/debian_version)"
    fi
}

# Lấy hostname
get_hostname() {
    hostname -f 2>/dev/null || hostname
}

#================================================================
# FILE & LOG FUNCTIONS  
#================================================================

# Log vào file
log() {
    local level="${1:-INFO}"
    local message="$2"
    local log_file="${OZI_LOG_FILE:-/var/log/oziscript/ozi.log}"
    
    # Tạo thư mục log nếu chưa có
    mkdir -p "$(dirname "$log_file")" 2>/dev/null
    
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$log_file"
}

log_info() {
    log "INFO" "$1"
}

log_error() {
    log "ERROR" "$1"
}

log_warning() {
    log "WARNING" "$1"
}

#================================================================
# PACKAGE MANAGEMENT
#================================================================

# Cài đặt package
install_package() {
    local package="$1"
    
    if is_installed "$package"; then
        print_warning "$package đã được cài đặt"
        return 0
    fi
    
    print_info "Đang cài đặt $package..."
    
    if apt-get install -y -qq "$package" > /dev/null 2>&1; then
        print_success "$package đã được cài đặt"
        log_info "Installed package: $package"
        return 0
    else
        print_error "Không thể cài đặt $package"
        log_error "Failed to install package: $package"
        return 1
    fi
}

# Cập nhật apt cache
update_apt() {
    print_info "Đang cập nhật danh sách package..."
    apt-get update -qq > /dev/null 2>&1
}

#================================================================
# SERVICE MANAGEMENT
#================================================================

# Khởi động lại service
service_restart() {
    local service="$1"
    
    if systemctl restart "$service" 2>/dev/null; then
        print_success "$service đã được khởi động lại"
        return 0
    else
        print_error "Không thể khởi động lại $service"
        return 1
    fi
}

# Bật service
service_enable() {
    local service="$1"
    systemctl enable "$service" 2>/dev/null
    systemctl start "$service" 2>/dev/null
}

# Tắt service  
service_disable() {
    local service="$1"
    systemctl stop "$service" 2>/dev/null
    systemctl disable "$service" 2>/dev/null
}

#================================================================
# UTILITY FUNCTIONS
#================================================================

# Chờ enter để tiếp tục
wait_enter() {
    echo ""
    read -p "$(echo -e "${CYAN}Nhấn Enter để tiếp tục...${NC}")"
}

# Clear màn hình
clear_screen() {
    clear
}

# Hiển thị spinner khi chờ
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}
