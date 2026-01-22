#!/bin/bash
#================================================================
# Ozi Script - Module: Redis
# Mô tả: Cài đặt và quản lý Redis
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"
source "$OZI_DIR/core/config.sh"

#================================================================
# INSTALLATION
#================================================================

# Thêm Redis repository
add_redis_repo() {
    if [[ -f /etc/apt/sources.list.d/redis.list ]]; then
        return 0
    fi
    
    print_info "Đang thêm Redis repository..."
    
    curl -fsSL https://packages.redis.io/gpg | \
        gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
    
    echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" \
        > /etc/apt/sources.list.d/redis.list
    
    apt-get update -qq
    
    print_success "Redis repository đã được thêm"
}

# Cài đặt Redis
install_redis() {
    print_header "CÀI ĐẶT REDIS"
    
    if is_installed "redis-server"; then
        print_warning "Redis đã được cài đặt"
        
        if is_service_running "redis-server"; then
            print_success "Redis đang chạy"
        else
            systemctl start redis-server
            print_success "Redis đã được khởi động"
        fi
        return 0
    fi
    
    # Add repo
    add_redis_repo
    
    print_info "Đang cài đặt Redis..."
    
    if apt-get install -y -qq redis-server; then
        print_success "Redis đã được cài đặt"
        log_info "Installed Redis"
    else
        print_error "Không thể cài đặt Redis"
        return 1
    fi
    
    # Enable and start
    systemctl enable redis-server
    systemctl start redis-server
    
    # Optimize config
    optimize_redis
    
    # Test connection
    if redis-cli ping | grep -q "PONG"; then
        print_success "Redis đã sẵn sàng!"
    else
        print_error "Redis không phản hồi"
    fi
}

# Tối ưu Redis
optimize_redis() {
    local redis_conf="/etc/redis/redis.conf"
    
    if [[ ! -f "$redis_conf" ]]; then
        return 0
    fi
    
    print_info "Đang tối ưu cấu hình Redis..."
    
    # Backup
    cp "$redis_conf" "${redis_conf}.backup"
    
    # Get RAM in GB
    local ram_gb=$(free -g | awk 'NR==2{print $2}')
    [[ "$ram_gb" -lt 1 ]] && ram_gb=1
    
    # Allocate 25% of RAM to Redis (max 4GB)
    local redis_mem=$((ram_gb / 4))
    [[ "$redis_mem" -lt 1 ]] && redis_mem=1
    [[ "$redis_mem" -gt 4 ]] && redis_mem=4
    
    # Apply settings
    sed -i "s/^# maxmemory .*/maxmemory ${redis_mem}gb/" "$redis_conf"
    sed -i "s/^# maxmemory-policy .*/maxmemory-policy allkeys-lru/" "$redis_conf"
    sed -i "s/^bind .*/bind 127.0.0.1/" "$redis_conf"
    
    # Enable persistence
    sed -i 's/^appendonly .*/appendonly yes/' "$redis_conf"
    
    systemctl restart redis-server
    
    print_success "Đã tối ưu cấu hình Redis (${redis_mem}GB memory)"
}

#================================================================
# STATUS
#================================================================

# Xem trạng thái Redis
show_redis_status() {
    print_header "TRẠNG THÁI REDIS"
    
    if ! is_installed "redis-server"; then
        print_error "Redis chưa được cài đặt"
        return 1
    fi
    
    echo ""
    redis-cli INFO server | head -20
    echo ""
    
    # Memory info
    print_subheader "Memory Usage"
    redis-cli INFO memory | grep -E "(used_memory_human|maxmemory_human)"
    echo ""
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-install}" in
        install)
            install_redis
            ;;
        status)
            show_redis_status
            ;;
        restart)
            systemctl restart redis-server
            print_success "Redis đã được khởi động lại"
            ;;
        *)
            echo "Sử dụng: $0 {install|status|restart}"
            ;;
    esac
fi
