#!/bin/bash
#================================================================
# Ozi Script - Module: MySQL/MariaDB
# Mô tả: Cài đặt và quản lý MySQL/MariaDB
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"
source "$OZI_DIR/core/config.sh"

#================================================================
# INSTALLATION
#================================================================

# Cài đặt MariaDB (recommended over MySQL for Debian)
install_mysql() {
    print_header "CÀI ĐẶT MARIADB"
    
    if is_installed "mariadb-server" || is_installed "mysql-server"; then
        print_warning "MySQL/MariaDB đã được cài đặt"
        
        if is_service_running "mariadb" || is_service_running "mysql"; then
            print_success "MySQL/MariaDB đang chạy"
        else
            systemctl start mariadb 2>/dev/null || systemctl start mysql
            print_success "MySQL/MariaDB đã được khởi động"
        fi
        return 0
    fi
    
    print_info "Đang cài đặt MariaDB..."
    
    apt-get update -qq
    
    if apt-get install -y -qq mariadb-server mariadb-client; then
        print_success "MariaDB đã được cài đặt"
        log_info "Installed MariaDB"
    else
        print_error "Không thể cài đặt MariaDB"
        return 1
    fi
    
    # Enable and start
    systemctl enable mariadb
    systemctl start mariadb
    
    # Secure installation
    secure_mysql
    
    print_success "MariaDB đã sẵn sàng!"
}

# Secure MariaDB installation
secure_mysql() {
    print_info "Đang bảo mật MariaDB..."
    
    # Generate random root password
    local root_pass=$(openssl rand -base64 16)
    
    # Secure installation commands
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${root_pass}';"
    mysql -u root -p"${root_pass}" -e "DELETE FROM mysql.user WHERE User='';"
    mysql -u root -p"${root_pass}" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    mysql -u root -p"${root_pass}" -e "DROP DATABASE IF EXISTS test;"
    mysql -u root -p"${root_pass}" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
    mysql -u root -p"${root_pass}" -e "FLUSH PRIVILEGES;"
    
    # Save root password to config
    cat > "$OZI_CONFIG_DIR/mysql.conf" << EOF
# MariaDB Root Password
# ⚠️ Keep this file secure!
MYSQL_ROOT_PASSWORD=${root_pass}
EOF
    chmod 600 "$OZI_CONFIG_DIR/mysql.conf"
    
    print_success "MariaDB đã được bảo mật"
    echo ""
    echo -e "  ${BOLD_CYAN}Root Password:${NC} $root_pass"
    echo -e "  ${BOLD_CYAN}Saved to:${NC} $OZI_CONFIG_DIR/mysql.conf"
    echo ""
    print_warning "Hãy lưu lại mật khẩu này!"
}

#================================================================
# DATABASE MANAGEMENT
#================================================================

# Lấy root password
get_mysql_root_password() {
    if [[ -f "$OZI_CONFIG_DIR/mysql.conf" ]]; then
        grep "^MYSQL_ROOT_PASSWORD=" "$OZI_CONFIG_DIR/mysql.conf" | cut -d= -f2
    else
        echo ""
    fi
}

# Tạo database và user
create_mysql_database() {
    local db_name="$1"
    local db_user="${2:-$db_name}"
    local db_pass="${3:-$(openssl rand -base64 16)}"
    
    local root_pass=$(get_mysql_root_password)
    
    if [[ -z "$root_pass" ]]; then
        print_error "Không tìm thấy root password. Vui lòng nhập thủ công:"
        root_pass=$(read_secret "MySQL Root Password")
    fi
    
    print_info "Đang tạo database: $db_name"
    
    # Create database
    mysql -u root -p"${root_pass}" -e "CREATE DATABASE IF NOT EXISTS \`${db_name}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    
    # Create user
    mysql -u root -p"${root_pass}" -e "CREATE USER IF NOT EXISTS '${db_user}'@'localhost' IDENTIFIED BY '${db_pass}';"
    
    # Grant privileges
    mysql -u root -p"${root_pass}" -e "GRANT ALL PRIVILEGES ON \`${db_name}\`.* TO '${db_user}'@'localhost';"
    mysql -u root -p"${root_pass}" -e "FLUSH PRIVILEGES;"
    
    print_success "Database đã được tạo!"
    echo ""
    echo -e "  ${BOLD_CYAN}Database:${NC} $db_name"
    echo -e "  ${BOLD_CYAN}User:${NC}     $db_user"
    echo -e "  ${BOLD_CYAN}Password:${NC} $db_pass"
    echo ""
}

# Liệt kê databases
list_mysql_databases() {
    print_header "DANH SÁCH DATABASE"
    
    local root_pass=$(get_mysql_root_password)
    
    if [[ -z "$root_pass" ]]; then
        root_pass=$(read_secret "MySQL Root Password")
    fi
    
    echo ""
    mysql -u root -p"${root_pass}" -e "SHOW DATABASES;"
    echo ""
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-install}" in
        install)
            install_mysql
            ;;
        create)
            create_mysql_database "${2:-}" "${3:-}" "${4:-}"
            ;;
        list)
            list_mysql_databases
            ;;
        *)
            echo "Sử dụng: $0 {install|create|list} [args]"
            ;;
    esac
fi
