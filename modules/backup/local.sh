#!/bin/bash
#================================================================
# Ozi Script - Module: Backup
# Mô tả: Backup và Restore hệ thống
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"
source "$OZI_DIR/core/config.sh"

#================================================================
# BACKUP CONFIGURATION
#================================================================
BACKUP_DIR="${BACKUP_DIR:-/var/backups/oziscript}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"

#================================================================
# BACKUP FUNCTIONS
#================================================================

# Tạo backup đầy đủ
create_full_backup() {
    print_header "TẠO BACKUP ĐẦY ĐỦ"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="backup_full_${timestamp}"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    mkdir -p "$backup_path"
    
    print_info "Đang tạo backup..."
    
    # Backup websites
    if [[ -d "$WWW_DIR" ]]; then
        print_info "Backup websites..."
        tar -czf "$backup_path/www.tar.gz" -C "$(dirname $WWW_DIR)" "$(basename $WWW_DIR)" 2>/dev/null
        print_success "Websites đã được backup"
    fi
    
    # Backup Nginx configs
    if [[ -d "/etc/nginx" ]]; then
        print_info "Backup Nginx configs..."
        tar -czf "$backup_path/nginx.tar.gz" -C "/etc" "nginx" 2>/dev/null
        print_success "Nginx configs đã được backup"
    fi
    
    # Backup SSL certificates
    if [[ -d "$SSL_DIR" ]]; then
        print_info "Backup SSL certificates..."
        tar -czf "$backup_path/ssl.tar.gz" -C "$(dirname $SSL_DIR)" "$(basename $SSL_DIR)" 2>/dev/null
        print_success "SSL certificates đã được backup"
    fi
    
    # Backup Ozi Script config
    if [[ -d "$OZI_CONFIG_DIR" ]]; then
        cp -r "$OZI_CONFIG_DIR" "$backup_path/oziscript_config"
    fi
    
    # Backup PostgreSQL (if installed)
    if is_service_running "postgresql"; then
        print_info "Backup PostgreSQL databases..."
        sudo -u postgres pg_dumpall | gzip > "$backup_path/postgresql.sql.gz"
        print_success "PostgreSQL đã được backup"
    fi
    
    # Backup MySQL/MariaDB (if installed)
    if is_service_running "mariadb" || is_service_running "mysql"; then
        print_info "Backup MySQL databases..."
        local mysql_pass=$(get_mysql_root_password 2>/dev/null)
        if [[ -n "$mysql_pass" ]]; then
            mysqldump -u root -p"$mysql_pass" --all-databases | gzip > "$backup_path/mysql.sql.gz"
            print_success "MySQL đã được backup"
        fi
    fi
    
    # Backup crontabs
    print_info "Backup crontabs..."
    crontab -l > "$backup_path/crontab_root.txt" 2>/dev/null || true
    ( cd /var/spool/cron/crontabs && tar -czf "$backup_path/crontabs.tar.gz" . 2>/dev/null ) || true
    
    # Create final archive
    print_info "Đang nén backup..."
    local final_backup="$BACKUP_DIR/${backup_name}.tar.gz"
    tar -czf "$final_backup" -C "$BACKUP_DIR" "$backup_name"
    rm -rf "$backup_path"
    
    local backup_size=$(du -h "$final_backup" | cut -f1)
    
    print_success "Backup hoàn tất!"
    echo ""
    echo -e "  ${BOLD_CYAN}File:${NC} $final_backup"
    echo -e "  ${BOLD_CYAN}Size:${NC} $backup_size"
    echo ""
    
    log_info "Created full backup: $final_backup ($backup_size)"
    
    # Cleanup old backups
    cleanup_old_backups
}

# Backup chỉ database
create_db_backup() {
    print_header "BACKUP DATABASE"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    # PostgreSQL
    if is_service_running "postgresql"; then
        local pg_backup="$BACKUP_DIR/db_postgresql_${timestamp}.sql.gz"
        print_info "Backup PostgreSQL..."
        sudo -u postgres pg_dumpall | gzip > "$pg_backup"
        print_success "PostgreSQL: $pg_backup"
    fi
    
    # MySQL/MariaDB
    if is_service_running "mariadb" || is_service_running "mysql"; then
        local mysql_pass=$(get_mysql_root_password 2>/dev/null)
        if [[ -n "$mysql_pass" ]]; then
            local mysql_backup="$BACKUP_DIR/db_mysql_${timestamp}.sql.gz"
            print_info "Backup MySQL..."
            mysqldump -u root -p"$mysql_pass" --all-databases | gzip > "$mysql_backup"
            print_success "MySQL: $mysql_backup"
        fi
    fi
    
    print_success "Backup database hoàn tất!"
}

# Liệt kê backups
list_backups() {
    print_header "DANH SÁCH BACKUP"
    
    echo ""
    
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A $BACKUP_DIR 2>/dev/null)" ]]; then
        print_warning "Chưa có backup nào"
        return 0
    fi
    
    local i=1
    for backup in $(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null); do
        local name=$(basename "$backup")
        local size=$(du -h "$backup" | cut -f1)
        local date=$(stat -c %y "$backup" | cut -d' ' -f1)
        
        echo -e "  ${BOLD_CYAN}[$i]${NC} $name (${size}, ${date})"
        ((i++))
    done
    
    echo ""
}

# Dọn dẹp backups cũ
cleanup_old_backups() {
    print_info "Dọn dẹp backups cũ (giữ ${BACKUP_RETENTION_DAYS} ngày)..."
    
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime +${BACKUP_RETENTION_DAYS} -delete 2>/dev/null
    find "$BACKUP_DIR" -name "*.sql.gz" -mtime +${BACKUP_RETENTION_DAYS} -delete 2>/dev/null
}

#================================================================
# RESTORE FUNCTIONS
#================================================================

# Restore từ backup
restore_backup() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        # Interactive selection
        list_backups
        local backup_name=$(read_input "Nhập tên file backup (hoặc số thứ tự)")
        
        if [[ "$backup_name" =~ ^[0-9]+$ ]]; then
            backup_file=$(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | sed -n "${backup_name}p")
        else
            backup_file="$BACKUP_DIR/$backup_name"
        fi
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        print_error "Không tìm thấy file backup: $backup_file"
        return 1
    fi
    
    print_header "RESTORE BACKUP"
    
    echo -e "  File: ${BOLD_CYAN}$backup_file${NC}"
    echo ""
    
    print_warning "Restore sẽ ghi đè dữ liệu hiện tại!"
    
    if ! confirm "Bạn có chắc muốn restore?"; then
        return 0
    fi
    
    print_info "Đang giải nén backup..."
    
    local temp_dir=$(mktemp -d)
    tar -xzf "$backup_file" -C "$temp_dir"
    
    local backup_content=$(ls "$temp_dir")
    local backup_path="$temp_dir/$backup_content"
    
    # Restore websites
    if [[ -f "$backup_path/www.tar.gz" ]]; then
        print_info "Restore websites..."
        tar -xzf "$backup_path/www.tar.gz" -C "$(dirname $WWW_DIR)"
        print_success "Websites đã được restore"
    fi
    
    # Restore Nginx configs
    if [[ -f "$backup_path/nginx.tar.gz" ]]; then
        print_info "Restore Nginx configs..."
        tar -xzf "$backup_path/nginx.tar.gz" -C "/etc"
        nginx -t && systemctl reload nginx
        print_success "Nginx configs đã được restore"
    fi
    
    # Restore SSL
    if [[ -f "$backup_path/ssl.tar.gz" ]]; then
        print_info "Restore SSL certificates..."
        tar -xzf "$backup_path/ssl.tar.gz" -C "$(dirname $SSL_DIR)"
        print_success "SSL certificates đã được restore"
    fi
    
    # Restore PostgreSQL
    if [[ -f "$backup_path/postgresql.sql.gz" ]] && is_service_running "postgresql"; then
        print_info "Restore PostgreSQL databases..."
        gunzip -c "$backup_path/postgresql.sql.gz" | sudo -u postgres psql
        print_success "PostgreSQL đã được restore"
    fi
    
    # Restore MySQL
    if [[ -f "$backup_path/mysql.sql.gz" ]] && (is_service_running "mariadb" || is_service_running "mysql"); then
        print_info "Restore MySQL databases..."
        local mysql_pass=$(get_mysql_root_password 2>/dev/null)
        if [[ -n "$mysql_pass" ]]; then
            gunzip -c "$backup_path/mysql.sql.gz" | mysql -u root -p"$mysql_pass"
            print_success "MySQL đã được restore"
        fi
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    
    print_success "Restore hoàn tất!"
    log_info "Restored from backup: $backup_file"
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-}" in
        full)
            create_full_backup
            ;;
        db)
            create_db_backup
            ;;
        list)
            list_backups
            ;;
        restore)
            restore_backup "${2:-}"
            ;;
        cleanup)
            cleanup_old_backups
            ;;
        *)
            echo "Sử dụng: $0 {full|db|list|restore|cleanup}"
            ;;
    esac
fi
