# OZI SCRIPT - KIẾN TRÚC TỐI ƯU HÓA V2.0

## 📋 Phân tích vấn đề hiện tại

### ❌ Vấn đề:

1. **Module rời rạc**: `site/manage.sh`, `site/cloudflare.sh`, `site/letsencrypt.sh` không liên kết
2. **Không có database trung tâm**: Không track sites, SSL expiry, domain aliases
3. **Nginx config thủ công**: Templates tĩnh, không linh hoạt
4. **SSL management phức tạp**: User phải nhớ domain nào dùng SSL gì
5. **Domain alias đơn giản**: Chỉ copy config, không quản lý lifecycle
6. **Deploy thiếu tích hợp**: Laravel deploy không tự động config Nginx + SSL

---

## 🎯 Kiến trúc mới - V2.0

### 1. **Site Database (Central Registry)**

File: `/etc/oziscript/sites.db` (JSON format)

```json
{
  "sites": {
    "example.com": {
      "id": "site_001",
      "domain": "example.com",
      "type": "laravel",
      "status": "active",
      "created_at": "2026-01-20T10:00:00Z",
      "root": "/var/www/example.com",
      "php_version": "8.3",
      "nginx_config": "/etc/nginx/sites-available/example.com.conf",
      "ssl": {
        "enabled": true,
        "type": "cloudflare",
        "cert_path": "/etc/ssl/oziscript/example.com/cert.pem",
        "key_path": "/etc/ssl/oziscript/example.com/key.pem",
        "expires_at": "2041-01-20T10:00:00Z",
        "auto_renew": false
      },
      "aliases": [
        "www.example.com",
        "app.example.com"
      ],
      "database": {
        "name": "example_db",
        "user": "example_user",
        "type": "mysql"
      },
      "features": {
        "laravel_octane": true,
        "queue_worker": true,
        "scheduler": true
      }
    }
  }
}
```

### 2. **Unified Site CLI**

```bash
# Tạo site với wizard đầy đủ
ozi site create
  → Nhập domain
  → Chọn loại (Laravel/WordPress/Node.js/Static)
  → Chọn PHP version (nếu PHP)
  → SSL: Let's Encrypt / Cloudflare / Custom / None
  → Database: Tạo mới / Existing / None
  → Deploy code? (Git URL)
  → Done! Site ready với Nginx + SSL + Database

# List sites với thông tin đầy đủ
ozi site list
# Output:
# DOMAIN              TYPE       SSL          PHP    STATUS   EXPIRES
# example.com         Laravel    Cloudflare   8.3    Active   2041-01-20
# blog.com            WordPress  LetsEncrypt  8.2    Active   2026-03-15
# api.myapp.com       Node.js    Custom       -      Active   2026-12-01

# Quản lý SSL cho site cụ thể
ozi site ssl example.com
  → [1] Renew SSL
  → [2] Change SSL type (Cloudflare → Let's Encrypt)
  → [3] View certificate info
  → [4] Force HTTPS
  → [5] Remove SSL

# Quản lý domain alias
ozi site alias example.com
  → [1] Add alias (www.example.com)
  → [2] Remove alias
  → [3] List aliases

# Xem chi tiết site
ozi site info example.com
# Output:
# Domain: example.com
# Type: Laravel 11
# PHP: 8.3-FPM
# Root: /var/www/example.com/public
# Nginx: /etc/nginx/sites-available/example.com.conf
# SSL: Cloudflare Origin Certificate (expires: 2041-01-20)
# Aliases: www.example.com, app.example.com
# Database: example_db (MySQL 8.0)
# Features: Octane ✓, Queue ✓, Scheduler ✓

# Xóa site hoàn toàn
ozi site delete example.com
  → Confirm xóa
  → Xóa Nginx config
  → Xóa SSL certificates
  → Hỏi xóa database? (y/n)
  → Hỏi xóa files? (y/n)
  → Done!

# Reload/restart site
ozi site reload example.com
ozi site restart example.com
```

### 3. **Smart Nginx Config Generator**

File: `core/nginx.sh`

```bash
# Generate nginx config động dựa trên site type
generate_nginx_config() {
    local domain="$1"
    local type="$2"
    local php_version="$3"
    local ssl_enabled="$4"
    local root="$5"
    
    # Base config
    local config="server {
    listen 80;
    server_name $domain;"
    
    # SSL
    if [[ "$ssl_enabled" == "true" ]]; then
        config+="
    listen 443 ssl http2;
    ssl_certificate /etc/ssl/oziscript/$domain/cert.pem;
    ssl_certificate_key /etc/ssl/oziscript/$domain/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;"
    fi
    
    # Root directory
    config+="
    root $root;
    index index.php index.html;"
    
    # Type-specific rules
    case "$type" in
        laravel)
            config+="
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location ~ \\.php$ {
        fastcgi_pass unix:/var/run/php/php${php_version}-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }"
            ;;
        wordpress)
            config+="
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    location ~ \\.php$ {
        fastcgi_pass unix:/var/run/php/php${php_version}-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }"
            ;;
        nodejs)
            config+="
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }"
            ;;
    esac
    
    config+="
}"
    
    echo "$config"
}
```

### 4. **SSL Lifecycle Manager**

File: `modules/site/ssl-manager.sh`

```bash
# Check SSL expiry cho tất cả sites
check_ssl_expiry() {
    local sites=$(get_all_sites)
    local expiring_soon=()
    
    for site in $sites; do
        local ssl_info=$(get_site_ssl "$site")
        local expires_at=$(echo "$ssl_info" | jq -r '.expires_at')
        local days_left=$(calculate_days_left "$expires_at")
        
        if [[ $days_left -lt 30 ]]; then
            expiring_soon+=("$site: $days_left days")
        fi
    done
    
    if [[ ${#expiring_soon[@]} -gt 0 ]]; then
        print_warning "SSL certificates expiring soon:"
        printf '%s\n' "${expiring_soon[@]}"
    fi
}

# Auto-renew SSL (chạy bằng cron)
auto_renew_ssl() {
    local sites=$(get_all_sites)
    
    for site in $sites; do
        local ssl_type=$(get_site_ssl_type "$site")
        local auto_renew=$(get_site_auto_renew "$site")
        
        if [[ "$auto_renew" == "true" ]]; then
            case "$ssl_type" in
                letsencrypt)
                    certbot renew --cert-name "$site"
                    ;;
                cloudflare)
                    # Cloudflare 15 năm, không cần renew
                    ;;
            esac
        fi
    done
}
```

### 5. **Site Type Handlers**

#### Laravel Handler: `modules/site/types/laravel.sh`

```bash
deploy_laravel() {
    local domain="$1"
    local git_url="$2"
    local branch="$3"
    
    # Clone repository
    git clone -b "$branch" "$git_url" "/var/www/$domain"
    cd "/var/www/$domain"
    
    # Install dependencies
    composer install --no-dev --optimize-autoloader
    
    # Environment
    cp .env.example .env
    php artisan key:generate
    
    # Setup database
    local db_name=$(get_site_database "$domain")
    update_env "DB_DATABASE" "$db_name"
    php artisan migrate --force
    
    # Permissions
    chown -R www-data:www-data storage bootstrap/cache
    chmod -R 775 storage bootstrap/cache
    
    # Optimize
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    
    # Octane detection
    if [[ -f "artisan" ]] && php artisan list | grep -q "octane:start"; then
        setup_octane "$domain"
    fi
    
    # Queue worker
    if confirm "Setup queue worker?"; then
        setup_queue_worker "$domain"
    fi
    
    # Scheduler
    setup_scheduler "$domain"
}

setup_octane() {
    local domain="$1"
    
    # Supervisor config for Octane
    cat > "/etc/supervisor/conf.d/${domain}-octane.conf" << EOF
[program:${domain}-octane]
command=php /var/www/${domain}/artisan octane:start --host=127.0.0.1 --port=8000
user=www-data
autostart=true
autorestart=true
EOF
    
    supervisorctl reread
    supervisorctl update
    
    # Update Nginx to proxy to Octane
    update_site_config "$domain" "octane" "true"
    regenerate_nginx_config "$domain"
}
```

#### WordPress Handler: `modules/site/types/wordpress.sh`

```bash
deploy_wordpress() {
    local domain="$1"
    local admin_user="$2"
    local admin_pass="$3"
    local admin_email="$4"
    
    # Download WordPress
    cd "/var/www"
    wp core download --path="$domain" --allow-root
    
    # wp-config
    local db_name=$(get_site_database "$domain")
    local db_user=$(get_site_db_user "$domain")
    local db_pass=$(get_site_db_pass "$domain")
    
    cd "$domain"
    wp config create \
        --dbname="$db_name" \
        --dbuser="$db_user" \
        --dbpass="$db_pass" \
        --allow-root
    
    # Install
    wp core install \
        --url="https://$domain" \
        --title="$domain" \
        --admin_user="$admin_user" \
        --admin_password="$admin_pass" \
        --admin_email="$admin_email" \
        --allow-root
    
    # Permissions
    chown -R www-data:www-data .
    find . -type d -exec chmod 755 {} \;
    find . -type f -exec chmod 644 {} \;
    
    # Recommended plugins
    if confirm "Install recommended plugins?"; then
        wp plugin install wp-super-cache redis-cache --activate --allow-root
    fi
}
```

### 6. **Database Integration**

File: `core/site-db.sh`

```bash
# CRUD operations for site database

# Create site entry
create_site() {
    local domain="$1"
    local type="$2"
    local php_version="$3"
    
    local site_data=$(cat <<EOF
{
  "id": "site_$(date +%s)",
  "domain": "$domain",
  "type": "$type",
  "status": "active",
  "created_at": "$(date -Iseconds)",
  "root": "/var/www/$domain",
  "php_version": "$php_version",
  "nginx_config": "/etc/nginx/sites-available/${domain}.conf",
  "ssl": {
    "enabled": false
  },
  "aliases": []
}
EOF
)
    
    # Add to database
    jq ".sites[\"$domain\"] = $site_data" /etc/oziscript/sites.db > /tmp/sites.db.tmp
    mv /tmp/sites.db.tmp /etc/oziscript/sites.db
}

# Get site info
get_site() {
    local domain="$1"
    jq -r ".sites[\"$domain\"]" /etc/oziscript/sites.db
}

# Update site
update_site() {
    local domain="$1"
    local field="$2"
    local value="$3"
    
    jq ".sites[\"$domain\"].$field = \"$value\"" /etc/oziscript/sites.db > /tmp/sites.db.tmp
    mv /tmp/sites.db.tmp /etc/oziscript/sites.db
}

# List all sites
list_sites() {
    jq -r '.sites | to_entries[] | "\(.key)\t\(.value.type)\t\(.value.ssl.enabled)\t\(.value.php_version)\t\(.value.status)"' /etc/oziscript/sites.db
}

# Delete site
delete_site() {
    local domain="$1"
    jq "del(.sites[\"$domain\"])" /etc/oziscript/sites.db > /tmp/sites.db.tmp
    mv /tmp/sites.db.tmp /etc/oziscript/sites.db
}
```

---

## 📦 Cấu trúc module mới

```
modules/
├── site/
│   ├── manager.sh          # Main site management (create, delete, list)
│   ├── ssl-manager.sh      # SSL lifecycle management
│   ├── nginx-builder.sh    # Dynamic Nginx config generator
│   ├── types/
│   │   ├── laravel.sh      # Laravel deployment handler
│   │   ├── wordpress.sh    # WordPress deployment handler
│   │   ├── nodejs.sh       # Node.js deployment handler
│   │   └── static.sh       # Static site handler
│   └── utils/
│       ├── domain.sh       # Domain validation, alias management
│       └── database.sh     # Database creation for sites
├── ssl/
│   ├── letsencrypt.sh      # Let's Encrypt integration
│   ├── cloudflare.sh       # Cloudflare Origin Cert
│   └── custom.sh           # Custom SSL upload
└── deploy/
    ├── git.sh              # Git deployment
    └── ftp.sh              # FTP deployment (future)

core/
├── site-db.sh              # Site database CRUD
├── nginx.sh                # Nginx helpers
└── validators.sh           # Input validation
```

---

## 🔄 User Flow Mới

### Example: Tạo Laravel site

```bash
$ ozi site create

╔════════════════════════════════════════════════════════════════╗
║                    TẠO WEBSITE MỚI                             ║
╚════════════════════════════════════════════════════════════════╝

Nhập domain: laravel-app.com

Chọn loại website:
  [1] Laravel
  [2] WordPress
  [3] Node.js
  [4] Static HTML
Chọn [1-4]: 1

Chọn PHP version:
  [1] PHP 8.4
  [2] PHP 8.3
  [3] PHP 8.2
Chọn [1-3]: 1

Cấu hình SSL:
  [1] Let's Encrypt (Auto-renew, miễn phí)
  [2] Cloudflare Origin Certificate (15 năm)
  [3] Custom SSL (upload cert/key)
  [4] Không dùng SSL
Chọn [1-4]: 2

Cloudflare API Token: W12hhWtwN_M3hAAhwIFpK5rXXlXe2XPbiN6KkDSB
✓ Token hợp lệ

Database:
  [1] Tạo database mới (MySQL)
  [2] Tạo database mới (PostgreSQL)
  [3] Sử dụng database có sẵn
  [4] Không cần database
Chọn [1-4]: 1

Database name [laravel_app_db]: 
Database user [laravel_user]: 
Database password (auto-generate): 

Deploy source code:
  [1] Clone từ Git repository
  [2] Upload qua FTP/SFTP sau
Chọn [1-2]: 1

Git URL: https://github.com/user/laravel-app.git
Branch [main]: 

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Đang tạo website...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Tạo thư mục /var/www/laravel-app.com
✓ Clone repository
✓ Cài đặt Composer dependencies
✓ Tạo database: laravel_app_db
✓ Tạo .env và generate key
✓ Chạy migrations
✓ Tạo Cloudflare SSL certificate (expires: 2041-01-23)
✓ Generate Nginx config
✓ Activate Nginx config
✓ Reload Nginx
✓ Set permissions
✓ Phát hiện Laravel Octane → Setup Supervisor
✓ Setup Queue Worker
✓ Setup Scheduler (cron)
✓ Cache config/routes/views

╔════════════════════════════════════════════════════════════════╗
║                    WEBSITE ĐÃ SẴN SÀNG!                        ║
╚════════════════════════════════════════════════════════════════╝

Domain: https://laravel-app.com
Type: Laravel 11 (Octane)
PHP: 8.4-FPM
Database: laravel_app_db (user: laravel_user)
SSL: Cloudflare Origin (expires: 2041-01-23)

Admin URL: https://laravel-app.com/admin

Quản lý website:
  ozi site info laravel-app.com
  ozi site ssl laravel-app.com
  ozi site alias laravel-app.com
  ozi site delete laravel-app.com
```

---

## 🚀 Roadmap Implementation

### Phase 1: Core Foundation (Week 1)
- [x] Site database structure (`core/site-db.sh`)
- [ ] Basic CRUD operations
- [ ] Unified CLI command structure
- [ ] Migration tool (import existing sites)

### Phase 2: Site Management (Week 2)
- [ ] `ozi site create` wizard
- [ ] `ozi site list` with table format
- [ ] `ozi site info` detailed view
- [ ] `ozi site delete` with cleanup

### Phase 3: Nginx Integration (Week 3)
- [ ] Dynamic Nginx config generator
- [ ] Type-specific templates
- [ ] Auto-detect PHP-FPM socket
- [ ] Config validation

### Phase 4: SSL Management (Week 4)
- [ ] SSL lifecycle tracking
- [ ] Auto-renew for Let's Encrypt
- [ ] Expiry warnings (email/CLI)
- [ ] `ozi site ssl` subcommands

### Phase 5: Type Handlers (Week 5-6)
- [ ] Laravel handler (Octane, Queue, Scheduler)
- [ ] WordPress handler (WP-CLI integration)
- [ ] Node.js handler (PM2 integration)
- [ ] Static site handler

### Phase 6: Polish & Testing (Week 7)
- [ ] Integration testing
- [ ] Migration from V1 to V2
- [ ] Documentation update
- [ ] User feedback

---

## 💡 Ưu điểm so với hiện tại

| Tính năng | Hiện tại (V1) | Mới (V2) |
|-----------|---------------|----------|
| **Site tracking** | ❌ Không có | ✅ Central database |
| **SSL management** | ⚠️ Thủ công, rời rạc | ✅ Lifecycle, auto-renew |
| **Nginx config** | ⚠️ Templates tĩnh | ✅ Dynamic generation |
| **Domain alias** | ⚠️ Copy config thủ công | ✅ Quản lý tập trung |
| **Deploy integration** | ❌ Riêng biệt | ✅ Tích hợp trong create |
| **Site info** | ❌ Phải check thủ công | ✅ `ozi site info` |
| **Cleanup** | ⚠️ Xóa thủ công từng phần | ✅ `ozi site delete` all-in-one |
| **SSL expiry** | ❌ Không track | ✅ Auto-check, warnings |
| **Type-specific** | ❌ Generic | ✅ Laravel/WP/Node handlers |

---

## 🎓 Học hỏi từ các script khác

### VPSSim
- ✅ Menu-driven, dễ sử dụng
- ✅ Site database với `/etc/vpssim/sites.txt`
- ✅ SSL auto-renew tracking

### DLEMP
- ✅ Nginx config templates cho từng CMS
- ✅ PHP version switching per-site
- ✅ Database backup tự động

### aaPanel
- ✅ Web UI + CLI
- ✅ Site monitoring (uptime, resources)
- ✅ One-click deploy từ Git

---

## ✅ Action Plan

Bạn có muốn tôi bắt đầu implement kiến trúc V2 này không? Tôi sẽ:

1. **Tạo `core/site-db.sh`** - Site database foundation
2. **Refactor `modules/site/manager.sh`** - Unified site management
3. **Tạo `core/nginx.sh`** - Dynamic Nginx config generator
4. **Update CLI** - New command structure

Hoặc bạn muốn review/điều chỉnh kiến trúc trước?
