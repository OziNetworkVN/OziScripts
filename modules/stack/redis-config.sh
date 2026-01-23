#!/bin/bash
#================================================================
# Ozi Script - Redis Configuration
# Mô tả: Cấu hình Redis cho Laravel và production
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
REDIS_CONF="/etc/redis/redis.conf"
REDIS_SOCKET="/var/run/redis/redis-server.sock"

#================================================================
# CHECK FUNCTIONS
#================================================================

check_redis_status() {
    print_header "KIỂM TRA REDIS STATUS"
    echo ""
    
    if ! systemctl is-active redis-server >/dev/null 2>&1; then
        print_error "Redis không chạy"
        return 1
    fi
    
    print_success "Redis đang chạy"
    echo ""
    
    # Version
    local version=$(redis-cli --version | awk '{print $2}')
    print_info "Version: $version"
    
    # Memory
    local memory=$(redis-cli INFO memory | grep "used_memory_human" | cut -d':' -f2 | tr -d '\r')
    print_info "Memory used: $memory"
    
    # Connected clients
    local clients=$(redis-cli INFO clients | grep "connected_clients" | cut -d':' -f2 | tr -d '\r')
    print_info "Connected clients: $clients"
    
    # Uptime
    local uptime=$(redis-cli INFO server | grep "uptime_in_days" | cut -d':' -f2 | tr -d '\r')
    print_info "Uptime: $uptime days"
    
    echo ""
}

check_redis_config() {
    print_header "KIỂM TRA REDIS CONFIG"
    echo ""
    
    if [[ ! -f "$REDIS_CONF" ]]; then
        print_error "File $REDIS_CONF không tồn tại"
        return 1
    fi
    
    local settings=(
        "maxmemory:512mb:Max memory"
        "maxmemory-policy:allkeys-lru:Eviction policy"
        "save::Persistence (empty=disabled)"
    )
    
    printf "%-30s %-20s %s\n" "Setting" "Value" "Description"
    print_separator
    
    # Maxmemory
    local maxmem=$(grep "^maxmemory " "$REDIS_CONF" | awk '{print $2}' || echo "not set")
    printf "%-30s ${BOLD_WHITE}%-20s${NC} %s\n" "maxmemory" "$maxmem" "Max memory"
    
    # Maxmemory policy
    local policy=$(grep "^maxmemory-policy" "$REDIS_CONF" | awk '{print $2}' || echo "noeviction")
    printf "%-30s ${BOLD_WHITE}%-20s${NC} %s\n" "maxmemory-policy" "$policy" "Eviction policy"
    
    # Persistence
    local save_count=$(grep "^save " "$REDIS_CONF" | wc -l)
    local persist="Enabled ($save_count rules)"
    [[ $save_count -eq 0 ]] && persist="Disabled"
    printf "%-30s ${BOLD_WHITE}%-20s${NC} %s\n" "save" "$persist" "Persistence"
    
    # Unix socket
    local socket=$(grep "^unixsocket " "$REDIS_CONF" | awk '{print $2}' || echo "not set")
    printf "%-30s ${BOLD_WHITE}%-20s${NC} %s\n" "unixsocket" "$socket" "Unix socket"
    
    # Password
    local pass=$(grep "^requirepass" "$REDIS_CONF" | awk '{print $2}' || echo "not set")
    local pass_display="not set"
    [[ "$pass" != "not set" ]] && pass_display="********"
    printf "%-30s ${BOLD_WHITE}%-20s${NC} %s\n" "requirepass" "$pass_display" "Password"
    
    echo ""
}

check_redis_performance() {
    print_header "KIỂM TRA REDIS PERFORMANCE"
    echo ""
    
    print_info "Đang chạy benchmark..."
    echo ""
    
    # Run quick benchmark
    redis-benchmark -q -t ping,set,get -n 10000 2>/dev/null | while read line; do
        echo "  $line"
    done
    
    echo ""
}

#================================================================
# OPTIMIZE FUNCTIONS
#================================================================

optimize_redis_config() {
    print_header "TỐI ƯU REDIS CONFIG"
    echo ""
    
    if [[ ! -f "$REDIS_CONF" ]]; then
        print_error "File $REDIS_CONF không tồn tại"
        return 1
    fi
    
    # Backup
    cp "$REDIS_CONF" "$REDIS_CONF.backup.$(date +%Y%m%d_%H%M%S)"
    print_info "Đã backup: $REDIS_CONF.backup.*"
    echo ""
    
    print_info "Đang áp dụng tối ưu..."
    
    # Set maxmemory (256MB default)
    if ! grep -q "^maxmemory " "$REDIS_CONF"; then
        echo "maxmemory 256mb" >> "$REDIS_CONF"
    else
        sed -i 's/^maxmemory .*/maxmemory 256mb/' "$REDIS_CONF"
    fi
    
    # Set eviction policy for cache
    if ! grep -q "^maxmemory-policy" "$REDIS_CONF"; then
        echo "maxmemory-policy allkeys-lru" >> "$REDIS_CONF"
    else
        sed -i 's/^maxmemory-policy.*/maxmemory-policy allkeys-lru/' "$REDIS_CONF"
    fi
    
    # Disable persistence (for cache only)
    sed -i 's/^save/#save/g' "$REDIS_CONF"
    
    # Enable Unix socket for better performance
    if ! grep -q "^unixsocket " "$REDIS_CONF"; then
        echo "unixsocket $REDIS_SOCKET" >> "$REDIS_CONF"
        echo "unixsocketperm 770" >> "$REDIS_CONF"
    fi
    
    # Add www-data to redis group
    if ! groups www-data | grep -q redis; then
        usermod -a -G redis www-data
        print_info "Đã thêm www-data vào redis group"
    fi
    
    print_success "Đã tối ưu redis config"
}

setup_laravel_redis() {
    local domain="${1:-}"
    
    if [[ -z "$domain" ]]; then
        domain=$(read_input "Nhập domain")
    fi
    
    print_header "CẤU HÌNH REDIS CHO LARAVEL"
    echo ""
    
    local env_file="/var/www/$domain/.env"
    
    if [[ ! -f "$env_file" ]]; then
        print_error "File .env không tồn tại: $env_file"
        return 1
    fi
    
    print_info "Cập nhật .env..."
    
    # Update Redis config in .env
    sed -i 's/^CACHE_DRIVER=.*/CACHE_DRIVER=redis/' "$env_file"
    sed -i 's/^SESSION_DRIVER=.*/SESSION_DRIVER=redis/' "$env_file"
    sed -i 's/^QUEUE_CONNECTION=.*/QUEUE_CONNECTION=redis/' "$env_file"
    
    # Set Redis connection
    if grep -q "^REDIS_HOST=" "$env_file"; then
        sed -i 's|^REDIS_HOST=.*|REDIS_HOST=/var/run/redis/redis-server.sock|' "$env_file"
    else
        echo "REDIS_HOST=/var/run/redis/redis-server.sock" >> "$env_file"
    fi
    
    if grep -q "^REDIS_PORT=" "$env_file"; then
        sed -i 's/^REDIS_PORT=.*/REDIS_PORT=0/' "$env_file"
    else
        echo "REDIS_PORT=0" >> "$env_file"
    fi
    
    print_success "Đã cấu hình Redis cho Laravel"
    echo ""
    print_info "Laravel sẽ sử dụng Redis cho:"
    echo "  - Cache (CACHE_DRIVER=redis)"
    echo "  - Session (SESSION_DRIVER=redis)"
    echo "  - Queue (QUEUE_CONNECTION=redis)"
    echo ""
    print_info "Clear cache sau khi cập nhật:"
    echo "  cd /var/www/$domain"
    echo "  php artisan cache:clear"
    echo "  php artisan config:clear"
}

#================================================================
# COMMANDS
#================================================================

cmd_check() {
    check_redis_status
    echo ""
    check_redis_config
}

cmd_optimize() {
    require_root
    
    if ! confirm "Tối ưu Redis cho Laravel cache?"; then
        print_info "Đã hủy"
        return 0
    fi
    
    optimize_redis_config
    echo ""
    
    print_info "Đang khởi động lại Redis..."
    systemctl restart redis-server
    
    # Wait for Redis to start
    sleep 2
    
    if systemctl is-active redis-server >/dev/null 2>&1; then
        print_success "Redis đã khởi động lại"
        echo ""
        check_redis_status
    else
        print_error "Không thể khởi động Redis"
        return 1
    fi
}

cmd_laravel() {
    require_root
    
    local domain="${1:-}"
    setup_laravel_redis "$domain"
}

cmd_benchmark() {
    print_header "REDIS BENCHMARK"
    echo ""
    
    print_info "Chạy benchmark đầy đủ..."
    echo ""
    
    redis-benchmark -q -n 100000
}

show_help() {
    cat << 'EOF'
Sử dụng: ozi redis {command} [options]

Commands:
    check           Kiểm tra Redis status và config
    optimize        Tối ưu Redis cho production
    laravel [domain] Cấu hình Redis cho Laravel site
    benchmark       Chạy Redis benchmark
    help            Hiển thị trợ giúp

Examples:
    ozi redis check
    ozi redis optimize
    ozi redis laravel example.com
    ozi redis benchmark

Tối ưu cho Laravel:
    - Maxmemory: 256MB
    - Eviction: allkeys-lru
    - Persistence: disabled (cache only)
    - Unix socket: enabled (faster than TCP)
    - Laravel: cache, session, queue via Redis

Laravel .env config:
    CACHE_DRIVER=redis
    SESSION_DRIVER=redis
    QUEUE_CONNECTION=redis
    REDIS_HOST=/var/run/redis/redis-server.sock
    REDIS_PORT=0
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
            cmd_check
            ;;
        optimize|opt|o)
            cmd_optimize
            ;;
        laravel|l)
            cmd_laravel "$@"
            ;;
        benchmark|bench|b)
            cmd_benchmark
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
