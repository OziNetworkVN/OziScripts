#!/bin/bash
#================================================================
# Ozi Script - Module: PHP Management
# Mô tả: Cài đặt và quản lý multiple PHP versions
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"
source "$OZI_DIR/core/config.sh"

#================================================================
# PHP CONFIGURATION
#================================================================
SUPPORTED_PHP_VERSIONS=("7.4" "8.0" "8.1" "8.2" "8.3" "8.4")

PHP_EXTENSIONS=(
    "fpm"
    "cli"
    "common"
    "pgsql"
    "mysql"
    "redis"
    "curl"
    "mbstring"
    "xml"
    "zip"
    "bcmath"
    "intl"
    "gd"
    "imagick"
    "opcache"
)

# Extensions cần cho Laravel/Swoole
PHP_EXTENSIONS_EXTRA=(
    "swoole"
    "pcntl"
    "readline"
)

#================================================================
# REPOSITORY MANAGEMENT
#================================================================

# Ensure www-data user exists
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

# Thêm Sury PHP repository
add_sury_repo() {
    if [[ -f /etc/apt/sources.list.d/php.list ]]; then
        print_info "Sury PHP repository đã được thêm trước đó"
        return 0
    fi
    
    print_info "Đang thêm Sury PHP repository..."
    
    # Install prerequisites
    apt-get update -qq
    apt-get install -y -qq curl gnupg2 ca-certificates lsb-release apt-transport-https
    
    # Add Sury GPG key
    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    
    # Add repository
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" \
        > /etc/apt/sources.list.d/php.list
    
    # Update apt
    apt-get update -qq
    
    print_success "Sury PHP repository đã được thêm"
    log_info "Added Sury PHP repository"
}

#================================================================
# INSTALLATION
#================================================================

# Cài đặt PHP version
install_php() {
    local version="$1"
    
    # Validate version
    if [[ ! " ${SUPPORTED_PHP_VERSIONS[*]} " =~ " ${version} " ]]; then
        print_error "Phiên bản PHP không hỗ trợ: $version"
        print_info "Các phiên bản hỗ trợ: ${SUPPORTED_PHP_VERSIONS[*]}"
        return 1
    fi
    
    # Check if already installed
    if is_installed "php${version}-fpm"; then
        print_warning "PHP ${version} đã được cài đặt"
        return 0
    fi
    
    print_header "CÀI ĐẶT PHP ${version}"
    
    # Ensure www-data user exists (required for PHP-FPM)
    ensure_www_data_user
    
    # Add Sury repo if needed
    add_sury_repo
    
    # Build package list
    local packages=""
    for ext in "${PHP_EXTENSIONS[@]}"; do
        packages="$packages php${version}-${ext}"
    done
    
    # Install PHP
    print_info "Đang cài đặt PHP ${version} và các extensions..."
    
    if apt-get install -y -qq $packages; then
        print_success "PHP ${version} đã được cài đặt"
        log_info "Installed PHP $version with extensions"
    else
        print_error "Không thể cài đặt PHP ${version}"
        log_error "Failed to install PHP $version"
        return 1
    fi
    
    # Try to install extra extensions (may fail on some versions)
    for ext in "${PHP_EXTENSIONS_EXTRA[@]}"; do
        apt-get install -y -qq "php${version}-${ext}" 2>/dev/null || true
    done
    
    # Optimize PHP-FPM config
    optimize_php_fpm "$version"
    
    # Restart PHP-FPM
    systemctl restart "php${version}-fpm"
    systemctl enable "php${version}-fpm"
    
    print_success "PHP ${version} đã sẵn sàng sử dụng!"
    
    return 0
}

# Tối ưu cấu hình PHP-FPM dựa trên RAM thực tế
optimize_php_fpm() {
    local version="$1"
    local fpm_conf="/etc/php/${version}/fpm/pool.d/www.conf"
    local php_ini="/etc/php/${version}/fpm/php.ini"
    
    if [[ ! -f "$fpm_conf" ]]; then
        return 0
    fi
    
    # Lấy thông số RAM (MB)
    local total_ram=$(free -m | awk '/^Mem:/{print $2}')
    print_info "Đang tối ưu cấu hình PHP ${version} cho VPS (${total_ram}MB RAM)..."
    
    # Tính toán thông số
    local mem_limit="128M"
    local max_children=5
    local start_servers=2
    local min_spare=2
    local max_spare=4
    
    if [[ "$total_ram" -le 1024 ]]; then
        # VPS < 1GB
        mem_limit="128M"
        max_children=10
        start_servers=2
        min_spare=2
        max_spare=4
    elif [[ "$total_ram" -le 2048 ]]; then
        # VPS 2GB
        mem_limit="256M"
        max_children=25
        start_servers=4
        min_spare=4
        max_spare=8
    elif [[ "$total_ram" -le 4096 ]]; then
        # VPS 4GB
        mem_limit="512M"
        max_children=50
        start_servers=8
        min_spare=8
        max_spare=16
    else
        # VPS > 4GB
        mem_limit="1024M"
        max_children=100
        start_servers=16
        min_spare=16
        max_spare=32
    fi
    
    # Backup original
    cp "$fpm_conf" "${fpm_conf}.backup"
    cp "$php_ini" "${php_ini}.backup"
    
    # Optimize FPM pool
    sed -i "s/^pm = .*/pm = dynamic/" "$fpm_conf"
    sed -i "s/^pm.max_children = .*/pm.max_children = ${max_children}/" "$fpm_conf"
    sed -i "s/^pm.start_servers = .*/pm.start_servers = ${start_servers}/" "$fpm_conf"
    sed -i "s/^pm.min_spare_servers = .*/pm.min_spare_servers = ${min_spare}/" "$fpm_conf"
    sed -i "s/^pm.max_spare_servers = .*/pm.max_spare_servers = ${max_spare}/" "$fpm_conf"
    
    # Optimize php.ini
    sed -i "s/^memory_limit = .*/memory_limit = ${mem_limit}/" "$php_ini"
    sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 100M/' "$php_ini"
    sed -i 's/^post_max_size = .*/post_max_size = 100M/' "$php_ini"
    sed -i 's/^max_execution_time = .*/max_execution_time = 300/' "$php_ini"
    sed -i 's/^max_input_time = .*/max_input_time = 300/' "$php_ini"
    sed -i 's/^;date.timezone =.*/date.timezone = Asia\/Ho_Chi_Minh/' "$php_ini"
    
    # Enable OPcache
    local opcache_ini="/etc/php/${version}/fpm/conf.d/10-opcache.ini"
    if [[ -f "$opcache_ini" ]]; then
        sed -i 's/^;opcache.enable=.*/opcache.enable=1/' "$opcache_ini"
        sed -i 's/^;opcache.memory_consumption=.*/opcache.memory_consumption=256/' "$opcache_ini"
        sed -i 's/^;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=20000/' "$opcache_ini"
    fi
    
    print_success "Đã tối ưu cấu hình PHP ${version}"
}

# Interactive install
install_php_interactive() {
    print_header "CÀI ĐẶT PHP"
    
    echo "  Các phiên bản PHP có thể cài đặt:"
    echo ""
    
    local i=1
    for v in "${SUPPORTED_PHP_VERSIONS[@]}"; do
        if is_installed "php${v}-fpm"; then
            echo -e "  ${BOLD_CYAN}[$i]${NC} PHP $v ${GREEN}(đã cài)${NC}"
        else
            echo -e "  ${BOLD_CYAN}[$i]${NC} PHP $v"
        fi
        ((i++))
    done
    
    echo ""
    echo -e "  ${BOLD_YELLOW}[0]${NC} Quay lại"
    echo ""
    
    read -p "$(echo -e "${BOLD_WHITE}Chọn phiên bản để cài [0-${#SUPPORTED_PHP_VERSIONS[@]}]: ${NC}")" choice
    
    if [[ "$choice" == "0" ]]; then
        return 0
    fi
    
    if [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#SUPPORTED_PHP_VERSIONS[@]}" ]]; then
        local selected_version="${SUPPORTED_PHP_VERSIONS[$((choice-1))]}"
        install_php "$selected_version"
    else
        print_error "Lựa chọn không hợp lệ"
    fi
}

#================================================================
# LISTING & INFO
#================================================================

# Liệt kê PHP versions đã cài
list_php_versions() {
    print_header "DANH SÁCH PHP ĐÃ CÀI"
    
    local found=false
    
    for v in "${SUPPORTED_PHP_VERSIONS[@]}"; do
        if is_installed "php${v}-fpm"; then
            found=true
            
            local status="stopped"
            local color="$RED"
            
            if systemctl is-active --quiet "php${v}-fpm"; then
                status="running"
                color="$GREEN"
            fi
            
            local default_mark=""
            if [[ "$(get_default_php_version)" == "$v" ]]; then
                default_mark=" ${BOLD_YELLOW}(default)${NC}"
            fi
            
            echo -e "  ${BOLD_CYAN}▸ PHP ${v}${NC}${default_mark}"
            echo -e "    Status: ${color}${status}${NC}"
            echo -e "    FPM: php${v}-fpm"
            echo ""
        fi
    done
    
    if [[ "$found" == false ]]; then
        print_warning "Chưa có PHP nào được cài đặt"
    fi
}

# Đổi PHP mặc định
set_default_php() {
    local version="$1"
    
    if ! is_installed "php${version}-cli"; then
        print_error "PHP ${version} chưa được cài đặt"
        return 1
    fi
    
    print_info "Đang đặt PHP ${version} làm mặc định..."
    
    update-alternatives --set php /usr/bin/php${version}
    update-alternatives --set phar /usr/bin/phar${version}
    update-alternatives --set phar.phar /usr/bin/phar.phar${version}
    
    # Update config
    set_config "DEFAULT_PHP_VERSION" "$version"
    
    print_success "PHP ${version} đã được đặt làm mặc định"
    log_info "Set PHP $version as default"
}

# Gỡ PHP version
remove_php() {
    local version="$1"
    
    if ! is_installed "php${version}-fpm"; then
        print_error "PHP ${version} chưa được cài đặt"
        return 1
    fi
    
    if ! confirm "Bạn có chắc muốn gỡ PHP ${version}?"; then
        print_info "Đã huỷ"
        return 0
    fi
    
    print_info "Đang gỡ PHP ${version}..."
    
    # Stop service first
    systemctl stop "php${version}-fpm" 2>/dev/null || true
    
    # Remove packages
    apt-get remove --purge -y "php${version}-*"
    apt-get autoremove -y
    
    print_success "PHP ${version} đã được gỡ"
    log_info "Removed PHP $version"
}

# Edit PHP configuration
edit_php_ini() {
    local version="$1"

    if [[ -z "$version" ]]; then
        version=$(get_default_php_version)
    fi

    if [[ -z "$version" ]]; then
        print_error "Không tìm thấy phiên bản PHP nào"
        return 1
    fi

    local php_ini="/etc/php/${version}/fpm/php.ini"

    if [[ ! -f "$php_ini" ]]; then
        print_error "Không tìm thấy file config: $php_ini"
        return 1
    fi

    print_info "Đang mở php.ini ($version)..."

    if command_exists nano; then
        nano "$php_ini"
    else
        vi "$php_ini"
    fi

    print_info "Khởi động lại PHP-FPM..."
    systemctl restart "php${version}-fpm"
    print_success "Đã cập nhật cấu hình PHP"
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-}" in
        install)
            install_php "${2:-8.3}"
            ;;
        list)
            list_php_versions
            ;;
        default)
            set_default_php "${2:-8.3}"
            ;;
        remove)
            remove_php "${2:-}"
            ;;
        edit)
            edit_php_ini "${2:-}"
            ;;
        *)
            echo "Sử dụng: $0 {install|list|default|remove|edit} [version]"
            ;;
    esac
fi
