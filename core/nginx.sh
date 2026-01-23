#!/bin/bash
#================================================================
# Ozi Script - Dynamic Nginx Config Generator
# Mô tả: Tạo cấu hình Nginx thông minh theo loại site
# Phiên bản: 2.0.0
#================================================================

set -euo pipefail

# Load dependencies
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh" 2>/dev/null || true
source "$OZI_DIR/core/colors.sh" 2>/dev/null || true
source "$OZI_DIR/core/site-db.sh" 2>/dev/null || true

#================================================================
# CONFIGURATION
#================================================================
NGINX_AVAILABLE="/etc/nginx/sites-available"
NGINX_ENABLED="/etc/nginx/sites-enabled"
TEMPLATE_DIR="$OZI_DIR/templates/nginx"

#================================================================
# HELPER FUNCTIONS
#================================================================

# Validate domain name
validate_domain() {
    local domain="$1"
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 1
    fi
    return 0
}

# Check if Nginx config is valid
test_nginx_config() {
    nginx -t 2>&1
}

# Reload Nginx
reload_nginx() {
    systemctl reload nginx 2>&1
}

#================================================================
# LARAVEL CONFIG GENERATOR
#================================================================

generate_laravel_config() {
    local domain="$1"
    local root="$2"
    local php_version="$3"
    local use_octane="${4:-false}"
    local octane_port="${5:-8000}"
    
    local php_socket="/run/php/php${php_version}-fpm.sock"
    local public_root="$root/public"
    
    cat > "$NGINX_AVAILABLE/${domain}.conf" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain;
    
    root $public_root;
    index index.php index.html;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # Logging
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
    
    # Character set
    charset utf-8;
EOF

    if [[ "$use_octane" == "true" ]]; then
        cat >> "$NGINX_AVAILABLE/${domain}.conf" <<EOF
    
    # Laravel Octane proxy
    location / {
        try_files \$uri \$uri/ @octane;
    }
    
    location @octane {
        proxy_http_version 1.1;
        proxy_set_header Host \$http_host;
        proxy_set_header Scheme \$scheme;
        proxy_set_header SERVER_PORT \$server_port;
        proxy_set_header REMOTE_ADDR \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_pass http://127.0.0.1:$octane_port;
    }
EOF
    else
        cat >> "$NGINX_AVAILABLE/${domain}.conf" <<EOF
    
    # Laravel rewrite rules
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    # PHP-FPM
    location ~ \.php$ {
        fastcgi_pass unix:$php_socket;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }
EOF
    fi
    
    cat >> "$NGINX_AVAILABLE/${domain}.conf" <<EOF
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
    
    # Deny access to sensitive files
    location ~ /(\.env|\.git|composer\.json|composer\.lock|package\.json|artisan) {
        deny all;
    }
    
    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF
}

#================================================================
# WORDPRESS CONFIG GENERATOR
#================================================================

generate_wordpress_config() {
    local domain="$1"
    local root="$2"
    local php_version="$3"
    
    local php_socket="/run/php/php${php_version}-fpm.sock"
    
    cat > "$NGINX_AVAILABLE/${domain}.conf" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain;
    
    root $root;
    index index.php index.html;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # Logging
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
    
    # Character set
    charset utf-8;
    
    # WordPress rewrite rules
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    # PHP-FPM
    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:$php_socket;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        
        # WordPress specific
        fastcgi_intercept_errors on;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
    
    # Deny access to WordPress specific files
    location ~* /(wp-config\.php|readme\.html|license\.txt) {
        deny all;
    }
    
    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    # WordPress uploads protection
    location ~* ^/wp-content/uploads/.*\.(php|php5|php7|phtml)$ {
        deny all;
    }
    
    # Disable XML-RPC
    location = /xmlrpc.php {
        deny all;
        access_log off;
    }
}
EOF
}

#================================================================
# NODE.JS CONFIG GENERATOR
#================================================================

generate_nodejs_config() {
    local domain="$1"
    local port="$2"
    local root="${3:-/var/www/$domain}"
    
    cat > "$NGINX_AVAILABLE/${domain}.conf" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # Logging
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
    
    # Character set
    charset utf-8;
    
    # Proxy to Node.js application
    location / {
        proxy_pass http://127.0.0.1:$port;
        proxy_http_version 1.1;
        
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    
    # Static files (if needed)
    location ~* ^/(images|css|js|fonts)/(.+)$ {
        root $root/public;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF
}

#================================================================
# STATIC SITE CONFIG GENERATOR
#================================================================

generate_static_config() {
    local domain="$1"
    local root="$2"
    
    cat > "$NGINX_AVAILABLE/${domain}.conf" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain;
    
    root $root;
    index index.html index.htm;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # Logging
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
    
    # Character set
    charset utf-8;
    
    # Static file serving
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
    
    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot|webp)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF
}

#================================================================
# SSL CONFIGURATION
#================================================================

add_ssl_to_config() {
    local domain="$1"
    local cert_path="$2"
    local key_path="$3"
    local config_file="$NGINX_AVAILABLE/${domain}.conf"
    
    # Check if SSL already configured
    if grep -q "ssl_certificate" "$config_file"; then
        return 0
    fi
    
    # Add SSL listener
    sed -i '/listen 80;/a\    listen 443 ssl http2;\n    listen [::]:443 ssl http2;' "$config_file"
    
    # Add SSL certificates
    sed -i "/server_name $domain;/a\    \n    # SSL Configuration\n    ssl_certificate $cert_path;\n    ssl_certificate_key $key_path;\n    ssl_protocols TLSv1.2 TLSv1.3;\n    ssl_ciphers HIGH:!aNULL:!MD5;\n    ssl_prefer_server_ciphers on;\n    ssl_session_cache shared:SSL:10m;\n    ssl_session_timeout 10m;" "$config_file"
    
    # Add HTTP to HTTPS redirect
    cat >> "$config_file" <<EOF

# HTTP to HTTPS redirect
server {
    listen 80;
    listen [::]:80;
    server_name $domain;
    return 301 https://\$server_name\$request_uri;
}
EOF
}

#================================================================
# DOMAIN ALIAS MANAGEMENT
#================================================================

add_alias_to_config() {
    local domain="$1"
    local alias="$2"
    local config_file="$NGINX_AVAILABLE/${domain}.conf"
    
    # Check if alias already exists
    if grep -q "server_name.*$alias" "$config_file"; then
        return 0
    fi
    
    # Add alias to server_name
    sed -i "s/server_name $domain;/server_name $domain $alias;/" "$config_file"
}

remove_alias_from_config() {
    local domain="$1"
    local alias="$2"
    local config_file="$NGINX_AVAILABLE/${domain}.conf"
    
    # Remove alias from server_name
    sed -i "s/ $alias//" "$config_file"
    sed -i "s/$alias //" "$config_file"
}

#================================================================
# MAIN GENERATOR
#================================================================

generate_nginx_config() {
    local domain="$1"
    local type="$2"
    shift 2
    
    # Validate domain
    if ! validate_domain "$domain"; then
        echo "ERROR: Invalid domain name" >&2
        return 1
    fi
    
    # Create directories if needed
    mkdir -p "$NGINX_AVAILABLE" "$NGINX_ENABLED"
    
    # Generate based on type
    case "$type" in
        laravel)
            local root="$1"
            local php_version="$2"
            local use_octane="${3:-false}"
            local octane_port="${4:-8000}"
            generate_laravel_config "$domain" "$root" "$php_version" "$use_octane" "$octane_port"
            ;;
        wordpress)
            local root="$1"
            local php_version="$2"
            generate_wordpress_config "$domain" "$root" "$php_version"
            ;;
        nodejs)
            local port="$1"
            local root="${2:-/var/www/$domain}"
            generate_nodejs_config "$domain" "$port" "$root"
            ;;
        static)
            local root="$1"
            generate_static_config "$domain" "$root"
            ;;
        *)
            echo "ERROR: Unknown site type: $type" >&2
            return 1
            ;;
    esac
    
    # Enable site
    if [[ ! -L "$NGINX_ENABLED/${domain}.conf" ]]; then
        ln -sf "$NGINX_AVAILABLE/${domain}.conf" "$NGINX_ENABLED/${domain}.conf"
    fi
    
    return 0
}

#================================================================
# CONFIG MANAGEMENT
#================================================================

enable_site() {
    local domain="$1"
    
    if [[ ! -f "$NGINX_AVAILABLE/${domain}.conf" ]]; then
        echo "ERROR: Config file not found" >&2
        return 1
    fi
    
    ln -sf "$NGINX_AVAILABLE/${domain}.conf" "$NGINX_ENABLED/${domain}.conf"
}

disable_site() {
    local domain="$1"
    
    if [[ -L "$NGINX_ENABLED/${domain}.conf" ]]; then
        rm -f "$NGINX_ENABLED/${domain}.conf"
    fi
}

delete_site_config() {
    local domain="$1"
    
    # Disable first
    disable_site "$domain"
    
    # Delete config
    if [[ -f "$NGINX_AVAILABLE/${domain}.conf" ]]; then
        rm -f "$NGINX_AVAILABLE/${domain}.conf"
    fi
}

#================================================================
# EXPORT
#================================================================

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    export -f generate_nginx_config
    export -f add_ssl_to_config
    export -f add_alias_to_config
    export -f remove_alias_from_config
    export -f enable_site
    export -f disable_site
    export -f delete_site_config
    export -f test_nginx_config
    export -f reload_nginx
fi
