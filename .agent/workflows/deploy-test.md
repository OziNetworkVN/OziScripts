---
description: Test và deploy Ozi Script lên VPS Debian
---

# Deploy & Test Ozi Script

## Bước 1: Kết nối VPS
```bash
ssh root@{vps-ip}
```

## Bước 2: Upload script (từ máy local)
// turbo
```bash
scp -r d:/laragon/www/oziTube/packages/oziDebianScript root@{vps-ip}:/opt/oziscript
```

## Bước 3: Cài đặt Ozi Script
// turbo
```bash
cd /opt/oziscript && bash install.sh
```

## Bước 4: Test menu chính
// turbo
```bash
ozi
```

## Bước 5: Test từng lệnh
```bash
# Thông tin hệ thống
ozi system info

# Cài PHP
ozi php install 8.3

# Tạo site
ozi site create laravel example.com
```

## Bước 6: Kiểm tra logs
// turbo
```bash
tail -f /var/log/oziscript/ozi.log
```

## Troubleshooting

### Lỗi permission denied
```bash
chmod +x /opt/oziscript/ozi
chmod +x /opt/oziscript/modules/**/*.sh
```

### Lỗi command not found
```bash
ln -sf /opt/oziscript/ozi /usr/local/bin/ozi
```
