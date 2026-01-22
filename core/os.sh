#!/bin/bash
#================================================================
# Ozi Script - OS Detection Module
# Mô tả: Kiểm tra và xác định hệ điều hành
# Phiên bản: 1.0.0
#================================================================

#================================================================
# OS DETECTION
#================================================================

# Kiểm tra và trả về tên OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$ID"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# Lấy version số của OS
get_os_version() {
    if [[ -f /etc/debian_version ]]; then
        cat /etc/debian_version | cut -d. -f1
    else
        echo "0"
    fi
}

# Lấy codename của Debian
get_debian_codename() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$VERSION_CODENAME"
    else
        echo "unknown"
    fi
}

# Kiểm tra đây có phải Debian không
is_debian() {
    [[ "$(detect_os)" == "debian" ]]
}

# Kiểm tra phiên bản Debian có hỗ trợ không (12+)
is_supported_debian() {
    local version=$(get_os_version)
    [[ "$version" -ge 12 ]]
}

# Validate OS - exit nếu không hỗ trợ
validate_os() {
    local CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$CORE_DIR/helpers.sh"
    
    if ! is_debian; then
        print_error "Ozi Script chỉ hỗ trợ Debian Linux."
        print_info "Hệ điều hành phát hiện: $(detect_os)"
        exit 1
    fi
    
    if ! is_supported_debian; then
        print_error "Cần Debian 12 (Bookworm) trở lên."
        print_info "Phiên bản hiện tại: Debian $(get_os_version)"
        exit 1
    fi
    
    return 0
}

#================================================================
# SYSTEM INFO
#================================================================

# Lấy thông tin CPU
get_cpu_info() {
    local cores=$(nproc 2>/dev/null || echo "N/A")
    local model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    echo "$cores cores - ${model:-Unknown}"
}

# Lấy thông tin RAM
get_ram_info() {
    free -h | awk 'NR==2{printf "%s / %s (%.1f%%)", $3, $2, $3*100/$2}'
}

# Lấy thông tin Disk
get_disk_info() {
    df -h / | awk 'NR==2{printf "%s / %s (%s)", $3, $2, $5}'
}

# Lấy Load Average
get_load_average() {
    uptime | awk -F'load average:' '{print $2}' | xargs
}

# Lấy Uptime
get_uptime() {
    uptime -p | sed 's/up //'
}

# Lấy Kernel version
get_kernel_version() {
    uname -r
}

# Lấy Architecture
get_arch() {
    uname -m
}
