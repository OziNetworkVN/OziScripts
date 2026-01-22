# Ozi Script

Bộ công cụ quản lý VPS bằng CLI dành cho **Debian 12+**, với giao diện tiếng Việt.

## ✨ Tính năng

- **Menu dạng số** - Dễ sử dụng như VPSSIM
- **Multi-PHP** - Cài đồng thời nhiều phiên bản (7.4, 8.1, 8.2, 8.3, 8.4)
- **Quản lý Website** - Tạo site Laravel, WordPress, Node.js tự động
- **SSL Cloudflare** - Tạo SSL 15 năm từ Cloudflare Origin Certificate
- **Database** - PostgreSQL + MySQL/MariaDB + Adminer
- **Bảo mật** - UFW Firewall, SSH hardening, Fail2ban
- **Backup** - Full backup websites + databases

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
