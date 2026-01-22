#!/bin/bash
#================================================================
# Ozi Script - Module: Node.js Deploy
# Mô tả: Deploy ứng dụng Node.js với PM2
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"
source "$OZI_DIR/core/config.sh"

#================================================================
# DEPLOY FUNCTIONS
#================================================================

# Deploy Node.js từ Git
deploy_nodejs() {
    local domain="$1"
    local git_url="$2"
    local branch="${3:-main}"
    local port="${4:-3000}"
    
    if [[ -z "$domain" ]] || [[ -z "$git_url" ]]; then
        print_error "Thiếu thông tin domain hoặc Git URL"
        return 1
    fi
    
    local app_dir="$WWW_DIR/$domain"
    
    print_header "DEPLOY NODE.JS: $domain"
    
    # Check NVM
    export NVM_DIR="/opt/nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if ! command_exists node; then
        print_error "Node.js chưa được cài đặt. Vui lòng cài trước."
        return 1
    fi
    
    # Clone or update
    if [[ -d "$app_dir" ]] && [[ -d "$app_dir/.git" ]]; then
        print_info "Đang cập nhật từ Git..."
        cd "$app_dir"
        git fetch origin
        git reset --hard "origin/$branch"
    else
        print_info "Đang clone từ Git..."
        rm -rf "$app_dir"
        git clone -b "$branch" "$git_url" "$app_dir"
        cd "$app_dir"
    fi
    
    # Install dependencies
    print_info "Đang cài đặt dependencies..."
    if [[ -f "package-lock.json" ]]; then
        npm ci
    else
        npm install
    fi
    
    # Build if script exists
    if grep -q '"build"' package.json; then
        print_info "Đang build..."
        npm run build
    fi
    
    # Create .env if not exists
    if [[ ! -f ".env" ]] && [[ -f ".env.example" ]]; then
        cp .env.example .env
        print_warning "Đã tạo .env từ .env.example. Vui lòng cấu hình!"
    fi
    
    # Setup PM2 or Supervisor
    if command_exists pm2; then
        setup_pm2 "$domain" "$app_dir" "$port"
    else
        setup_supervisor_nodejs "$domain" "$app_dir" "$port"
    fi
    
    # Set permissions
    chown -R www-data:www-data "$app_dir"
    
    print_success "Deploy hoàn tất!"
    echo ""
    echo -e "  ${BOLD_CYAN}URL:${NC} http://$domain"
    echo -e "  ${BOLD_CYAN}Port:${NC} $port"
    echo ""
    
    log_info "Deployed Node.js: $domain on port $port"
}

# Setup PM2
setup_pm2() {
    local name="$1"
    local app_dir="$2"
    local port="$3"
    
    print_info "Đang cấu hình PM2..."
    
    # Stop if running
    pm2 delete "$name" 2>/dev/null || true
    
    # Detect start script
    local start_script="npm start"
    if [[ -f "$app_dir/server.js" ]]; then
        start_script="node server.js"
    elif [[ -f "$app_dir/index.js" ]]; then
        start_script="node index.js"
    elif [[ -f "$app_dir/app.js" ]]; then
        start_script="node app.js"
    fi
    
    # Start with PM2
    cd "$app_dir"
    PORT=$port pm2 start --name "$name" "$start_script"
    pm2 save
    
    print_success "PM2 đã được cấu hình"
}

# Setup Supervisor for Node.js
setup_supervisor_nodejs() {
    local name="$1"
    local app_dir="$2"
    local port="$3"
    
    print_info "Đang cấu hình Supervisor..."
    
    cat > "/etc/supervisor/conf.d/${name}.conf" << EOF
[program:${name}]
directory=${app_dir}
command=/usr/local/bin/node ${app_dir}/server.js
environment=PORT="${port}",NODE_ENV="production"
autostart=true
autorestart=true
user=www-data
stdout_logfile=${app_dir}/logs/app.log
stderr_logfile=${app_dir}/logs/error.log
EOF
    
    mkdir -p "$app_dir/logs"
    chown www-data:www-data "$app_dir/logs"
    
    supervisorctl reread
    supervisorctl update
    supervisorctl restart "$name"
    
    print_success "Supervisor đã được cấu hình"
}

# Interactive deploy
deploy_nodejs_interactive() {
    print_header "DEPLOY NODE.JS"
    
    local domain=$(read_input "Nhập domain")
    local git_url=$(read_input "Nhập Git URL")
    local branch=$(read_input "Branch" "main")
    local port=$(read_input "Port" "3000")
    
    deploy_nodejs "$domain" "$git_url" "$branch" "$port"
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-}" in
        new)
            deploy_nodejs_interactive
            ;;
        redeploy)
            local domain="${2:-}"
            local app_dir="$WWW_DIR/$domain"
            if [[ -d "$app_dir/.git" ]]; then
                cd "$app_dir"
                git pull
                npm ci
                npm run build 2>/dev/null || true
                pm2 restart "$domain" 2>/dev/null || supervisorctl restart "$domain"
                print_success "Redeploy hoàn tất!"
            fi
            ;;
        *)
            deploy_nodejs_interactive
            ;;
    esac
fi
