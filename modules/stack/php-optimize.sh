#!/bin/bash
#================================================================
# Ozi Script - PHP Configuration Optimizer
# Mô tả: Kiểm tra và tối ưu PHP config cho production
# Phiên bản: 1.0.0
#================================================================

set -euo pipefail

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"
source "$OZI_DIR/core/colors.sh"

#================================================================
# CONFIGURATION
#================================================================

# Required PHP extensions for Laravel
LARAVEL_EXTENSIONS=(
    "bcmath"
    "ctype"
    "curl"
    "dom"
    "fileinfo"
    "json"
    "mbstring"
    "openssl"
    "pcre"
    "pdo"
    "pdo_mysql"
    "tokenizer"
    "xml"
    "zip"
    "gd"
    "intl"
    "redis"
)

# Optional but recommended extensions
RECOMMENDED_EXTENSIONS=(
    "opcache"
    "imagick"
    "exif"
    "sodium"
)

#================================================================
# CHECK FUNCTIONS
#================================================================

check_php_extensions() {
    local php_version="${1:-8.3}"
    local missing=()
    local installed=()
    
    print_header "KIỂM TRA PHP $php_version EXTENSIONS"
    echo ""
    
    print_subheader "Extensions bắt buộc (Laravel):"
    for ext in "${LARAVEL_EXTENSIONS[@]}"; do
        if php"$php_version" -m 2>/dev/null | grep -q "^$ext\$"; then
            printf "  ${GREEN}✓${NC} %-20s ${GREEN}Installed${NC}\n" "$ext"
            installed+=("$ext")
        else
            printf "  ${RED}✗${NC} %-20s ${RED}Missing${NC}\n" "$ext"
            missing+=("$ext")
        fi
    done
    
    echo ""
    print_subheader "Extensions khuyến nghị:"
    for ext in "${RECOMMENDED_EXTENSIONS[@]}"; do
        if php"$php_version" -m 2>/dev/null | grep -q "^$ext\$"; then
            printf "  ${GREEN}✓${NC} %-20s ${GREEN}Installed${NC}\n" "$ext"
        else
            printf "  ${YELLOW}○${NC} %-20s ${YELLOW}Not installed${NC}\n" "$ext"
        fi
    done
    
    echo ""
    if [[ ${#missing[@]} -eq 0 ]]; then
        print_success "Tất cả extensions bắt buộc đã được cài đặt"
        return 0
    else
        print_warning "Thiếu ${#missing[@]} extensions"
        echo ""
        print_info "Cài đặt extensions thiếu:"
        echo "  apt-get install -y $(printf 'php%s-%s ' $(echo $php_version | tr -d .) "${missing[@]}")"
        return 1
    fi
}

check_php_config() {
    local php_version="${1:-8.3}"
    local php_ini="/etc/php/$php_version/fpm/php.ini"
    
    print_header "KIỂM TRA PHP $php_version CONFIG"
    echo ""
    
    if [[ ! -f "$php_ini" ]]; then
        print_error "File $php_ini không tồn tại"
        return 1
    fi
    
    # Important settings
    local settings=(
        "memory_limit:512M:Memory limit"
        "upload_max_filesize:64M:Max upload size"
        "post_max_size:64M:Max POST size"
        "max_execution_time:300:Max execution time"
        "max_input_time:300:Max input time"
        "date.timezone:Asia/Ho_Chi_Minh:Timezone"
    )
    
    printf "%-30s %-20s %-20s %s\n" "Setting" "Current" "Recommended" "Status"
    print_separator
    
    for setting_line in "${settings[@]}"; do
        IFS=':' read -r key recommended description <<< "$setting_line"
        
        local current=$(php"$php_version" -i 2>/dev/null | grep "^$key =>" | awk '{print $3}' | head -1)
        [[ -z "$current" ]] && current=$(php"$php_version" -r "echo ini_get('$key');" 2>/dev/null || echo "N/A")
        
        local status="${GREEN}✓${NC}"
        if [[ "$current" != "$recommended" ]]; then
            status="${YELLOW}○${NC}"
        fi
        
        printf "%s %-28s ${BOLD_WHITE}%-18s${NC} ${BLUE}%-18s${NC}\n" "$status" "$description" "$current" "$recommended"
    done
    
    echo ""
}

check_opcache_config() {
    local php_version="${1:-8.3}"
    
    print_header "KIỂM TRA OPCACHE CONFIG"
    echo ""
    
    if ! php"$php_version" -m 2>/dev/null | grep -q "^opcache\$"; then
        print_warning "OPcache chưa được cài đặt"
        return 1
    fi
    
    local opcache_settings=(
        "opcache.enable:1"
        "opcache.memory_consumption:256"
        "opcache.interned_strings_buffer:16"
        "opcache.max_accelerated_files:10000"
        "opcache.revalidate_freq:2"
        "opcache.fast_shutdown:1"
    )
    
    printf "%-40s %-15s %-15s\n" "Setting" "Current" "Recommended"
    print_separator
    
    for setting_line in "${opcache_settings[@]}"; do
        IFS=':' read -r key recommended <<< "$setting_line"
        
        local current=$(php"$php_version" -r "echo ini_get('$key');" 2>/dev/null || echo "N/A")
        
        local status="${GREEN}✓${NC}"
        [[ "$current" != "$recommended" ]] && status="${YELLOW}○${NC}"
        
        printf "%s %-38s ${BOLD_WHITE}%-13s${NC} ${BLUE}%-13s${NC}\n" "$status" "$key" "$current" "$recommended"
    done
    
    echo ""
}

check_fpm_pools() {
    local php_version="${1:-8.3}"
    local pool_dir="/etc/php/$php_version/fpm/pool.d"
    
    print_header "KIỂM TRA PHP-FPM POOLS"
    echo ""
    
    if [[ ! -d "$pool_dir" ]]; then
        print_error "Directory $pool_dir không tồn tại"
        return 1
    fi
    
    local pools=($(ls "$pool_dir"/*.conf 2>/dev/null | xargs -n1 basename | sed 's/.conf$//'))
    
    print_info "PHP-FPM Pools: ${#pools[@]}"
    echo ""
    
    for pool in "${pools[@]}"; do
        local pool_file="$pool_dir/$pool.conf"
        local pm=$(grep "^pm =" "$pool_file" | awk '{print $3}')
        local pm_max=$(grep "^pm.max_children" "$pool_file" | awk '{print $3}')
        
        printf "  ${CYAN}●${NC} %-20s PM: %-10s Max: %s\n" "$pool" "$pm" "$pm_max"
    done
    
    echo ""
}

#================================================================
# OPTIMIZE FUNCTIONS
#================================================================

optimize_php_ini() {
    local php_version="${1:-8.3}"
    local php_ini="/etc/php/$php_version/fpm/php.ini"
    
    print_header "TỐI ƯU PHP.INI"
    echo ""
    
    if [[ ! -f "$php_ini" ]]; then
        print_error "File $php_ini không tồn tại"
        return 1
    fi
    
    # Backup
    cp "$php_ini" "$php_ini.backup.$(date +%Y%m%d_%H%M%S)"
    print_info "Đã backup: $php_ini.backup.*"
    echo ""
    
    # Apply optimizations
    print_info "Đang áp dụng tối ưu..."
    
    sed -i 's/^memory_limit =.*/memory_limit = 512M/' "$php_ini"
    sed -i 's/^upload_max_filesize =.*/upload_max_filesize = 64M/' "$php_ini"
    sed -i 's/^post_max_size =.*/post_max_size = 64M/' "$php_ini"
    sed -i 's/^max_execution_time =.*/max_execution_time = 300/' "$php_ini"
    sed -i 's/^max_input_time =.*/max_input_time = 300/' "$php_ini"
    
    # Timezone
    if ! grep -q "^date.timezone" "$php_ini"; then
        echo "date.timezone = Asia/Ho_Chi_Minh" >> "$php_ini"
    else
        sed -i 's|^;*date.timezone =.*|date.timezone = Asia/Ho_Chi_Minh|' "$php_ini"
    fi
    
    print_success "Đã tối ưu php.ini"
}

optimize_opcache() {
    local php_version="${1:-8.3}"
    local opcache_ini="/etc/php/$php_version/fpm/conf.d/10-opcache.ini"
    
    print_header "TỐI ƯU OPCACHE"
    echo ""
    
    if [[ ! -f "$opcache_ini" ]]; then
        print_warning "File $opcache_ini không tồn tại, tạo mới..."
        opcache_ini="/etc/php/$php_version/mods-available/opcache.ini"
    fi
    
    # Backup
    [[ -f "$opcache_ini" ]] && cp "$opcache_ini" "$opcache_ini.backup.$(date +%Y%m%d_%H%M%S)"
    
    cat > "$opcache_ini" << 'EOF'
; OPcache Configuration
zend_extension=opcache.so
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=10000
opcache.max_wasted_percentage=10
opcache.use_cwd=1
opcache.validate_timestamps=1
opcache.revalidate_freq=2
opcache.fast_shutdown=1
opcache.save_comments=1
EOF
    
    print_success "Đã tối ưu OPcache"
}

optimize_fpm_pool() {
    local php_version="${1:-8.3}"
    local domain="${2:-www}"
    local pool_file="/etc/php/$php_version/fpm/pool.d/$domain.conf"
    
    # Calculate optimal values based on RAM
    local total_ram=$(free -m | awk '/^Mem:/{print $2}')
    local max_children=$((total_ram / 50))  # ~50MB per child
    [[ $max_children -lt 10 ]] && max_children=10
    [[ $max_children -gt 100 ]] && max_children=100
    
    local start_servers=$((max_children / 4))
    local min_spare=$((max_children / 5))
    local max_spare=$((max_children / 2))
    
    print_info "Tối ưu pool: $domain"
    print_info "RAM: ${total_ram}MB → Max children: $max_children"
    echo ""
    
    if [[ "$domain" == "www" ]]; then
        pool_file="/etc/php/$php_version/fpm/pool.d/www.conf"
    fi
    
    # Backup
    [[ -f "$pool_file" ]] && cp "$pool_file" "$pool_file.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Update settings
    sed -i "s/^pm.max_children =.*/pm.max_children = $max_children/" "$pool_file"
    sed -i "s/^pm.start_servers =.*/pm.start_servers = $start_servers/" "$pool_file"
    sed -i "s/^pm.min_spare_servers =.*/pm.min_spare_servers = $min_spare/" "$pool_file"
    sed -i "s/^pm.max_spare_servers =.*/pm.max_spare_servers = $max_spare/" "$pool_file"
    
    print_success "Đã tối ưu FPM pool"
}

#================================================================
# COMMANDS
#================================================================

cmd_check() {
    local php_version="${1:-}"
    
    if [[ -z "$php_version" ]]; then
        # Get default PHP version
        php_version=$(get_default_php_version 2>/dev/null || echo "8.3")
    fi
    
    check_php_extensions "$php_version"
    echo ""
    check_php_config "$php_version"
    echo ""
    check_opcache_config "$php_version"
    echo ""
    check_fpm_pools "$php_version"
}

cmd_optimize() {
    local php_version="${1:-}"
    
    if [[ -z "$php_version" ]]; then
        php_version=$(get_default_php_version 2>/dev/null || echo "8.3")
    fi
    
    if ! confirm "Tối ưu PHP $php_version config cho production?"; then
        print_info "Đã hủy"
        return 0
    fi
    
    optimize_php_ini "$php_version"
    echo ""
    optimize_opcache "$php_version"
    echo ""
    optimize_fpm_pool "$php_version" "www"
    echo ""
    
    print_info "Đang khởi động lại PHP-FPM..."
    systemctl restart php"$php_version"-fpm
    
    print_success "Hoàn tất tối ưu!"
    echo ""
    print_info "Chạy lại: ozi php check để xem kết quả"
}

cmd_install_extensions() {
    local php_version="${1:-}"
    
    if [[ -z "$php_version" ]]; then
        php_version=$(get_default_php_version 2>/dev/null || echo "8.3")
    fi
    
    print_header "CÀI ĐẶT PHP EXTENSIONS"
    echo ""
    
    local extensions=(
        "php${php_version}-bcmath"
        "php${php_version}-cli"
        "php${php_version}-curl"
        "php${php_version}-fpm"
        "php${php_version}-gd"
        "php${php_version}-intl"
        "php${php_version}-mbstring"
        "php${php_version}-mysql"
        "php${php_version}-opcache"
        "php${php_version}-readline"
        "php${php_version}-redis"
        "php${php_version}-xml"
        "php${php_version}-zip"
    )
    
    print_info "Sẽ cài đặt ${#extensions[@]} extensions..."
    echo ""
    
    for ext in "${extensions[@]}"; do
        if dpkg -l | grep -q "^ii  $ext "; then
            print_info "$ext: đã cài"
        else
            print_info "Cài đặt: $ext"
            apt-get install -y "$ext" >/dev/null 2>&1 && print_success "Đã cài $ext"
        fi
    done
    
    echo ""
    print_success "Hoàn tất!"
}

show_help() {
    cat << 'EOF'
Sử dụng: ozi php {command} [php-version]

Commands:
    check [version]       Kiểm tra PHP config và extensions
    optimize [version]    Tối ưu PHP cho production
    extensions [version]  Cài đặt extensions đầy đủ
    help                  Hiển thị trợ giúp

PHP Version: 7.4, 8.1, 8.2, 8.3, 8.4 (mặc định: phiên bản default)

Examples:
    ozi php check           # Kiểm tra PHP mặc định
    ozi php check 8.4       # Kiểm tra PHP 8.4
    ozi php optimize        # Tối ưu PHP cho production
    ozi php extensions 8.3  # Cài extensions cho PHP 8.3

Kiểm tra:
    - Extensions bắt buộc (Laravel, WordPress)
    - Settings quan trọng (memory, upload, timezone)
    - OPcache config
    - PHP-FPM pools

Tối ưu:
    - Memory limit: 512M
    - Upload size: 64M
    - Execution time: 300s
    - OPcache: 256M
    - FPM pools: Auto calculate based on RAM
EOF
}

#================================================================
# MAIN
#================================================================

main() {
    local cmd="${1:-check}"
    shift || true
    
    case "$cmd" in
        check|c)
            cmd_check "$@"
            ;;
        optimize|opt|o)
            require_root
            cmd_optimize "$@"
            ;;
        extensions|ext|e)
            require_root
            cmd_install_extensions "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $cmd"
            show_help
            return 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
