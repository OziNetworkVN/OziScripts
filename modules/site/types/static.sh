#!/bin/bash
#================================================================
# Ozi Script - Static Site Handler
# Mô tả: Xử lý tạo và quản lý Static HTML sites
# Phiên bản: 2.0.0
#================================================================

set -euo pipefail

#================================================================
# CREATE STATIC SITE
#================================================================

create_static_site() {
    local domain="$1"
    local root="$2"
    
    print_subheader "Static HTML Configuration"
    
    # Create site entry
    print_info "Đang tạo site entry..."
    create_site_entry "$domain" "static" "" "$root"
    
    # Create directory
    print_info "Đang tạo thư mục..."
    mkdir -p "$root"
    
    # Create sample index.html
    if [[ ! -f "$root/index.html" ]]; then
        cat > "$root/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            text-align: center;
        }
        h1 {
            color: #333;
        }
        p {
            color: #666;
            line-height: 1.6;
        }
    </style>
</head>
<body>
    <h1>🎉 Website đang hoạt động!</h1>
    <p>Chào mừng đến với website của bạn.</p>
    <p>Trang web này được tạo bởi <strong>Ozi Script</strong>.</p>
</body>
</html>
EOF
    fi
    
    # Generate Nginx config
    print_info "Đang tạo Nginx config..."
    generate_nginx_config "$domain" "static" "$root"
    
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
    find "$root" -type d -exec chmod 755 {} \;
    find "$root" -type f -exec chmod 644 {} \;
    
    print_separator
    print_success "✓ Static site created successfully!"
    echo
    print_info "Domain: $domain"
    print_info "Root: $root"
    
    echo
    print_subheader "Next Steps"
    echo "1. Upload your HTML/CSS/JS files to: $root"
    echo "2. Visit: http://$domain"
    echo "3. Install SSL: ozi site ssl install $domain"
}

#================================================================
# EXPORT
#================================================================

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    export -f create_static_site
fi
