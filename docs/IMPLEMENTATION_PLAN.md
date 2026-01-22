# Ozi Script - Implementation Plan

## Tổng quan

**Ozi Script** là bộ công cụ quản lý VPS bằng dòng lệnh (CLI) dành cho Debian 12+. Script được thiết kế module hóa, dễ mở rộng, với giao diện tiếng Việt.

### Thông tin dự án

| Mục | Chi tiết |
|-----|----------|
| **Tên** | Ozi Script |
| **CLI** | `ozi` |
| **OS** | Debian 12 (Bookworm), Debian 13 (Trixie) |
| **Ngôn ngữ** | Bash script |
| **Giao diện** | Tiếng Việt |
| **Thư mục** | `/opt/oziscript` |
| **Config** | `/etc/oziscript/config` |
| **Logs** | `/var/log/oziscript/` |

---

## Cấu trúc thư mục

```
packages/oziDebianScript/
├── install.sh              # Script cài đặt Ozi Script
├── uninstall.sh            # Script gỡ cài đặt
├── ozi                     # CLI chính (symlink to /usr/local/bin/ozi)
├── core/
│   ├── config.sh           # Quản lý cấu hình
│   ├── colors.sh           # Màu sắc terminal
│   ├── helpers.sh          # Hàm tiện ích
│   ├── menu.sh             # Hệ thống menu
│   └── os.sh               # Kiểm tra OS
├── modules/
│   ├── system/             # info.sh, swap.sh
│   ├── security/           # firewall.sh, ssh.sh, fail2ban.sh
│   ├── stack/              # php.sh, nginx.sh, postgresql.sh, mysql.sh, redis.sh, nodejs.sh, composer.sh, supervisor.sh
│   ├── site/               # manage.sh, cloudflare.sh
│   ├── database/           # admin.sh
│   ├── backup/             # local.sh
│   └── deploy/             # laravel.sh, nodejs.sh, wordpress.sh
└── templates/nginx/        # laravel.conf, laravel-octane.conf, wordpress.conf, nodejs.conf
```

---

## Menu Chính

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
```

---

## Quyết định đã được phê duyệt ✅

| Mục | Quyết định |
|-----|------------|
| **Database mặc định** | PostgreSQL (MySQL có thể cài thêm trong CLI) |
| **PM2** | Optional, là menu cài đặt thêm |
| **Database Admin** | Adminer |
| **SSL** | Cloudflare Origin Certificate (15 năm) |

---

## Hướng dẫn lấy Cloudflare API Token

1. Đăng nhập https://dash.cloudflare.com/
2. Click avatar → My Profile → API Tokens
3. Create Token → Create Custom Token
4. Permissions:
   - SSL and Certificates → Origin Certificates → Edit
   - Zone → Zone → Read
5. Create Token → Copy token ngay lập tức

---

## Verification

Xem file `TESTING.md` để biết chi tiết cách test trên VPS.
