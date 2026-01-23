# PHP & Redis Configuration Guide

## Sau khi cài SSL và tạo website

### 1. Kiểm tra PHP Config

```bash
# Kiểm tra PHP extensions và settings
ozi php check

# Hoặc kiểm tra version cụ thể
ozi php check 8.4
```

**Kiểm tra gì:**
- ✅ Extensions bắt buộc (Laravel): bcmath, curl, dom, gd, intl, mbstring, mysql, redis, zip...
- ✅ Extensions khuyến nghị: opcache, imagick, sodium
- ✅ Settings quan trọng: memory_limit, upload_max_filesize, timezone
- ✅ OPcache config
- ✅ PHP-FPM pools

### 2. Tối ưu PHP cho Production

```bash
# Tự động tối ưu PHP
ozi php optimize

# Hoặc optimize version cụ thể
ozi php optimize 8.4
```

**Tối ưu gì:**
- memory_limit = 512M
- upload_max_filesize = 64M
- post_max_size = 64M
- max_execution_time = 300
- date.timezone = Asia/Ho_Chi_Minh
- OPcache: 256M memory, 10000 max files
- PHP-FPM pools: Auto-calculate dựa trên RAM

### 3. Cài Extensions thiếu

```bash
# Cài đầy đủ extensions cho Laravel/WordPress
ozi php extensions

# Hoặc version cụ thể
ozi php extensions 8.3
```

**Extensions được cài:**
- php-bcmath, php-cli, php-curl, php-fpm
- php-gd, php-intl, php-mbstring, php-mysql
- php-opcache, php-redis, php-xml, php-zip

---

## Redis Configuration

### 1. Kiểm tra Redis

```bash
# Kiểm tra status và config
ozi redis check
```

**Thông tin hiển thị:**
- Redis version
- Memory usage
- Connected clients
- Uptime
- Config settings (maxmemory, eviction policy, persistence)

### 2. Tối ưu Redis cho Laravel

```bash
# Tự động tối ưu Redis
ozi redis optimize
```

**Tối ưu gì:**
- maxmemory = 256MB
- maxmemory-policy = allkeys-lru (tự động xóa key cũ khi hết RAM)
- Disable persistence (không save disk → nhanh hơn)
- Enable Unix socket (nhanh hơn TCP connection)
- Add www-data vào redis group

### 3. Cấu hình Laravel dùng Redis

```bash
# Tự động config Laravel .env
ozi redis laravel xtubedb.com
```

**Cập nhật .env:**
```env
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
REDIS_HOST=/var/run/redis/redis-server.sock
REDIS_PORT=0
```

**Sau đó clear cache:**
```bash
cd /var/www/xtubedb.com
php artisan cache:clear
php artisan config:clear
```

### 4. Test Performance

```bash
# Chạy benchmark
ozi redis benchmark
```

---

## Quy trình đầy đủ

### Sau khi tạo Laravel site mới:

```bash
# 1. Check PHP
ozi php check

# 2. Optimize PHP (nếu cần)
ozi php optimize

# 3. Cài extensions thiếu (nếu có)
ozi php extensions

# 4. Optimize Redis
ozi redis optimize

# 5. Config Laravel dùng Redis
ozi redis laravel xtubedb.com

# 6. Clear Laravel cache
cd /var/www/xtubedb.com
php artisan cache:clear
php artisan config:clear
php artisan config:cache
```

### Kiểm tra kết quả:

```bash
# Test phpinfo
echo "<?php phpinfo();" > /var/www/xtubedb.com/public/info.php
curl https://xtubedb.com/info.php

# Test Redis connection
php artisan tinker
>>> \Illuminate\Support\Facades\Cache::put('test', 'Hello Redis', 60);
>>> \Illuminate\Support\Facades\Cache::get('test');
# Kết quả: "Hello Redis"
```

---

## Checklist đầy đủ

### PHP Extensions (Laravel)
- [x] bcmath - Tính toán số lớn
- [x] ctype - Character type checking
- [x] curl - HTTP requests
- [x] dom - DOM manipulation
- [x] fileinfo - File information
- [x] json - JSON parsing
- [x] mbstring - Multi-byte string
- [x] openssl - SSL/TLS
- [x] pdo - Database abstraction
- [x] pdo_mysql - MySQL driver
- [x] tokenizer - PHP tokenizer
- [x] xml - XML processing
- [x] zip - ZIP compression
- [x] gd - Image processing
- [x] intl - Internationalization
- [x] redis - Redis extension

### PHP Settings
- [x] memory_limit = 512M
- [x] upload_max_filesize = 64M
- [x] post_max_size = 64M
- [x] max_execution_time = 300
- [x] date.timezone = Asia/Ho_Chi_Minh

### OPcache
- [x] opcache.enable = 1
- [x] opcache.memory_consumption = 256
- [x] opcache.max_accelerated_files = 10000
- [x] opcache.revalidate_freq = 2

### Redis
- [x] maxmemory = 256mb
- [x] maxmemory-policy = allkeys-lru
- [x] Unix socket enabled
- [x] Persistence disabled (cache only)

### Laravel .env
- [x] CACHE_DRIVER=redis
- [x] SESSION_DRIVER=redis
- [x] QUEUE_CONNECTION=redis
- [x] REDIS_HOST=/var/run/redis/redis-server.sock

---

## Troubleshooting

### PHP không có extension

```bash
# Check extension có sẵn không
apt-cache search php8.4-redis

# Cài thủ công
apt-get install -y php8.4-redis

# Restart PHP-FPM
systemctl restart php8.4-fpm
```

### Redis không kết nối được

```bash
# Check Redis running
systemctl status redis-server

# Check socket exists
ls -la /var/run/redis/redis-server.sock

# Check permissions
sudo usermod -a -G redis www-data
sudo chmod 770 /var/run/redis/redis-server.sock
sudo systemctl restart php8.4-fpm
```

### Laravel không dùng Redis

```bash
# Check .env
cat /var/www/xtubedb.com/.env | grep REDIS

# Clear config cache
cd /var/www/xtubedb.com
php artisan config:clear
php artisan cache:clear

# Test connection
php artisan tinker
>>> Cache::put('test', 'value');
>>> Cache::get('test');
```

### OPcache không hoạt động

```bash
# Check module loaded
php -m | grep opcache

# Check settings
php -i | grep opcache

# Restart PHP-FPM
systemctl restart php8.4-fpm
```

---

## Performance Tips

### 1. PHP-FPM Pools
- Script tự động tính based on RAM
- ~50MB per child process
- Min 10, Max 100 children

### 2. Redis Memory
- Default: 256MB
- Tăng lên nếu cache nhiều: `maxmemory 512mb`
- Monitor: `redis-cli INFO memory`

### 3. OPcache
- Cache compiled PHP files
- Giảm CPU, tăng tốc độ
- Không cần revalidate mỗi request

### 4. Laravel Optimization
```bash
cd /var/www/xtubedb.com

# Cache config
php artisan config:cache

# Cache routes
php artisan route:cache

# Cache views
php artisan view:cache

# Optimize autoloader
composer install --optimize-autoloader --no-dev
```

---

## Monitoring

### Check PHP-FPM Status
```bash
# Pool status
systemctl status php8.4-fpm

# Slow log
tail -f /var/log/php8.4-fpm.log

# Process list
ps aux | grep php-fpm
```

### Check Redis Status
```bash
# Status
redis-cli INFO

# Monitor commands
redis-cli MONITOR

# Check keys
redis-cli KEYS *

# Memory usage
redis-cli INFO memory
```

### Check Laravel Logs
```bash
# Application log
tail -f /var/www/xtubedb.com/storage/logs/laravel.log

# Nginx access
tail -f /var/www/xtubedb.com/logs/access.log

# Nginx error
tail -f /var/www/xtubedb.com/logs/error.log
```

---

## Quick Commands Reference

| Task | Command |
|------|---------|
| Check PHP config | `ozi php check` |
| Optimize PHP | `ozi php optimize` |
| Install extensions | `ozi php extensions` |
| Check Redis | `ozi redis check` |
| Optimize Redis | `ozi redis optimize` |
| Config Laravel Redis | `ozi redis laravel <domain>` |
| Test Redis performance | `ozi redis benchmark` |
| Restart PHP-FPM | `systemctl restart php8.4-fpm` |
| Restart Redis | `systemctl restart redis-server` |
| Clear Laravel cache | `php artisan cache:clear` |

---

**Tóm lại:** Chạy 2 lệnh này sau khi cài SSL:
```bash
ozi php optimize
ozi redis optimize
```

Xong! 🚀
