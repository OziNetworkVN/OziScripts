# Fix: PHP-FPM "Failed to resolve user www-data" Error

## 🐛 Lỗi

```
/usr/lib/tmpfiles.d/php8.4-fpm.conf:2: Failed to resolve user 'www-data': No such process
Job for php8.4-fpm.service failed because the control process exited with error code.
dpkg: error processing package php8.4-fpm (--configure):
 installed php8.4-fpm package post-installation script subprocess returned error exit status 1
```

## 🔍 Nguyên Nhân

- **User `www-data` không tồn tại** trên hệ thống
- PHP-FPM và Nginx yêu cầu user `www-data` để chạy processes
- Xảy ra trên Debian minimal installations hoặc Docker containers

## ✅ Cách Fix Ngay Lập Tức

### 1. Tạo User www-data

```bash
# Tạo group www-data
sudo groupadd -f www-data

# Tạo user www-data
sudo useradd -g www-data -s /usr/sbin/nologin -M www-data

# Verify
id www-data
# Output: uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

### 2. Reconfigure PHP-FPM

```bash
# Fix broken packages
sudo dpkg --configure -a

# Start PHP-FPM
sudo systemctl start php8.4-fpm

# Check status
sudo systemctl status php8.4-fpm
# Should show: Active: active (running)

# Enable auto-start
sudo systemctl enable php8.4-fpm
```

### 3. Verify Installation

```bash
# Check PHP version
php -v

# Check PHP-FPM socket
ls -l /run/php/php8.4-fpm.sock

# Test PHP-FPM
sudo systemctl restart php8.4-fpm
sudo systemctl status php8.4-fpm
```

## 🔄 Fix Đã Được Tích Hợp Vào V2

Từ phiên bản **V2.0.0**, Ozi Script tự động tạo user `www-data` trước khi cài đặt PHP/Nginx.

### Cập Nhật Lên V2

```bash
cd /opt/oziscript
git pull origin main

# Verify version
ozi version
# Should show: Ozi Script v2.0.0
```

### Cài Mới với V2

```bash
git clone https://github.com/OziNetworkVN/OziScripts.git
cd OziScripts
sudo bash install.sh

# www-data sẽ được tạo tự động
```

## 🛠️ Troubleshooting

### Lỗi: User Already Exists

```bash
# Nếu user đã tồn tại nhưng có vấn đề
sudo userdel www-data
sudo groupdel www-data

# Tạo lại
sudo groupadd -r www-data
sudo useradd -r -g www-data -s /usr/sbin/nologin -d /var/www -M www-data
```

### PHP-FPM Vẫn Không Start

```bash
# Check logs
sudo journalctl -xeu php8.4-fpm.service

# Check config
sudo php-fpm8.4 -t

# Check permissions
sudo ls -l /etc/php/8.4/fpm/
sudo ls -l /run/php/
```

### Nginx Cũng Có Lỗi Tương Tự

```bash
# Apply same fix
sudo groupadd -f www-data
sudo useradd -g www-data -s /usr/sbin/nologin -M www-data

# Restart Nginx
sudo systemctl restart nginx
sudo systemctl status nginx
```

## 📝 Technical Details

### www-data User Specifications

- **UID/GID**: Typically 33 on Debian/Ubuntu
- **Shell**: `/usr/sbin/nologin` (no login allowed)
- **Home**: `/var/www` (web root)
- **Purpose**: Run web services (Nginx, PHP-FPM, Apache)

### Why www-data?

- Standard user for web services on Debian/Ubuntu
- Provides security isolation
- Limited permissions (can't login)
- Owns web files in `/var/www`

### Creation Command Breakdown

```bash
useradd -r -g www-data -s /usr/sbin/nologin -d /var/www -M www-data
#       │  │          │                      │          │  └─ Username
#       │  │          │                      │          └─ No create home
#       │  │          │                      └─ Home directory
#       │  │          └─ No login shell
#       │  └─ Primary group
#       └─ System account
```

## 🔐 Security Note

User `www-data` should have:
- No password
- No login shell
- Minimal permissions
- Only access to web directories

## 📚 Related Issues

### Similar Errors

```
Failed to resolve user 'nginx'
Failed to resolve user 'apache'
```

**Fix**: Create respective users before service installation

### Prevention

Always ensure system users exist before installing services that depend on them.

## ✅ Verification Checklist

After fix:

- [ ] `id www-data` returns user info
- [ ] `sudo systemctl status php8.4-fpm` shows active
- [ ] `ls -l /run/php/php8.4-fpm.sock` shows socket exists
- [ ] `php -v` returns PHP version
- [ ] `sudo nginx -t` passes (if Nginx installed)

## 🆘 Still Having Issues?

1. Check system logs: `sudo journalctl -xe`
2. Check PHP-FPM logs: `sudo tail -f /var/log/php8.4-fpm.log`
3. Check permissions: `ls -la /var/www`
4. Report issue: https://github.com/OziNetworkVN/OziScripts/issues

---

**Fixed in Ozi Script V2.0.0+** ✅
