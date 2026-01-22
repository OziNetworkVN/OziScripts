#!/bin/bash
#================================================================
# Ozi Script - Module: PostgreSQL
# Mô tả: Cài đặt và quản lý PostgreSQL
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"
source "$OZI_DIR/core/config.sh"

#================================================================
# CONFIGURATION
#================================================================
POSTGRES_VERSION="16"

#================================================================
# INSTALLATION
#================================================================

# Thêm PostgreSQL repository
add_postgres_repo() {
    if [[ -f /etc/apt/sources.list.d/pgdg.list ]]; then
        return 0
    fi
    
    print_info "Đang thêm PostgreSQL repository..."
    
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
        gpg --dearmor -o /usr/share/keyrings/postgresql.gpg
    
    echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
        > /etc/apt/sources.list.d/pgdg.list
    
    apt-get update -qq
    
    print_success "PostgreSQL repository đã được thêm"
}

# Cài đặt PostgreSQL
install_postgresql() {
    print_header "CÀI ĐẶT POSTGRESQL ${POSTGRES_VERSION}"
    
    if is_installed "postgresql-${POSTGRES_VERSION}"; then
        print_warning "PostgreSQL ${POSTGRES_VERSION} đã được cài đặt"
        
        if is_service_running "postgresql"; then
            print_success "PostgreSQL đang chạy"
        else
            systemctl start postgresql
            print_success "PostgreSQL đã được khởi động"
        fi
        return 0
    fi
    
    # Add repo
    add_postgres_repo
    
    print_info "Đang cài đặt PostgreSQL ${POSTGRES_VERSION}..."
    
    if apt-get install -y -qq "postgresql-${POSTGRES_VERSION}" "postgresql-contrib-${POSTGRES_VERSION}"; then
        print_success "PostgreSQL ${POSTGRES_VERSION} đã được cài đặt"
        log_info "Installed PostgreSQL $POSTGRES_VERSION"
    else
        print_error "Không thể cài đặt PostgreSQL"
        return 1
    fi
    
    # Enable and start
    systemctl enable postgresql
    systemctl start postgresql
    
    # Optimize config
    optimize_postgresql
    
    print_success "PostgreSQL đã sẵn sàng!"
    echo ""
    print_info "Để tạo database mới, dùng menu [4] Quản lý Database"
}

# Tối ưu PostgreSQL
optimize_postgresql() {
    local pg_conf="/etc/postgresql/${POSTGRES_VERSION}/main/postgresql.conf"
    
    if [[ ! -f "$pg_conf" ]]; then
        return 0
    fi
    
    print_info "Đang tối ưu cấu hình PostgreSQL..."
    
    # Backup
    cp "$pg_conf" "${pg_conf}.backup"
    
    # Get RAM in GB
    local ram_gb=$(free -g | awk 'NR==2{print $2}')
    [[ "$ram_gb" -lt 1 ]] && ram_gb=1
    
    # Calculate settings based on RAM
    local shared_buffers="${ram_gb}GB"
    local effective_cache="$((ram_gb * 3 / 4))GB"
    local maintenance_mem="$((ram_gb * 64))MB"
    local work_mem="$((ram_gb * 16))MB"
    
    # Append optimizations
    cat >> "$pg_conf" << EOF

# Ozi Script Optimizations (${ram_gb}GB RAM)
shared_buffers = ${shared_buffers}
effective_cache_size = ${effective_cache}
maintenance_work_mem = ${maintenance_mem}
work_mem = ${work_mem}
wal_buffers = 16MB
checkpoint_completion_target = 0.9
max_wal_size = 2GB
min_wal_size = 1GB
random_page_cost = 1.1
effective_io_concurrency = 200
max_parallel_workers_per_gather = 2
max_parallel_workers = 4
log_statement = 'ddl'
log_min_duration_statement = 1000
EOF
    
    systemctl restart postgresql
    
    print_success "Đã tối ưu cấu hình PostgreSQL"
}

#================================================================
# DATABASE MANAGEMENT
#================================================================

# Tạo database và user
create_database() {
    local db_name="$1"
    local db_user="${2:-$db_name}"
    local db_pass="${3:-$(openssl rand -base64 16)}"
    
    print_info "Đang tạo database: $db_name"
    
    # Create user
    sudo -u postgres psql -c "CREATE USER ${db_user} WITH PASSWORD '${db_pass}';" 2>/dev/null || true
    
    # Create database
    sudo -u postgres psql -c "CREATE DATABASE ${db_name} OWNER ${db_user} ENCODING 'UTF8';"
    
    # Grant privileges
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${db_name} TO ${db_user};"
    
    # Install extensions
    sudo -u postgres psql -d "$db_name" -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
    sudo -u postgres psql -d "$db_name" -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;"
    
    print_success "Database đã được tạo!"
    echo ""
    echo -e "  ${BOLD_CYAN}Database:${NC} $db_name"
    echo -e "  ${BOLD_CYAN}User:${NC}     $db_user"
    echo -e "  ${BOLD_CYAN}Password:${NC} $db_pass"
    echo ""
    print_warning "Hãy lưu lại thông tin này!"
}

# Liệt kê databases
list_databases() {
    print_header "DANH SÁCH DATABASE"
    
    if ! is_service_running "postgresql"; then
        print_error "PostgreSQL không chạy"
        return 1
    fi
    
    echo ""
    sudo -u postgres psql -c "\l"
    echo ""
}

# Xoá database
drop_database() {
    local db_name="$1"
    
    if ! confirm "Bạn có chắc muốn xoá database '$db_name'?"; then
        return 0
    fi
    
    sudo -u postgres psql -c "DROP DATABASE IF EXISTS ${db_name};"
    print_success "Database '$db_name' đã được xoá"
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-install}" in
        install)
            install_postgresql
            ;;
        create)
            create_database "${2:-}" "${3:-}" "${4:-}"
            ;;
        list)
            list_databases
            ;;
        drop)
            drop_database "${2:-}"
            ;;
        *)
            echo "Sử dụng: $0 {install|create|list|drop} [args]"
            ;;
    esac
fi
