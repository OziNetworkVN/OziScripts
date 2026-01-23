# Ozi Script V2 - Site Management Architecture

## 🎯 Tổng Quan

Ozi Script V2 là kiến trúc quản lý website hoàn toàn mới với:
- **Site Database tập trung** (JSON format)
- **Unified CLI** dễ sử dụng
- **Dynamic Nginx config generator**
- **SSL lifecycle manager** tự động
- **Type handlers** cho Laravel/WordPress/Node.js/Static

## 🚀 Cài Đặt

### Cài đặt mới
```bash
git clone https://github.com/OziNetworkVN/OziScripts.git
cd OziScripts
sudo bash install.sh
```

### Nâng cấp từ V1
```bash
cd /opt/oziscript
git pull
sudo bash migrate-v2.sh
```

## 📖 Sử Dụng

### Tạo Website Mới

```bash
# Interactive wizard
ozi site create

# Hỗ trợ 4 loại:
# 1. Laravel (PHP Framework)
# 2. WordPress (CMS) 
# 3. Node.js (JavaScript)
# 4. Static HTML
```

### Quản Lý Sites

```bash
# Liệt kê tất cả sites
ozi site list

# Xem chi tiết site
ozi site info example.com

# Xóa site
ozi site delete example.com
```

### Quản Lý SSL

```bash
# Cài SSL (wizard)
ozi site ssl install example.com

# Các loại SSL:
# 1. Let's Encrypt (Free, Auto-renew)
# 2. Cloudflare Origin (15 years)
# 3. Custom SSL (Upload cert/key)

# Xem trạng thái SSL
ozi site ssl status example.com

# Liệt kê tất cả SSL
ozi site ssl list

# Gia hạn Let's Encrypt
ozi site ssl renew example.com

# Auto-renew SSL sắp hết hạn
ozi site ssl auto-renew
```

### Quản Lý Domain Aliases

```bash
# Thêm alias
ozi site alias add example.com www.example.com

# Xem aliases
ozi site alias list example.com

# Xóa alias
ozi site alias remove example.com www.example.com
```

## 🏗️ Kiến Trúc V2

### Site Database
```json
{
  "sites": {
    "example.com": {
      "id": "site_1234567890_abc123",
      "domain": "example.com",
      "type": "laravel",
      "status": "active",
      "root": "/var/www/example.com",
      "php_version": "8.3",
      "nginx": {
        "config": "/etc/nginx/sites-available/example.com.conf",
        "enabled": true
      },
      "ssl": {
        "enabled": true,
        "type": "letsencrypt",
        "cert_path": "/etc/letsencrypt/live/example.com/fullchain.pem",
        "key_path": "/etc/letsencrypt/live/example.com/privkey.pem",
        "expires_at": "2026-04-23T10:30:00+07:00",
        "auto_renew": true
      },
      "aliases": ["www.example.com"],
      "database": {
        "name": "db_example_com",
        "user": "user_example",
        "type": "mysql"
      },
      "features": {
        "octane": false
      }
    }
  }
}
```

### Core Modules

#### 1. `core/site-db.sh` - Site Database Manager
- CRUD operations cho sites
- JSON database tại `/etc/oziscript/sites.db`
- Auto-backup trước mỗi thay đổi
- Query functions (by type, SSL status, etc.)

#### 2. `core/nginx.sh` - Dynamic Nginx Generator
- Generate configs theo loại site
- Laravel (PHP-FPM hoặc Octane)
- WordPress (với WP-specific rules)
- Node.js (reverse proxy)
- Static HTML
- Auto-enable/disable sites
- Config validation

#### 3. `core/ssl-manager.sh` - SSL Lifecycle Manager
- Let's Encrypt (auto-renew)
- Cloudflare Origin Certificates
- Custom SSL upload
- Expiry tracking
- Auto-renewal warnings
- Certificate validation

#### 4. `modules/site/manager.sh` - Unified Site Manager
- Single entry point cho tất cả site operations
- Wizard-based site creation
- SSL management commands
- Alias management
- Site deletion với cleanup

#### 5. Type Handlers - `modules/site/types/`
- **laravel.sh**: PHP version selection, Octane support, database auto-create
- **wordpress.sh**: Auto-download WordPress, WP-CLI integration, database setup
- **nodejs.sh**: Port configuration, PM2 integration, reverse proxy
- **static.sh**: Simple HTML serving với caching headers

## 🔄 So Sánh V1 vs V2

| Feature | V1 | V2 |
|---------|----|----|
| Site tracking | Manual Nginx configs | Centralized JSON database |
| SSL management | Separate scripts | Unified SSL manager |
| Domain aliases | Manual Nginx edit | `ozi site alias` command |
| Site creation | Multiple menus | Single `ozi site create` |
| SSL renewal | Manual | Auto-renewal with cron |
| Site info | Parse Nginx files | `ozi site info` command |
| Type support | Basic | Laravel/WordPress/Node.js/Static |
| Database | Manual | Auto-create with site |

## 📁 File Structure

```
/opt/oziscript/
├── ozi                         # Main CLI (V2 integrated)
├── core/
│   ├── site-db.sh              # Site database manager [NEW]
│   ├── nginx.sh                # Dynamic Nginx generator [NEW]
│   ├── ssl-manager.sh          # SSL lifecycle manager [NEW]
│   ├── helpers.sh
│   ├── colors.sh
│   └── config.sh
├── modules/
│   └── site/
│       ├── manager.sh          # Unified site manager [NEW]
│       └── types/              # Type handlers [NEW]
│           ├── laravel.sh
│           ├── wordpress.sh
│           ├── nodejs.sh
│           └── static.sh
├── templates/
│   └── nginx/                  # Nginx config templates
├── cron/
│   └── ssl-auto-renew.sh       # SSL auto-renewal cron [NEW]
└── migrate-v2.sh               # V1→V2 migration tool [NEW]

/etc/oziscript/
├── sites.db                    # Site database (JSON) [NEW]
├── sites.db.backup.*           # Auto-backups [NEW]
└── ssl/                        # SSL certificates [NEW]
    ├── cloudflare/
    └── custom/
```

## 🔧 Advanced Usage

### Programmatic Access

```bash
# Load site database functions
source /opt/oziscript/core/site-db.sh

# Check if site exists
if site_exists "example.com"; then
    echo "Site exists"
fi

# Get site data (JSON)
site_data=$(get_site "example.com")
echo "$site_data" | jq '.ssl.expires_at'

# List all sites
list_all_sites

# Get sites with expiring SSL
get_expiring_ssl_sites 30  # Next 30 days
```

### Custom Site Type

Create `modules/site/types/custom.sh`:
```bash
create_custom_site() {
    local domain="$1"
    local root="$2"
    
    # Your custom logic
    create_site_entry "$domain" "custom" "" "$root"
    generate_nginx_config "$domain" "static" "$root"
    # ...
}
```

### Cron Jobs

Setup SSL auto-renewal:
```bash
# Add to crontab
0 2 * * * /opt/oziscript/cron/ssl-auto-renew.sh
```

## 🐛 Troubleshooting

### Site database không tồn tại
```bash
# Initialize manually
source /opt/oziscript/core/site-db.sh
init_site_db
```

### Nginx config test failed
```bash
# Check syntax
nginx -t

# View errors
tail -f /var/log/nginx/error.log
```

### SSL renewal failed
```bash
# Check logs
tail -f /var/log/oziscript/ssl-auto-renew.log

# Manual renewal
ozi site ssl renew example.com
```

### Migration issues
```bash
# Re-run migration
bash /opt/oziscript/migrate-v2.sh

# Check site database
cat /etc/oziscript/sites.db | jq .
```

## 📚 Documentation

- **Full Documentation**: `/opt/oziscript/docs/`
- **Architecture V2**: `docs/ARCHITECTURE_V2.md`
- **API Reference**: `docs/API_REFERENCE.md`
- **Developer Guide**: `docs/DEVELOPER_GUIDE.md`

## 🤝 Contributing

1. Fork repository
2. Create feature branch
3. Test trên Debian 12/13
4. Submit pull request

## 📝 License

MIT License

## 👨‍💻 Author

**Ozi DevOps**
- GitHub: [@OziNetworkVN](https://github.com/OziNetworkVN)

## 🎉 Changelog

### V2.0.0 (2026-01-23)
- ✨ Centralized site database (JSON)
- ✨ Unified CLI (`ozi site` commands)
- ✨ Dynamic Nginx config generator
- ✨ SSL lifecycle manager with auto-renewal
- ✨ Type handlers (Laravel/WordPress/Node.js/Static)
- ✨ Domain alias management
- ✨ Auto-migration from V1
- 🔄 Complete architecture redesign
- 📚 Comprehensive documentation

### V1.0.4 (2026-01-22)
- Bug fixes và improvements
- Auto-update feature
- Git hooks support
- Enhanced Cloudflare SSL

---

**🚀 Ozi Script V2 - Professional VPS Management**
