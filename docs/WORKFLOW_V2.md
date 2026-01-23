# Quy Trình Quản Lý Site Đúng Chuẩn - Ozi Script V2

## 📋 Quy Trình Chuẩn (Theo VPSSim/DLEMP/aaPanel)

### ✅ Quy Trình Đúng

```
1. TẠO SITE TRƯỚC
   ↓
2. CÀI SSL (nếu cần)
   ↓
3. THÊM ALIASES (nếu cần)
   ↓
4. SỬ DỤNG SITE
```

### ❌ QUY TRÌNH SAI

```
❌ Cài SSL khi chưa có site
❌ Thêm alias khi chưa có site
❌ Delete không cleanup hết
```

## 🎯 Hướng Dẫn Chi Tiết

### Bước 1: Tạo Website

```bash
# Chạy wizard tạo site
ozi site create

# Chọn loại site:
# 1. Laravel
# 2. WordPress
# 3. Node.js
# 4. Static HTML

# Nhập domain: example.com
# Cấu hình theo loại site

# ✅ Kết quả: Site được tạo, Nginx config ready, chưa có SSL
```

**Output:**
```
✓ Laravel site created successfully!

Domain: example.com
Root: /var/www/example.com
PHP: 8.3
Database: db_example_com
User: user_example
Password: [saved to /root/.oziscript/db-credentials/example.com.txt]

Next Steps:
1. Upload Laravel code to: /var/www/example.com
2. Configure .env file
3. Run: php artisan migrate
4. Install SSL: ozi site ssl install example.com
```

### Bước 2: Kiểm Tra Site

```bash
# Xem chi tiết site
ozi site info example.com

# Xem danh sách tất cả sites
ozi site list

# Test truy cập
curl -I http://example.com
```

### Bước 3: Cài SSL (Sau khi có site)

```bash
# ✅ ĐÚNG: Cài SSL cho site đã tồn tại
ozi site ssl install example.com

# Chọn loại SSL:
# 1. Let's Encrypt (Free, Auto-renew)
# 2. Cloudflare Origin (15 years)
# 3. Custom SSL (Upload)

# ✅ Kết quả: SSL được cài, Nginx config updated, HTTPS enabled
```

**Validation:**
```bash
# Script sẽ check:
✓ Site có tồn tại không?
✓ Nginx config có hợp lệ không?
✓ Domain đã trỏ về server chưa? (Let's Encrypt)
✓ Certificate valid không? (Custom SSL)

# Nếu fail → rollback, không làm hỏng site
```

### Bước 4: Thêm Aliases (Optional)

```bash
# Thêm www subdomain
ozi site alias add example.com www.example.com

# Thêm nhiều aliases
ozi site alias add example.com blog.example.com
ozi site alias add example.com shop.example.com

# Xem aliases hiện tại
ozi site alias list example.com
```

### Bước 5: Quản Lý Site

```bash
# Xem trạng thái SSL
ozi site ssl status example.com

# Gia hạn SSL
ozi site ssl renew example.com

# Xem tất cả SSL
ozi site ssl list
```

## 🗑️ Xóa Site Đúng Cách

### Xóa 1 Site (Cleanup Hoàn Toàn)

```bash
ozi site delete example.com
```

**Quá trình xóa:**
```
⚠ CẢNH BÁO: Hành động này sẽ xóa:
  - Cấu hình Nginx
  - Thư mục website
  - Database (nếu có)
  - SSL certificates

Bạn có chắc chắn muốn xóa example.com? [y/N]: y

Đang xóa example.com...
ℹ Đang dừng processes...
ℹ Xóa SSL certificates...
ℹ Xóa Nginx config...
ℹ Xóa thư mục website: /var/www/example.com
ℹ Xóa database và user...

✓ Đã xóa example.com hoàn toàn

Đã cleanup:
  ✓ Nginx config và logs
  ✓ SSL certificates
  ✓ Website files (/var/www/example.com)
  ✓ Database: db_example_com
  ✓ Database user: user_example
  ✓ PM2 processes (nếu Node.js)
  ✓ Supervisor configs (nếu Laravel)
  ✓ Site database entry
```

### Cleanup Toàn Bộ (NGUY HIỂM!)

```bash
# Xóa TẤT CẢ sites
ozi site cleanup

# Yêu cầu gõ "DELETE ALL" để xác nhận
```

**Sử dụng khi:**
- Reset VPS về trạng thái ban đầu
- Xóa hết để test lại
- Cleanup sau khi migration

## 🔍 Troubleshooting

### Vấn Đề 1: Cài SSL khi chưa có site

**Lỗi:**
```bash
$ ozi site ssl install example.com
✗ Website không tồn tại: example.com

ℹ Tạo website trước khi cài SSL:
  ozi site create

ℹ Hoặc xem danh sách sites:
  ozi site list
```

**Giải pháp:**
```bash
# Tạo site trước
ozi site create
# Chọn type → nhập domain

# Sau đó mới cài SSL
ozi site ssl install example.com
```

### Vấn Đề 2: Delete không xóa hết

**Triệu chứng:**
- Không thể tạo lại site với domain cũ
- Database vẫn còn
- Nginx config còn sót
- SSL certificates còn

**Giải pháp:**

```bash
# V2 đã fix - delete sẽ xóa:
✓ PM2/Supervisor processes
✓ Database + User
✓ Nginx config + logs
✓ SSL certificates (all types)
✓ Website files
✓ DB credentials file
✓ Site database entry

# Nếu vẫn còn sót, dùng cleanup:
ozi site cleanup
# Hoặc manual cleanup:
sudo rm -rf /var/www/old-domain.com
sudo rm -f /etc/nginx/sites-available/old-domain.com.conf
sudo rm -f /etc/nginx/sites-enabled/old-domain.com.conf
mysql -e "DROP DATABASE IF EXISTS db_old_domain_com;"
mysql -e "DROP USER IF EXISTS 'user_old'@'localhost';"
```

### Vấn Đề 3: Không thể tạo lại domain

**Lỗi:**
```bash
$ ozi site create
Domain: example.com
✗ Website example.com đã tồn tại
```

**Nguyên nhân:**
- Site vẫn còn trong database
- Delete không hoàn tất

**Giải pháp:**
```bash
# Check site có thực sự tồn tại không
ozi site info example.com

# Nếu có → delete đúng cách
ozi site delete example.com

# Nếu không có nhưng vẫn báo lỗi → force cleanup database
source /opt/oziscript/core/site-db.sh
delete_site_entry "example.com"

# Hoặc cleanup toàn bộ
ozi site cleanup
```

## 📊 So Sánh Với Script Khác

### VPSSim Flow

```
VPSSim:
1. Tạo domain → Files + Nginx
2. Add SSL → Let's Encrypt/Manual
3. Quản lý → Edit/Delete

Ozi V2:
1. Create site → Type handler + DB tracking
2. SSL install → 3 types (LE/CF/Custom)
3. Manage → Unified commands
```

### DLEMP Flow

```
DLEMP:
1. Add domain
2. Add database
3. Add SSL
4. Manage

Ozi V2:
1. Create site (all-in-one wizard)
   - Domain + Type + DB + Nginx
2. SSL install (separate)
3. Aliases (separate)
```

### aaPanel Flow

```
aaPanel (Web UI):
1. Add website (form)
2. Database (checkbox)
3. SSL (button)

Ozi V2 (CLI):
1. ozi site create (wizard)
2. ozi site ssl install
3. ozi site alias add
```

## ✅ Best Practices

### 1. Luôn Tạo Site Trước

```bash
# ✅ ĐÚNG
ozi site create        # Tạo site
ozi site ssl install   # Sau đó cài SSL

# ❌ SAI
ozi site ssl install   # Lỗi: site chưa tồn tại
```

### 2. Xóa Site Đúng Cách

```bash
# ✅ ĐÚNG: Dùng command delete
ozi site delete example.com

# ❌ SAI: Xóa manual
rm -rf /var/www/example.com  # Còn sót database, Nginx config, SSL
```

### 3. Check Trước Khi Làm

```bash
# Xem site có tồn tại
ozi site list
ozi site info example.com

# Xem SSL status
ozi site ssl status example.com

# Xem aliases
ozi site alias list example.com
```

### 4. Backup Trước Khi Xóa

```bash
# Backup site database
cp /etc/oziscript/sites.db /backup/sites.db.backup

# Backup website files
tar -czf /backup/example.com.tar.gz /var/www/example.com

# Backup database
mysqldump db_example_com > /backup/db_example_com.sql

# Sau đó mới delete
ozi site delete example.com
```

## 🎓 Workflow Examples

### Tạo Laravel Site Hoàn Chỉnh

```bash
# 1. Create site
ozi site create
# → Chọn Laravel
# → Domain: laravel.test
# → PHP 8.3
# → Octane: No
# → Database: Yes

# 2. Upload code
cd /var/www/laravel.test
git clone your-laravel-repo.git .

# 3. Configure
cp .env.example .env
nano .env  # Use DB credentials from /root/.oziscript/db-credentials/

# 4. Setup Laravel
composer install
php artisan key:generate
php artisan migrate

# 5. Install SSL
ozi site ssl install laravel.test
# → Let's Encrypt
# → Email: your@email.com

# 6. Add www
ozi site alias add laravel.test www.laravel.test

# 7. Verify
curl -I https://laravel.test
curl -I https://www.laravel.test
```

### Migrate Site to New Domain

```bash
# 1. Create new site
ozi site create
# → Domain: newdomain.com

# 2. Copy files
cp -r /var/www/olddomain.com/* /var/www/newdomain.com/

# 3. Update configs
# Update .env, wp-config.php, etc.

# 4. Install SSL
ozi site ssl install newdomain.com

# 5. Test new site
curl -I https://newdomain.com

# 6. Delete old site
ozi site delete olddomain.com
```

---

**Quy trình này đảm bảo:**
- ✅ Không cài SSL khi chưa có site
- ✅ Delete cleanup hoàn toàn
- ✅ Không conflict khi tạo lại domain
- ✅ Theo chuẩn VPSSim/DLEMP/aaPanel
