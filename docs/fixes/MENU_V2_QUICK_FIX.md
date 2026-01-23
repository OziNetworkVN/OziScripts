# Menu V2 Integration - Quick Reference

## Vấn đề đã fix

**Triệu chứng:** Khi tạo website qua menu, script bị dừng tại "TẠO WEBSITE: domain.com" và chỉ hiển thị "/opt/oziscript/"

**Nguyên nhân:** Menu system vẫn gọi code V1 cũ (`modules/site/manage.sh`) thay vì V2 Site Manager mới

**Ảnh hưởng:** Người dùng không thể tạo website qua menu (giao diện chính)

## Giải pháp

### Thay đổi chính

```bash
# TRƯỚC (V1)
source "$OZI_DIR/modules/site/manage.sh"  # ❌
create_site_interactive                    # ❌

# SAU (V2)
source "$OZI_DIR/core/site-db.sh"         # ✅
source "$OZI_DIR/modules/site/manager.sh" # ✅
cmd_create                                 # ✅
```

### Files đã sửa

- **core/menu.sh**
  - `handle_website_menu()` - Gọi V2 manager functions
  - `handle_ssl_menu()` - Sử dụng V2 SSL commands
  - Enable/disable - Dùng `core/nginx.sh` functions

### Mapping V1 → V2

| V1 Function | V2 Function | Menu Option |
|------------|-------------|-------------|
| `create_site_interactive()` | `cmd_create()` | 1. Tạo website mới |
| `list_sites()` | `cmd_list()` | 2. Danh sách website |
| `delete_site()` | `cmd_delete()` | 3. Xoá website |
| `add_domain_alias_interactive()` | `cmd_alias()` | 6. Thêm domain alias |
| `install_cloudflare_ssl_interactive()` | `cmd_ssl "$domain" "install" "cloudflare"` | SSL menu: Cloudflare |
| `install_letsencrypt_ssl()` | `cmd_ssl "$domain" "install" "letsencrypt"` | SSL menu: Let's Encrypt |

## Testing

### Test nhanh
```bash
# 1. Tạo Laravel site
ozi
# → 5) Quản lý Website
# → 1) Tạo website mới
# → 1) Laravel / PHP
# → Domain: test.com
# → PHP: 8.3
# Kết quả: Tạo thành công với database entry

# 2. Kiểm tra danh sách
ozi site list
# Kết quả: Hiển thị test.com

# 3. Cài SSL
ozi
# → 6) Quản lý SSL
# → 2) Let's Encrypt SSL
# → Domain: test.com
# Kết quả: Cài SSL thành công

# 4. Xoá site
ozi
# → 5) Quản lý Website
# → 3) Xoá website
# → Domain: test.com
# Kết quả: 8-step cleanup completed
```

## Lợi ích

✅ **Centralized Database**: Tất cả thông tin site lưu trong JSON database  
✅ **Complete Cleanup**: 8-step deletion (PM2, DB, SSL, files, etc.)  
✅ **Better Validation**: Kiểm tra site exists trước khi cài SSL  
✅ **Consistent Workflow**: CLI và Menu đều dùng cùng V2 code  
✅ **Type Handlers**: Laravel, WordPress, Node.js, Static riêng biệt  
✅ **Error Messages**: Thông báo lỗi rõ ràng, actionable  

## Rollback (nếu cần)

Nếu gặp vấn đề với V2, có thể rollback:

```bash
cd /opt/oziscript
git checkout 6955345  # Commit trước khi integrate menu
./install.sh
```

Hoặc edit `core/menu.sh` thủ công để gọi lại V1:
```bash
source "$OZI_DIR/modules/site/manage.sh"  # Restore V1
```

## Documentation

Chi tiết đầy đủ: [docs/fixes/menu-v2-integration.md](./menu-v2-integration.md)

## Changelog

**2025-01-XX - Menu V2 Integration**
- Fixed: Menu routing from V1 to V2
- Updated: `handle_website_menu()` and `handle_ssl_menu()`
- Added: Comprehensive error handling
- Created: Integration documentation

**Commit:** `33ea2ec` - fix: Integrate menu system with V2 Site Manager  
**Previous:** `6955345` - fix: Improve site deletion and SSL validation workflow
