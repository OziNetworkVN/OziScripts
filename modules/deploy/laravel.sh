#!/bin/bash
#================================================================
# Ozi Script - Module: Laravel Deploy
# Mô tả: Deploy ứng dụng Laravel
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"
source "$OZI_DIR/core/config.sh"

#================================================================
# DEPLOY FUNCTIONS
#================================================================

# Deploy Laravel từ Git
deploy_laravel() {
    local domain="$1"
    local git_url="$2"
    local branch="${3:-main}"
    
    if [[ -z "$domain" ]] || [[ -z "$git_url" ]]; then
        print_error "Thiếu thông tin domain hoặc Git URL"
        return 1
    fi
    
    local app_dir="$WWW_DIR/$domain"
    
    print_header "DEPLOY LARAVEL: $domain"
    
    # Check if directory exists
    if [[ -d "$app_dir" ]] && [[ -d "$app_dir/.git" ]]; then
        # Update existing
        print_info "Đang cập nhật từ Git..."
        cd "$app_dir"
        git fetch origin
        git reset --hard "origin/$branch"
    else
        # Fresh clone
        print_info "Đang clone từ Git..."
        rm -rf "$app_dir"
        git clone -b "$branch" "$git_url" "$app_dir"
        cd "$app_dir"
    fi
    
    # Composer install
    print_info "Đang cài đặt Composer dependencies..."
    composer install --no-dev --optimize-autoloader --no-interaction
    
    # NPM build (if package.json exists)
    if [[ -f "package.json" ]]; then
        print_info "Đang build assets..."
        npm ci --silent
        npm run build
    fi
    
    # Create .env if not exists
    if [[ ! -f ".env" ]]; then
        if [[ -f ".env.example" ]]; then
            cp .env.example .env
            php artisan key:generate
            print_warning "Đã tạo .env từ .env.example. Vui lòng cấu hình!"
        else
            print_error "Không tìm thấy .env.example"
        fi
    fi
    
    # Laravel commands
    print_info "Đang tối ưu Laravel..."
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    php artisan migrate --force 2>/dev/null || print_warning "Migration thất bại (có thể chưa có DB)"
    
    # Set permissions
    chown -R www-data:www-data "$app_dir"
    chmod -R 755 "$app_dir"
    chmod -R 775 "$app_dir/storage"
    chmod -R 775 "$app_dir/bootstrap/cache"
    
    # Storage link
    php artisan storage:link 2>/dev/null || true
    
    # Restart services
    print_info "Khởi động lại services..."
    local php_version=$(get_default_php_version)
    systemctl restart "php${php_version}-fpm" 2>/dev/null || true
    
    # Restart Octane if using
    supervisorctl restart "${domain}-octane" 2>/dev/null || true
    
    print_success "Deploy hoàn tất!"
    log_info "Deployed Laravel: $domain from $git_url"
}

# Interactive deploy
deploy_laravel_interactive() {
    print_header "DEPLOY LARAVEL"
    
    local domain=$(read_input "Nhập domain")
    if [[ -z "$domain" ]]; then
        print_error "Domain không được để trống"
        return 1
    fi
    
    local git_url=$(read_input "Nhập Git URL")
    if [[ -z "$git_url" ]]; then
        print_error "Git URL không được để trống"
        return 1
    fi
    
    local branch=$(read_input "Branch" "main")
    
    deploy_laravel "$domain" "$git_url" "$branch"
}

# Quick redeploy (update existing)
redeploy_laravel() {
    local domain="$1"
    local app_dir="$WWW_DIR/$domain"
    
    if [[ ! -d "$app_dir/.git" ]]; then
        print_error "Không phải Git repository: $app_dir"
        return 1
    fi
    
    print_header "REDEPLOY: $domain"
    
    cd "$app_dir"
    
    # Maintenance mode
    php artisan down 2>/dev/null || true
    
    # Git pull
    print_info "Đang cập nhật code..."
    git pull
    
    # Composer
    print_info "Đang cập nhật dependencies..."
    composer install --no-dev --optimize-autoloader --no-interaction
    
    # NPM
    if [[ -f "package.json" ]]; then
        npm ci --silent
        npm run build
    fi
    
    # Laravel optimize
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    php artisan migrate --force 2>/dev/null || true
    
    # Permissions
    chown -R www-data:www-data "$app_dir"
    chmod -R 775 storage bootstrap/cache
    
    # Restart services
    local php_version=$(get_default_php_version)
    systemctl restart "php${php_version}-fpm" 2>/dev/null || true
    supervisorctl restart "${domain}-octane" 2>/dev/null || true
    
    # End maintenance
    php artisan up
    
    print_success "Redeploy hoàn tất!"
    log_info "Redeployed Laravel: $domain"
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-}" in
        new)
            deploy_laravel_interactive
            ;;
        redeploy)
            redeploy_laravel "${2:-}"
            ;;
        *)
            echo "Sử dụng: $0 {new|redeploy [domain]}"
            ;;
    esac
fi
