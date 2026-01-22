# Hướng dẫn Test Ozi Script

## Bước 1: Upload lên VPS

Từ máy Windows, mở PowerShell:

```powershell
# Nén thư mục (tùy chọn)
Compress-Archive -Path "D:\laragon\www\oziTube\packages\oziDebianScript\*" -DestinationPath "oziscript.zip"

# Hoặc dùng scp để upload trực tiếp
scp -r "D:\laragon\www\oziTube\packages\oziDebianScript" root@YOUR_VPS_IP:/opt/oziscript
```

## Bước 2: SSH vào VPS

```bash
ssh root@YOUR_VPS_IP
```

## Bước 3: Cài đặt Ozi Script

```bash
cd /opt/oziscript
chmod +x install.sh
bash install.sh
```

**Kết quả mong đợi:**
```
═══════════════════════════════════════════════════════════════
       ✓ CÀI ĐẶT THÀNH CÔNG!
═══════════════════════════════════════════════════════════════

  Để bắt đầu, gõ: ozi
```

## Bước 4: Test Menu Chính

```bash
ozi
```

**Kết quả mong đợi:**
```
╔══════════════════════════════════════════════════════════════╗
║              OZI SCRIPT - Quản lý VPS                        ║
║              VPS: xxx.xxx.xxx.xxx                            ║
║              Debian GNU/Linux 13 (trixie)                    ║
╚══════════════════════════════════════════════════════════════╝

  MENU CHÍNH
────────────────────────────────────────────────────────────────

  [1] Thông tin hệ thống
  [2] Quản lý PHP
  ...
  [0] Thoát

Nhập lựa chọn [0-10]: 
```

## Bước 5: Test từng module

### Test [1] Thông tin hệ thống
- Chọn `1` → `1` (Xem thống kê tổng quan)
- Kiểm tra: Hiển thị đúng IP, RAM, Disk

### Test [2] Quản lý PHP
- Chọn `2` → `1` (Cài đặt PHP mới) → Chọn PHP 8.3
- Kiểm tra: `php -v` hiện phiên bản 8.3

### Test [3] Quản lý Nginx
- Chọn `3` → `1` (Cài đặt Nginx)
- Kiểm tra: `systemctl status nginx` chạy

### Test [4] Quản lý Database
- Chọn `4` → `1` (Cài PostgreSQL)
- Kiểm tra: `systemctl status postgresql` chạy

### Test [5] Quản lý Website
- Chọn `5` → `1` (Tạo website mới)
- Nhập: Laravel, test.example.com
- Kiểm tra: File config tại `/etc/nginx/sites-available/test.example.com`

### Test [6] SSL / Cloudflare
- Chọn `6` → `5` (Cấu hình Cloudflare API)
- Nhập token và kiểm tra xác thực

### Test [7] Bảo mật Server
- Chọn `7` → `1` (Cấu hình Firewall)
- Kiểm tra: `ufw status` hiện các rules

### Test [8] Backup & Restore
- Chọn `8` → `1` (Tạo Backup đầy đủ)
- Kiểm tra: File backup tại `/var/backups/oziscript/`

## Xử lý lỗi thường gặp

### Lỗi: Permission denied
```bash
chmod +x /opt/oziscript/ozi
chmod +x /opt/oziscript/**/*.sh
```

### Lỗi: Command not found
```bash
ln -sf /opt/oziscript/ozi /usr/local/bin/ozi
```

### Lỗi: Module not found
Kiểm tra path trong file `/opt/oziscript/core/menu.sh`

## Gỡ cài đặt (nếu cần)

```bash
bash /opt/oziscript/uninstall.sh
```
