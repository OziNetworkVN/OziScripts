# Ozi Script

Bộ công cụ quản lý VPS bằng CLI dành cho **Debian 12+**, với giao diện tiếng Việt.

## ✨ Tính năng

- **Menu dạng số** - Giao diện tiếng Việt, dễ sử dụng như VPSSIM
- **Multi-PHP** - Cài đặt đồng thời nhiều phiên bản PHP (7.4 - 8.4)
- **Tối ưu RAM** - Tự động tính toán thông số PHP-FPM tối ưu theo cấu hình VPS
- **Nginx Templates** - Cấu hình Website chuẩn cho Laravel, WordPress, Node.js, Static
- **SSL Origin** - Tích hợp Cloudflare API, cấp SSL 15 năm miễn phí
- **Database** - Hỗ trợ PostgreSQL, MySQL/MariaDB và công cụ quản trị Adminer
- **Bảo mật** - Firewall UFW, chặn truy cập trái phép với Fail2ban, SSH hardening
- **Backup & Restore** - Sao lưu toàn bộ dữ liệu hoặc database, hỗ trợ đặt lịch tự động
- **Self-Update** - Cơ chế tự động cập nhật an toàn với rollback khi lỗi

## 🚀 Cài đặt

```bash
# Upload lên VPS
scp -r . root@your-vps-ip:/opt/oziscript

# SSH vào VPS
ssh root@your-vps-ip

# Chạy installer
cd /opt/oziscript
bash install.sh
```

## 📖 Sử dụng

```bash
# Mở menu chính
ozi
```

### Menu chính

```
╔══════════════════════════════════════════════════════════════╗
║                    OZI SCRIPT - MENU CHÍNH                    ║
║                   VPS: 103.xxx.xxx.xxx (Debian 13)            ║
╚══════════════════════════════════════════════════════════════╝

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

## 🔧 Yêu cầu

- Debian 12 (Bookworm) hoặc Debian 13 (Trixie)
- Quyền root

## 📄 License

MIT License
