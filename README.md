# Ozi Script

<div align="center">
  
[![Ozi Network](https://img.shields.io/badge/Ozi-Network-blue?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZD0iTTEyIDJMMiA3TDEyIDEyTDIyIDdMMTIgMloiIGZpbGw9IndoaXRlIi8+CjxwYXRoIGQ9Ik0yIDEyTDEyIDE3TDIyIDEyIiBzdHJva2U9IndoaXRlIiBzdHJva2Utd2lkdGg9IjIiLz4KPC9zdmc+)](https://ozinetwork.com)
[![Debian](https://img.shields.io/badge/Debian-12%2B-A81D33?style=for-the-badge&logo=debian)](https://www.debian.org/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![GitHub](https://img.shields.io/badge/GitHub-OziScripts-181717?style=for-the-badge&logo=github)](https://github.com/OziNetworkVN/OziScripts)

</div>

> 🚀 Bộ công cụ quản lý VPS chuyên nghiệp dành cho **Debian 12+** | Giao diện tiếng Việt | Miễn phí & Open Source

## ✨ Tính năng nổi bật

- 🎨 **Menu dạng số** - Giao diện tiếng Việt trực quan, dễ sử dụng như VPSSIM
- 🐘 **Multi-PHP** - Cài đặt đồng thời nhiều phiên bản PHP (7.4, 8.0, 8.1, 8.2, 8.3, 8.4)
- 🧠 **Tối ưu RAM tự động** - Tính toán thông số PHP-FPM tối ưu theo cấu hình VPS
- 🌐 **Nginx Templates** - Cấu hình Website chuẩn cho Laravel, WordPress, Node.js, Static
- 🔒 **SSL miễn phí** - Tích hợp Cloudflare API (SSL 15 năm) & Let's Encrypt
- 🗄️ **Multi Database** - Hỗ trợ PostgreSQL, MySQL/MariaDB và Adminer web interface
- 🛡️ **Bảo mật toàn diện** - UFW Firewall, Fail2ban, SSH hardening tự động
- 💾 **Backup & Restore** - Sao lưu toàn bộ hoặc database, hỗ trợ cronjob tự động
- 🔄 **Self-Update** - Cơ chế tự động cập nhật an toàn với rollback khi lỗi
- 🚀 **Deploy Tools** - Git-based deployment cho Laravel, Node.js, WordPress

## 🚀 Cài đặt nhanh

### Phương pháp 1: Từ GitHub (Khuyến nghị)

```bash
# SSH vào VPS
ssh root@your-vps-ip

# Cài Git (nếu VPS chưa có)
apt-get update && apt-get install -y git

# Clone repository
cd /opt
git clone https://github.com/OziNetworkVN/OziScripts.git oziscript

# Chạy installer
cd oziscript
bash install.sh

# Sử dụng ngay
ozi
```

### Phương pháp 2: Upload thủ công

```bash
# Upload từ máy local
scp -r . root@your-vps-ip:/opt/oziscript

# SSH vào VPS
ssh root@your-vps-ip

# Chạy installer
cd /opt/oziscript
bash install.sh
```

## 📖 Sử dụng

### Khởi động Menu

```bash
# Mở menu chính
ozi
```

### Demo Interface

```
╔══════════════════════════════════════════════════════════════╗
║              OZI SCRIPT - Quản lý VPS                        ║
║              VPS: 103.xxx.xxx.xxx (Debian 13)                ║
╚══════════════════════════════════════════════════════════════╝

  MENU CHÍNH
────────────────────────────────────────────────────────────────

  [1] Thông tin hệ thống
  [2] Quản lý PHP
  [3] Quản lý Nginx
  [4] Quản lý Database
  [5] Quản lý Website
  [6] SSL / Cloudflare
  [7] Bảo mật Server
  [8] Backup & Restore
  [9] Deploy ứng dụng
  [10] Cài đặt thêm

  [0] Thoát

Nhập lựa chọn [0-10]: _
```

## 📚 Hướng dẫn chi tiết

### 🚀 Quick Start: Tạo website Laravel

```bash
# 1. Cài PHP 8.3
ozi  # Chọn 2 → 1 → nhập "8.3"

# 2. Cài Nginx
# Chọn 3 → 1

# 3. Cài Database
# Chọn 4 → 1 (PostgreSQL) hoặc 2 (MySQL)

# 4. Tạo website
# Chọn 5 → 1
# Type: laravel
# Domain: myapp.com
# PHP: 8.3

# 5. Cài SSL Cloudflare (15 năm miễn phí)
# Chọn 6 → 5 (Config API)
# Sau đó chọn 1 (Install SSL)

# 6. Deploy từ Git
# Chọn 9 → 1
# Domain: myapp.com
# Git URL: https://github.com/user/laravel-app.git
# Branch: main
```

### 🎯 Quick Start: WordPress Site

```bash
# 1. Cài PHP + MySQL
ozi  # Chọn 2 → 1 → "8.2"
# Chọn 4 → 2 (MySQL)

# 2. Deploy WordPress
# Chọn 9 → 3
# Nhập domain và database info

# 3. Cài SSL Let's Encrypt
# Chọn 6 → 2
```

### 🔄 Cập nhật Script

#### Phương pháp 1: Từ Menu (Khuyến nghị)

```bash
ozi
# Chọn 1 (Thông tin hệ thống)
# Chọn 8 (Kiểm tra cập nhật script)
# Nếu có bản mới, chọn "Yes" để cập nhật
```

**Tính năng Self-Update:**
- ✅ Tự động backup phiên bản cũ trước khi update
- ✅ Rollback tự động nếu update lỗi
- ✅ Giữ nguyên cấu hình và dữ liệu

#### Phương pháp 2: Git Pull

```bash
# Nếu cài từ Git
cd /opt/oziscript
git pull origin main

# Set lại quyền
chmod +x ozi
find . -name "*.sh" -exec chmod +x {} \;
```

#### ⚠️ Xử lý lỗi "local changes"

Nếu gặp lỗi: `error: Your local changes to the following files would be overwritten by merge`

**Cách 1: Reset về code gốc (Khuyến nghị)**
```bash
cd /opt/oziscript

# Reset tất cả thay đổi local
git reset --hard HEAD

# Pull code mới
git pull origin main

# Set quyền
chmod +x ozi
find . -name "*.sh" -exec chmod +x {} \;
```

**Cách 2: Stash changes (Nếu muốn giữ thay đổi)**
```bash
cd /opt/oziscript

# Lưu thay đổi tạm thời
git stash

# Pull code mới
git pull origin main

# Apply lại thay đổi (nếu cần)
git stash pop

# Set quyền
chmod +x ozi
find . -name "*.sh" -exec chmod +x {} \;
```

**Cách 3: Force pull (Nhanh nhất)**
```bash
cd /opt/oziscript
git fetch origin
git reset --hard origin/main
chmod +x ozi
find . -name "*.sh" -exec chmod +x {} \;
```

### 📦 Thêm Domain Alias

**Nhiều domain cùng trỏ về 1 source code:**

```bash
ozi
# Chọn 5 (Quản lý Website)
# Chọn 6 (Thêm domain alias)
# Main domain: myapp.com
# Alias domain: staging.myapp.com
```

**Use cases:**
- Production & Staging cùng code
- Multiple domains (.com, .net, .vn)
- Dev/Test environments

### Các tính năng nổi bật

#### 🧠 Tối ưu hóa PHP theo RAM
Ozi Script tự động nhận diện dung lượng RAM trên VPS của bạn để điều chỉnh các thông số PHP-FPM (`max_children`, `memory_limit`, `start_servers`,...) một cách tối ưu nhất. Giúp server hoạt động ổn định và tận dụng tối đa tài nguyên.

#### 🛡️ Safe Self-Update
Cập nhật Ozi Script lên phiên bản mới nhất chỉ với 1 click:
- Tự động sao lưu phiên bản cũ trước khi update.
- Cơ chế **Rollback** tự động nếu quá trình tải bản cập nhật gặp lỗi.
- Đảm bảo script của bạn luôn có những tính năng và bản vá bảo mật mới nhất.

#### 📅 Tự động Backup
Không còn lo lắng việc mất dữ liệu. Chức năng Backup tích hợp cho phép:
- Backup đầy đủ Code + Database.
- Thiết lập lịch chạy tự định kỳ (Hàng ngày / Hàng tuần) qua Cronjob.
- Quản lý và khôi phục (Restore) dễ dàng từ giao diện CLI.

#### 🎨 Nginx Templates
Hệ thống template thông minh giúp tạo cấu hình Nginx chuẩn cho từng loại ứng dụng:
- **Laravel:** Tối ưu hóa cho Laravel Octane, caching, security headers.
- **WordPress:** Bảo mật file config, xmlrpc, tối ưu permalinks.
- **Node.js:** Reverse proxy với cấu hình port linh hoạt.
- **Static:** Chuyên dụng cho các app React, Vue, HTML tĩnh.

## 📁 Cấu trúc

```
/opt/oziscript/
├── ozi                 # CLI chính
├── install.sh          # Cài đặt
├── uninstall.sh        # Gỡ cài đặt
├── core/               # Core libraries
│   ├── colors.sh
│   ├── helpers.sh
│   ├── config.sh
│   ├── os.sh
│   └── menu.sh
├── modules/            # Các modules
│   ├── system/         # Thông tin hệ thống
│   ├── stack/          # PHP, Nginx, Database...
│   ├── site/           # Quản lý website, SSL
│   ├── security/       # Firewall, SSH
│   ├── backup/         # Backup/Restore
│   └── database/       # Adminer
└── templates/          # Nginx templates
```

## 🔧 Yêu cầu hệ thống

- ✅ **OS:** Debian 12 (Bookworm) hoặc Debian 13 (Trixie)
- ✅ **Quyền:** Root access
- ✅ **RAM:** Tối thiểu 512MB (khuyến nghị 1GB+)
- ✅ **Disk:** Tối thiểu 10GB free space
- ✅ **Network:** Kết nối internet ổn định

## 🎯 Use Cases

- 🏢 **Hosting Laravel Apps** - Deploy và quản lý Laravel projects với Octane support
- 🌐 **WordPress Sites** - Tạo và tối ưu WordPress sites trong vài phút
- ⚡ **Node.js Applications** - Reverse proxy và PM2 process management
- 🗄️ **Database Management** - PostgreSQL, MySQL với Adminer web interface
- 🔐 **Server Security** - UFW, Fail2ban, SSH hardening tự động
- 💾 **Automated Backups** - Schedule daily/weekly backups với cronjobs

## 🤝 Đóng góp

Chúng tôi luôn chào đón mọi đóng góp! Xem [CONTRIBUTING.md](docs/CONTRIBUTING.md) để biết thêm chi tiết.

## 📞 Hỗ trợ

- 🌐 **Website:** [Ozi Network](https://ozinetwork.com)
- 💬 **Issues:** [GitHub Issues](https://github.com/OziNetworkVN/OziScripts/issues)
- 📧 **Email:** dev@oziscript.dev
- 📚 **Documentation:** [docs/](docs/)

## 👥 Credits

Phát triển bởi [**Ozi Network**](https://ozinetwork.com) - Giải pháp VPS & Cloud Hosting chuyên nghiệp.

## ⭐ Support Us

Nếu bạn thấy project hữu ích, hãy cho chúng tôi một ⭐ trên [GitHub](https://github.com/OziNetworkVN/OziScripts)!

## 📄 License

MIT License - Copyright © 2026 [Ozi Network](https://ozinetwork.com)

---

<div align="center">
  
**Made with ❤️ by [Ozi Network](https://ozinetwork.com)**

[Website](https://ozinetwork.com) • [GitHub](https://github.com/OziNetworkVN) • [Documentation](docs/)

</div>
