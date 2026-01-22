#!/bin/bash
#================================================================
# Ozi Script - Menu System
# Mô tả: Hệ thống menu dạng số
# Phiên bản: 1.0.0
#================================================================

# Load core modules
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_DIR/colors.sh"
source "$CORE_DIR/helpers.sh"
source "$CORE_DIR/config.sh"
source "$CORE_DIR/os.sh"

#================================================================
# MENU DISPLAY FUNCTIONS
#================================================================

# Hiển thị banner chính
show_banner() {
    local ip=$(get_public_ip)
    local os_info=$(get_debian_info)
    
    clear_screen
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${BOLD_WHITE}OZI SCRIPT${NC} - ${BOLD_CYAN}Quản lý VPS${NC}                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}              ${GREEN}VPS: ${ip}${NC}                         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}              ${YELLOW}${os_info}${NC}                  ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Hiển thị menu chính
show_main_menu() {
    show_banner
    
    echo -e "${BOLD_WHITE}  MENU CHÍNH${NC}"
    print_separator
    echo ""
    
    print_menu_item "1" "Thông tin hệ thống"
    print_menu_item "2" "Quản lý PHP"
    print_menu_item "3" "Quản lý Nginx"
    print_menu_item "4" "Quản lý Database"
    print_menu_item "5" "Quản lý Website"
    print_menu_item "6" "SSL / Cloudflare"
    print_menu_item "7" "Bảo mật Server"
    print_menu_item "8" "Backup & Restore"
    print_menu_item "9" "Deploy ứng dụng"
    print_menu_item "10" "Cài đặt thêm"
    
    print_menu_exit
}

# Hiển thị submenu header
show_submenu_header() {
    local title="$1"
    
    clear_screen
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${BOLD_WHITE}${title}${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

#================================================================
# SUBMENUS
#================================================================

# Menu Thông tin hệ thống
menu_system_info() {
    show_submenu_header "THÔNG TIN HỆ THỐNG"
    
    print_menu_item "1" "Xem thống kê tổng quan"
    print_menu_item "2" "Xem thông tin CPU"
    print_menu_item "3" "Xem thông tin RAM"
    print_menu_item "4" "Xem thông tin Disk"
    print_menu_item "5" "Đổi Hostname"
    print_menu_item "6" "Đổi Timezone"
    print_menu_item "7" "Quản lý Swap"
    print_menu_item "8" "Kiểm tra cập nhật script"
    
    print_menu_back
}

# Menu Quản lý PHP
menu_php() {
    show_submenu_header "QUẢN LÝ PHP"
    
    local installed=$(get_installed_php_versions)
    local default=$(get_default_php_version)
    
    if [[ -n "$installed" ]]; then
        echo -e "  ${BLUE}PHP đã cài:${NC} $installed"
        [[ -n "$default" ]] && echo -e "  ${BLUE}Mặc định:${NC} $default"
        echo ""
    fi
    
    print_menu_item "1" "Cài đặt PHP mới"
    print_menu_item "2" "Xem danh sách PHP đã cài"
    print_menu_item "3" "Đổi PHP mặc định"
    print_menu_item "4" "Gỡ phiên bản PHP"
    print_menu_item "5" "Cấu hình PHP (php.ini)"
    print_menu_item "6" "Khởi động lại PHP-FPM"
    
    print_menu_back
}

# Menu Quản lý Nginx
menu_nginx() {
    show_submenu_header "QUẢN LÝ NGINX"
    
    local status="Chưa cài đặt"
    if is_installed "nginx"; then
        if is_service_running "nginx"; then
            status="${GREEN}Đang chạy${NC}"
        else
            status="${RED}Đã dừng${NC}"
        fi
    fi
    
    echo -e "  ${BLUE}Trạng thái:${NC} $status"
    echo ""
    
    print_menu_item "1" "Cài đặt Nginx"
    print_menu_item "2" "Xem trạng thái Nginx"
    print_menu_item "3" "Khởi động lại Nginx"
    print_menu_item "4" "Test cấu hình Nginx"
    print_menu_item "5" "Xem logs Nginx"
    
    print_menu_back
}

# Menu Quản lý Database
menu_database() {
    show_submenu_header "QUẢN LÝ DATABASE"
    
    echo -e "  ${BLUE}PostgreSQL:${NC} $(is_postgresql_installed && echo -e "${GREEN}Đã cài${NC}" || echo -e "${YELLOW}Chưa cài${NC}")"
    echo -e "  ${BLUE}MySQL/MariaDB:${NC} $(is_mysql_installed && echo -e "${GREEN}Đã cài${NC}" || echo -e "${YELLOW}Chưa cài${NC}")"
    echo ""
    
    print_menu_item "1" "Cài đặt PostgreSQL"
    print_menu_item "2" "Cài đặt MySQL/MariaDB"
    print_menu_item "3" "Quản lý PostgreSQL"
    print_menu_item "4" "Quản lý MySQL"
    print_menu_item "5" "Cài đặt Adminer"
    print_menu_item "6" "Backup Database"
    print_menu_item "7" "Restore Database"
    
    print_menu_back
}

# Menu Quản lý Website
menu_website() {
    show_submenu_header "QUẢN LÝ WEBSITE"
    
    # Đếm số site
    local site_count=$(ls -1 "$NGINX_SITES_AVAILABLE" 2>/dev/null | wc -l)
    echo -e "  ${BLUE}Số website:${NC} $site_count"
    echo ""
    
    print_menu_item "1" "Tạo website mới"
    print_menu_item "2" "Danh sách website"
    print_menu_item "3" "Xoá website"
    print_menu_item "4" "Enable/Disable website"
    print_menu_item "5" "Xem logs website"
    
    print_menu_back
}

# Menu SSL / Cloudflare
menu_ssl() {
    show_submenu_header "SSL / CLOUDFLARE"
    
    print_menu_item "1" "Cài SSL Cloudflare (15 năm)"
    print_menu_item "2" "Cài SSL Let's Encrypt"
    print_menu_item "3" "Xem danh sách SSL"
    print_menu_item "4" "Gia hạn SSL Let's Encrypt"
    print_menu_item "5" "Cấu hình Cloudflare API"
    
    print_menu_back
}

# Menu Bảo mật
menu_security() {
    show_submenu_header "BẢO MẬT SERVER"
    
    print_menu_item "1" "Cấu hình Firewall (UFW)"
    print_menu_item "2" "Quản lý Port"
    print_menu_item "3" "Thêm SSH Key"
    print_menu_item "4" "Tắt đăng nhập Root"
    print_menu_item "5" "Đổi Port SSH"
    print_menu_item "6" "Cài đặt Fail2ban"
    print_menu_item "7" "Hardening tự động"
    
    print_menu_back
}

# Menu Backup & Restore
menu_backup() {
    show_submenu_header "BACKUP & RESTORE"
    
    print_menu_item "1" "Tạo Backup đầy đủ"
    print_menu_item "2" "Tạo Backup Database only"
    print_menu_item "3" "Danh sách Backup"
    print_menu_item "4" "Restore từ Backup"
    print_menu_item "5" "Cấu hình Backup tự động"
    print_menu_item "6" "Cấu hình Offsite Backup (S3/R2)"
    
    print_menu_back
}

# Menu Deploy
menu_deploy() {
    show_submenu_header "DEPLOY ỨNG DỤNG"
    
    print_menu_item "1" "Deploy Laravel"
    print_menu_item "2" "Deploy Node.js"
    print_menu_item "3" "Deploy WordPress"
    print_menu_item "4" "Cấu hình Git deploy"
    
    print_menu_back
}

# Menu Cài đặt thêm
menu_extras() {
    show_submenu_header "CÀI ĐẶT THÊM"
    
    echo -e "  ${BLUE}Node.js:${NC} $(command_exists node && echo -e "${GREEN}$(node -v 2>/dev/null)${NC}" || echo -e "${YELLOW}Chưa cài${NC}")"
    echo -e "  ${BLUE}Redis:${NC} $(is_installed redis-server && echo -e "${GREEN}Đã cài${NC}" || echo -e "${YELLOW}Chưa cài${NC}")"
    echo -e "  ${BLUE}Supervisor:${NC} $(is_installed supervisor && echo -e "${GREEN}Đã cài${NC}" || echo -e "${YELLOW}Chưa cài${NC}")"
    echo -e "  ${BLUE}Composer:${NC} $(command_exists composer && echo -e "${GREEN}$(composer --version 2>/dev/null | awk '{print $3}')${NC}" || echo -e "${YELLOW}Chưa cài${NC}")"
    echo ""
    
    print_menu_item "1" "Cài đặt Node.js (NVM)"
    print_menu_item "2" "Cài đặt Redis"
    print_menu_item "3" "Cài đặt Supervisor"
    print_menu_item "4" "Cài đặt PM2"
    print_menu_item "5" "Cài đặt Composer"
    print_menu_item "6" "Cài đặt Certbot"
    print_menu_item "7" "Cài đặt FFmpeg"
    
    print_menu_back
}

#================================================================
# MENU NAVIGATION
#================================================================

# Handler menu chính
handle_main_menu() {
    local choice
    
    while true; do
        show_main_menu
        
        echo ""
        read -p "$(echo -e "${BOLD_WHITE}Nhập lựa chọn [0-10]: ${NC}")" choice
        
        case "$choice" in
            1) handle_system_menu ;;
            2) handle_php_menu ;;
            3) handle_nginx_menu ;;
            4) handle_database_menu ;;
            5) handle_website_menu ;;
            6) handle_ssl_menu ;;
            7) handle_security_menu ;;
            8) handle_backup_menu ;;
            9) handle_deploy_menu ;;
            10) handle_extras_menu ;;
            0)
                clear_screen
                echo ""
                print_success "Cảm ơn bạn đã sử dụng Ozi Script!"
                echo ""
                exit 0
                ;;
            *)
                print_error "Lựa chọn không hợp lệ"
                sleep 1
                ;;
        esac
    done
}

# Placeholder handlers cho các submenu (sẽ được implement sau)
    while true; do
        menu_system_info
        echo ""
        read -p "$(echo -e "${BOLD_WHITE}Nhập lựa chọn [0-8]: ${NC}")" choice
        
        source "$OZI_DIR/modules/system/info.sh"
        source "$OZI_DIR/modules/system/swap.sh"

        case "$choice" in
            1) show_system_overview; wait_enter ;;
            2) show_cpu_info; wait_enter ;;
            3) show_ram_info; wait_enter ;;
            4) show_disk_info; wait_enter ;;
            5) change_hostname; wait_enter ;;
            6) change_timezone; wait_enter ;;
            7) manage_swap_interactive ;;
            8)
                source "$OZI_DIR/modules/system/update.sh"
                update_script
                wait_enter
                ;;
            0) return ;;
            *) print_error "Lựa chọn không hợp lệ"; sleep 1 ;;
        esac
    done
}

handle_php_menu() {
    while true; do
        menu_php
        echo ""
        read -p "$(echo -e "${BOLD_WHITE}Nhập lựa chọn [0-6]: ${NC}")" choice
        
        source "$OZI_DIR/modules/stack/php.sh"

        case "$choice" in
            1) install_php_interactive; wait_enter ;;
            2) list_php_versions; wait_enter ;;
            3)
                local version=$(read_input "Nhập version PHP (vd: 8.3)")
                set_default_php "$version"
                wait_enter
                ;;
            4)
                local version=$(read_input "Nhập version PHP muốn gỡ (vd: 8.3)")
                remove_php "$version"
                wait_enter
                ;;
            5)
                local version=$(read_input "Nhập version PHP (để trống chọn default)" "")
                edit_php_ini "$version"
                wait_enter
                ;;
            6)
                local version=$(read_input "Nhập version PHP (vd: 8.3)")
                systemctl restart "php${version}-fpm"
                print_success "Đã khởi động lại PHP-FPM"
                wait_enter
                ;;
            0) return ;;
            *) print_error "Lựa chọn không hợp lệ"; sleep 1 ;;
        esac
    done
}

handle_nginx_menu() {
    while true; do
        menu_nginx
        echo ""
        read -p "$(echo -e "${BOLD_WHITE}Nhập lựa chọn [0-5]: ${NC}")" choice
        
        source "$OZI_DIR/modules/stack/nginx.sh"

        case "$choice" in
            1) install_nginx; wait_enter ;;
            2) show_nginx_status; wait_enter ;;
            3) restart_nginx; wait_enter ;;
            4) test_nginx_config; wait_enter ;;
            5) view_nginx_logs; wait_enter ;;
            0) return ;;
            *) print_error "Lựa chọn không hợp lệ"; sleep 1 ;;
        esac
    done
}

handle_database_menu() {
    while true; do
        menu_database
        echo ""
        read -p "$(echo -e "${BOLD_WHITE}Nhập lựa chọn [0-7]: ${NC}")" choice
        
        source "$OZI_DIR/modules/stack/postgresql.sh"
        source "$OZI_DIR/modules/stack/mysql.sh"
        source "$OZI_DIR/modules/database/admin.sh"
        source "$OZI_DIR/modules/backup/local.sh"

        case "$choice" in
            1) install_postgresql; wait_enter ;;
            2) install_mysql; wait_enter ;;
            3)
                local action=$(read_input "Nhập 'create', 'list' hoặc 'drop'" "list")
                case "$action" in
                    create)
                        local db=$(read_input "Tên Database")
                        create_database "$db"
                        ;;
                    drop)
                        local db=$(read_input "Tên Database")
                        drop_database "$db"
                        ;;
                    *) list_databases ;;
                esac
                wait_enter
                ;;
            4)
                local action=$(read_input "Nhập 'create' hoặc 'list'" "list")
                case "$action" in
                    create)
                        local db=$(read_input "Tên Database")
                        create_mysql_database "$db"
                        ;;
                    *) list_mysql_databases ;;
                esac
                wait_enter
                ;;
            5) install_adminer; wait_enter ;;
            6) create_db_backup; wait_enter ;;
            7) restore_backup; wait_enter ;;
            0) return ;;
            *) print_error "Lựa chọn không hợp lệ"; sleep 1 ;;
        esac
    done
}

handle_website_menu() {
    while true; do
        menu_website
        echo ""
        read -p "$(echo -e "${BOLD_WHITE}Nhập lựa chọn [0-5]: ${NC}")" choice
        
        source "$OZI_DIR/modules/site/manage.sh"

        case "$choice" in
            1) create_site_interactive; wait_enter ;;
            2) list_sites; wait_enter ;;
            3)
                local domain=$(read_input "Nhập domain cần xoá")
                delete_site "$domain"
                wait_enter
                ;;
            4)
                local action=$(read_input "Nhập 'enable' hoặc 'disable'" "enable")
                local domain=$(read_input "Nhập domain")
                if [[ "$action" == "disable" ]]; then
                    disable_site "$domain"
                else
                    enable_site "$domain"
                fi
                wait_enter
                ;;
            5) view_site_logs; wait_enter ;;
            0) return ;;
            *) print_error "Lựa chọn không hợp lệ"; sleep 1 ;;
        esac
    done
}

handle_ssl_menu() {
    while true; do
        menu_ssl
        echo ""
        read -p "$(echo -e "${BOLD_WHITE}Nhập lựa chọn [0-5]: ${NC}")" choice
        
        source "$OZI_DIR/modules/site/cloudflare.sh"
        source "$OZI_DIR/modules/site/letsencrypt.sh"

        case "$choice" in
            1) install_cloudflare_ssl_interactive; wait_enter ;;
            2) install_letsencrypt_ssl; wait_enter ;;
            3) list_ssl_certs; wait_enter ;;
            4) renew_ssl_certs; wait_enter ;;
            5) configure_cloudflare_api; wait_enter ;;
            0) return ;;
            *) print_error "Lựa chọn không hợp lệ"; sleep 1 ;;
        esac
    done
}

handle_security_menu() {
    while true; do
        menu_security
        echo ""
        read -p "$(echo -e "${BOLD_WHITE}Nhập lựa chọn [0-7]: ${NC}")" choice
        
        source "$OZI_DIR/modules/security/firewall.sh"
        source "$OZI_DIR/modules/security/ssh.sh"
        source "$OZI_DIR/modules/security/fail2ban.sh"

        case "$choice" in
            1) install_firewall; wait_enter ;;
            2) manage_ports_interactive ;;
            3) add_ssh_key; wait_enter ;;
            4) disable_root_login; wait_enter ;;
            5) change_ssh_port; wait_enter ;;
            6) install_fail2ban; wait_enter ;;
            7) auto_harden_ssh; wait_enter ;;
            0) return ;;
            *) print_error "Lựa chọn không hợp lệ"; sleep 1 ;;
        esac
    done
}

handle_backup_menu() {
    while true; do
        menu_backup
        echo ""
        read -p "$(echo -e "${BOLD_WHITE}Nhập lựa chọn [0-6]: ${NC}")" choice
        
        source "$OZI_DIR/modules/backup/local.sh"

        case "$choice" in
            1) create_full_backup; wait_enter ;;
            2) create_db_backup; wait_enter ;;
            3) list_backups; wait_enter ;;
            4) restore_backup ""; wait_enter ;;
            5) print_warning "Chức năng đang phát triển..."; wait_enter ;;
            6) print_warning "Chức năng đang phát triển..."; wait_enter ;;
            0) return ;;
            *) print_error "Lựa chọn không hợp lệ"; sleep 1 ;;
        esac
    done
}

handle_deploy_menu() {
    while true; do
        menu_deploy
        echo ""
        read -p "$(echo -e "${BOLD_WHITE}Nhập lựa chọn [0-4]: ${NC}")" choice
        
        source "$OZI_DIR/modules/deploy/laravel.sh"
        source "$OZI_DIR/modules/deploy/nodejs.sh"
        source "$OZI_DIR/modules/deploy/wordpress.sh"

        case "$choice" in
            1) deploy_laravel_interactive; wait_enter ;;
            2) deploy_nodejs_interactive; wait_enter ;;
            3) install_wordpress_interactive; wait_enter ;;
            4) print_warning "Chức năng đang phát triển..."; wait_enter ;;
            0) return ;;
            *) print_error "Lựa chọn không hợp lệ"; sleep 1 ;;
        esac
    done
}

handle_extras_menu() {
    while true; do
        menu_extras
        echo ""
        read -p "$(echo -e "${BOLD_WHITE}Nhập lựa chọn [0-7]: ${NC}")" choice
        
        source "$OZI_DIR/modules/stack/nodejs.sh"
        source "$OZI_DIR/modules/stack/redis.sh"
        source "$OZI_DIR/modules/stack/supervisor.sh"
        source "$OZI_DIR/modules/stack/composer.sh"
        source "$OZI_DIR/modules/stack/certbot.sh"
        source "$OZI_DIR/modules/stack/ffmpeg.sh"

        case "$choice" in
            1) install_nodejs_interactive; wait_enter ;;
            2) install_redis; wait_enter ;;
            3) install_supervisor; wait_enter ;;
            4) install_pm2; wait_enter ;;
            5) install_composer; wait_enter ;;
            6) install_certbot; wait_enter ;;
            7) install_ffmpeg; wait_enter ;;
            0) return ;;
            *) print_error "Lựa chọn không hợp lệ"; sleep 1 ;;
        esac
    done
}
