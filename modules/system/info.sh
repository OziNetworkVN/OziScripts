#!/bin/bash
#================================================================
# Ozi Script - Module: System Info
# Mô tả: Hiển thị thông tin hệ thống
# Phiên bản: 1.0.0
#================================================================

# Load core nếu chưa load
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OZI_DIR="${OZI_DIR:-/opt/oziscript}"

if [[ -f "$OZI_DIR/core/helpers.sh" ]]; then
    source "$OZI_DIR/core/helpers.sh"
    source "$OZI_DIR/core/os.sh"
fi

#================================================================
# SYSTEM INFO FUNCTIONS
#================================================================

# Hiển thị thống kê tổng quan
show_system_overview() {
    print_header "THÔNG TIN HỆ THỐNG"
    
    local ip=$(get_public_ip)
    local hostname=$(get_hostname)
    local os_info=$(get_debian_info)
    local kernel=$(get_kernel_version)
    local arch=$(get_arch)
    local uptime=$(get_uptime)
    local load=$(get_load_average)
    
    echo -e "  ${BOLD_CYAN}▸ Hostname:${NC}      $hostname"
    echo -e "  ${BOLD_CYAN}▸ IP Public:${NC}     $ip"
    echo -e "  ${BOLD_CYAN}▸ Hệ điều hành:${NC}  $os_info"
    echo -e "  ${BOLD_CYAN}▸ Kernel:${NC}        $kernel ($arch)"
    echo -e "  ${BOLD_CYAN}▸ Uptime:${NC}        $uptime"
    echo -e "  ${BOLD_CYAN}▸ Load Average:${NC}  $load"
    echo ""
    
    print_separator
    echo -e "  ${BOLD_WHITE}CPU & RAM${NC}"
    print_separator
    
    # CPU Info
    local cpu_cores=$(nproc)
    local cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    
    echo -e "  ${BOLD_CYAN}▸ CPU:${NC}           $cpu_model"
    echo -e "  ${BOLD_CYAN}▸ CPU Cores:${NC}     $cpu_cores"
    echo -e "  ${BOLD_CYAN}▸ CPU Usage:${NC}     ${cpu_usage}%"
    echo ""
    
    # RAM Info
    local ram_total=$(free -m | awk 'NR==2{print $2}')
    local ram_used=$(free -m | awk 'NR==2{print $3}')
    local ram_free=$(free -m | awk 'NR==2{print $7}')
    local ram_percent=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    
    echo -e "  ${BOLD_CYAN}▸ RAM Total:${NC}     ${ram_total} MB"
    echo -e "  ${BOLD_CYAN}▸ RAM Used:${NC}      ${ram_used} MB (${ram_percent}%)"
    echo -e "  ${BOLD_CYAN}▸ RAM Available:${NC} ${ram_free} MB"
    echo ""
    
    # Swap Info
    local swap_total=$(free -m | awk 'NR==3{print $2}')
    local swap_used=$(free -m | awk 'NR==3{print $3}')
    
    if [[ "$swap_total" -gt 0 ]]; then
        echo -e "  ${BOLD_CYAN}▸ Swap Total:${NC}    ${swap_total} MB"
        echo -e "  ${BOLD_CYAN}▸ Swap Used:${NC}     ${swap_used} MB"
    else
        echo -e "  ${BOLD_CYAN}▸ Swap:${NC}          ${YELLOW}Chưa cấu hình${NC}"
    fi
    echo ""
    
    print_separator
    echo -e "  ${BOLD_WHITE}DISK${NC}"
    print_separator
    
    # Disk Info
    echo ""
    df -h | grep -E '^/dev/' | while read line; do
        local dev=$(echo "$line" | awk '{print $1}')
        local size=$(echo "$line" | awk '{print $2}')
        local used=$(echo "$line" | awk '{print $3}')
        local avail=$(echo "$line" | awk '{print $4}')
        local percent=$(echo "$line" | awk '{print $5}')
        local mount=$(echo "$line" | awk '{print $6}')
        
        echo -e "  ${BOLD_CYAN}▸ ${mount}${NC}"
        echo -e "    Size: ${size}  Used: ${used}  Avail: ${avail}  (${percent})"
    done
    echo ""
    
    print_separator
    echo -e "  ${BOLD_WHITE}SERVICES${NC}"
    print_separator
    echo ""
    
    # Check common services
    check_service_status() {
        local service="$1"
        local name="$2"
        
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "  ${GREEN}●${NC} $name"
        elif systemctl is-enabled --quiet "$service" 2>/dev/null; then
            echo -e "  ${YELLOW}○${NC} $name (stopped)"
        fi
    }
    
    check_service_status "nginx" "Nginx"
    check_service_status "php8.3-fpm" "PHP 8.3-FPM"
    check_service_status "php8.2-fpm" "PHP 8.2-FPM"
    check_service_status "postgresql" "PostgreSQL"
    check_service_status "mysql" "MySQL"
    check_service_status "mariadb" "MariaDB"
    check_service_status "redis-server" "Redis"
    check_service_status "supervisor" "Supervisor"
    check_service_status "fail2ban" "Fail2ban"
    check_service_status "ufw" "UFW Firewall"
    
    echo ""
}

# Hiển thị chi tiết CPU
show_cpu_info() {
    print_header "THÔNG TIN CPU"
    
    echo ""
    lscpu | grep -E "^(Architecture|CPU\(s\)|Model name|CPU MHz|CPU max MHz|Virtualization)" | \
    while IFS=':' read -r key value; do
        echo -e "  ${BOLD_CYAN}▸ $key:${NC} $(echo "$value" | xargs)"
    done
    echo ""
}

# Hiển thị chi tiết RAM
show_ram_info() {
    print_header "THÔNG TIN RAM"
    
    echo ""
    free -h
    echo ""
}

# Hiển thị chi tiết Disk
show_disk_info() {
    print_header "THÔNG TIN DISK"
    
    echo ""
    df -h
    echo ""
    
    print_subheader "Top 10 thư mục lớn nhất"
    du -h /var/www --max-depth=1 2>/dev/null | sort -hr | head -10 || \
        echo "  Không có dữ liệu trong /var/www"
    echo ""
}

# Đổi Hostname
change_hostname() {
    print_header "ĐỔI HOSTNAME"

    local current_hostname=$(get_hostname)
    echo -e "  Hostname hiện tại: ${BOLD_CYAN}${current_hostname}${NC}"
    echo ""

    local new_hostname=$(read_input "Nhập hostname mới")

    if [[ -z "$new_hostname" ]]; then
        print_error "Hostname không được để trống"
        return 1
    fi

    hostnamectl set-hostname "$new_hostname"

    # Update /etc/hosts
    if grep -q "127.0.0.1.*$current_hostname" /etc/hosts; then
        sed -i "s/127.0.0.1.*$current_hostname/127.0.0.1 $new_hostname/" /etc/hosts
    else
        echo "127.0.0.1 $new_hostname" >> /etc/hosts
    fi

    print_success "Hostname đã được đổi thành '$new_hostname'"
    log_info "Changed hostname to: $new_hostname"
}

# Đổi Timezone
change_timezone() {
    print_header "ĐỔI TIMEZONE"

    local current_timezone=$(timedatectl show --property=Timezone --value)
    echo -e "  Timezone hiện tại: ${BOLD_CYAN}${current_timezone}${NC}"
    echo ""

    local new_timezone=$(read_input "Nhập timezone (vd: Asia/Ho_Chi_Minh)" "Asia/Ho_Chi_Minh")

    if [[ -z "$new_timezone" ]]; then
        print_error "Timezone không được để trống"
        return 1
    fi

    if timedatectl set-timezone "$new_timezone" 2>/dev/null; then
        print_success "Timezone đã được đổi thành '$new_timezone'"
        echo -e "  Thời gian hiện tại: $(date)"

        # Update config
        set_config "TIMEZONE" "$new_timezone"

        log_info "Changed timezone to: $new_timezone"
    else
        print_error "Timezone không hợp lệ"
        return 1
    fi
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    show_system_overview
fi
