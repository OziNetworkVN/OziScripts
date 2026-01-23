#!/bin/bash
#================================================================
# Ozi Script - Node.js Site Handler
# Mô tả: Xử lý tạo và quản lý Node.js sites
# Phiên bản: 2.0.0
#================================================================

set -euo pipefail

#================================================================
# CREATE NODEJS SITE
#================================================================

create_nodejs_site() {
    local domain="$1"
    local root="$2"
    
    print_subheader "Node.js Configuration"
    
    # Check if Node.js is installed
    if ! command -v node >/dev/null 2>&1; then
        print_error "Node.js chưa được cài đặt. Vui lòng cài đặt Node.js trước."
        return 1
    fi
    
    # Get application port
    echo
    read -p "$(echo -e "${BOLD_WHITE}Application port [3000]: ${NC}")" app_port
    app_port="${app_port:-3000}"
    
    # Check if port is available
    if ! check_port_available "$app_port" 2>/dev/null; then
        print_error "Port $app_port đã được sử dụng"
        return 1
    fi
    
    # Database configuration
    echo
    if confirm "Tạo MySQL database?"; then
        local db_name="node_$(echo $domain | tr '.' '_')"
        local db_user="node_$(echo $domain | tr '.' '_' | cut -c1-16)"
        local db_pass="$(openssl rand -base64 16)"
        
        print_info "Đang tạo database..."
        mysql -e "CREATE DATABASE IF NOT EXISTS \`$db_name\`;" 2>/dev/null || true
        mysql -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass';" 2>/dev/null || true
        mysql -e "GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$db_user'@'localhost';" 2>/dev/null || true
        mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true
        
        print_success "✓ Database created: $db_name"
        
        # Save credentials
        mkdir -p "/root/.oziscript/db-credentials"
        cat > "/root/.oziscript/db-credentials/$domain.txt" <<EOF
Database: $db_name
User: $db_user
Password: $db_pass
EOF
        chmod 600 "/root/.oziscript/db-credentials/$domain.txt"
    else
        local db_name=""
        local db_user=""
        local db_type="none"
    fi
    
    # Create site entry
    print_info "Đang tạo site entry..."
    create_site_entry "$domain" "nodejs" "" "$root"
    
    # Update database info
    if [[ -n "$db_name" ]]; then
        update_site_database "$domain" "$db_name" "$db_user" "mysql"
    fi
    
    # Store port
    enable_site_feature "$domain" "nodejs"
    update_site_field "$domain" "features.nodejs_port" "$app_port"
    
    # Create directory
    print_info "Đang tạo thư mục..."
    mkdir -p "$root"
    
    # Create sample package.json if needed
    if [[ ! -f "$root/package.json" ]]; then
        cat > "$root/package.json" <<'EOF'
{
  "name": "nodejs-app",
  "version": "1.0.0",
  "description": "Node.js application",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  }
}
EOF
    fi
    
    # Create sample index.js if needed
    if [[ ! -f "$root/index.js" ]]; then
        cat > "$root/index.js" <<EOF
const http = require('http');

const server = http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'text/html'});
  res.end('<h1>Hello from Node.js!</h1><p>Your application is running.</p>');
});

const PORT = process.env.PORT || $app_port;
server.listen(PORT, () => {
  console.log(\`Server running on port \${PORT}\`);
});
EOF
    fi
    
    # Generate Nginx config
    print_info "Đang tạo Nginx config..."
    generate_nginx_config "$domain" "nodejs" "$app_port" "$root"
    
    # Test and reload Nginx
    if test_nginx_config >/dev/null 2>&1; then
        reload_nginx
        print_success "✓ Nginx config loaded"
    else
        print_error "✗ Nginx config test failed"
        return 1
    fi
    
    # Set permissions
    print_info "Đang thiết lập quyền..."
    chown -R www-data:www-data "$root"
    
    # Setup PM2 if available
    if command -v pm2 >/dev/null 2>&1; then
        if confirm "Chạy ứng dụng với PM2?"; then
            cd "$root"
            pm2 start index.js --name "$domain" || true
            pm2 save || true
            print_success "✓ Application started with PM2"
            enable_site_feature "$domain" "pm2"
        fi
    fi
    
    print_separator
    print_success "✓ Node.js site created successfully!"
    echo
    print_info "Domain: $domain"
    print_info "Root: $root"
    print_info "Port: $app_port"
    
    if [[ -n "$db_name" ]]; then
        echo
        print_subheader "Database Credentials"
        print_info "Database: $db_name"
        print_info "User: $db_user"
        print_info "Password: $db_pass"
        print_info "Saved to: /root/.oziscript/db-credentials/$domain.txt"
    fi
    
    echo
    print_subheader "Next Steps"
    echo "1. Upload your Node.js code to: $root"
    echo "2. Install dependencies: cd $root && npm install"
    echo "3. Start application: node index.js (or use PM2)"
    echo "4. Install SSL: ozi site ssl install $domain"
    
    if command -v pm2 >/dev/null 2>&1; then
        echo
        print_info "PM2 Commands:"
        echo "  pm2 list                 - List applications"
        echo "  pm2 restart $domain      - Restart app"
        echo "  pm2 logs $domain         - View logs"
    fi
}

#================================================================
# EXPORT
#================================================================

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    export -f create_nodejs_site
fi
