# Menu Integration with V2 Site Manager

## Vấn đề

Hệ thống menu ban đầu (`core/menu.sh`) gọi code V1 cũ (`modules/site/manage.sh`), gây ra lỗi khi người dùng tạo website qua menu:

- Menu gọi `create_site_interactive()` từ `manage.sh` (V1)
- V1 code không tương thích với architecture V2
- Script bị dừng/treo tại "TẠO WEBSITE: domain.com"
- Output chỉ hiển thị "/opt/oziscript/" rồi dừng

## Nguyên nhân

```bash
# CŨ - core/menu.sh line 433
handle_website_menu() {
    source "$OZI_DIR/modules/site/manage.sh"  # ❌ V1 code
    case "$choice" in
        1) create_site_interactive ;;          # ❌ V1 function
        2) list_sites ;;                       # ❌ V1 function
        3) delete_site "$domain" ;;            # ❌ V1 function
    esac
}
```

## Giải pháp

Cập nhật menu để gọi V2 Site Manager (`modules/site/manager.sh`):

### 1. Website Menu

```bash
# MỚI - core/menu.sh
handle_website_menu() {
    # Load V2 modules
    source "$OZI_DIR/core/site-db.sh"
    source "$OZI_DIR/modules/site/manager.sh"
    
    case "$choice" in
        1) cmd_create ;;          # ✅ V2 unified creator
        2) cmd_list ;;            # ✅ V2 from database
        3) cmd_delete "$domain" ;; # ✅ V2 complete cleanup
        6) cmd_alias ;;           # ✅ V2 alias management
    esac
}
```

### 2. SSL Menu

```bash
handle_ssl_menu() {
    # Load V2 modules
    source "$OZI_DIR/core/site-db.sh"
    source "$OZI_DIR/modules/site/manager.sh"
    
    case "$choice" in
        1) cmd_ssl "$domain" "install" "cloudflare" ;;
        2) cmd_ssl "$domain" "install" "letsencrypt" ;;
    esac
}
```

## Thay đổi chi tiết

### Website Management Functions

| Menu Option | V1 Function (Cũ) | V2 Function (Mới) | Cải tiến |
|------------|------------------|-------------------|----------|
| 1. Tạo website | `create_site_interactive()` | `cmd_create()` | Type handlers, DB tracking, validation |
| 2. Danh sách | `list_sites()` | `cmd_list()` | From database, complete info |
| 3. Xoá website | `delete_site()` | `cmd_delete()` | 8-step cleanup (PM2, DB, SSL, etc.) |
| 4. Enable/Disable | `enable_site()` / `disable_site()` | `enable_site_nginx()` / `disable_site_nginx()` | Consistent naming |
| 5. Xem logs | `view_site_logs()` | Inline implementation | Simplified |
| 6. Domain alias | `add_domain_alias_interactive()` | `cmd_alias()` | Add/remove/list support |
| 7. List alias | `list_domain_aliases()` | `cmd_alias "$domain" "list"` | Unified command |

### SSL Management Functions

| Menu Option | V1 Function (Cũ) | V2 Function (Mới) | Cải tiến |
|------------|------------------|-------------------|----------|
| 1. Cloudflare SSL | `install_cloudflare_ssl_interactive()` | `cmd_ssl "$domain" "install" "cloudflare"` | Validation, DB tracking |
| 2. Let's Encrypt | `install_letsencrypt_ssl()` | `cmd_ssl "$domain" "install" "letsencrypt"` | Auto-renewal, validation |
| 3. List SSL | `list_ssl_certs()` | Custom query from DB | Real-time status |
| 4. Renew SSL | `renew_ssl_certs()` | Direct `certbot renew` | Simplified |
| 5. Cloudflare API | `configure_cloudflare_api()` | Inline with `config_set` | Config integration |

## Cải tiến chính

### 1. **Centralized Database**
- V1: Đọc từ Nginx configs (`ls $NGINX_SITES_AVAILABLE`)
- V2: Đọc từ JSON database (`/etc/oziscript/sites.db`)
- Lợi ích: Complete info, history tracking, metadata

### 2. **Type Handlers**
- V1: Inline code trong `create_site()`
- V2: Separate handlers (`modules/site/types/{laravel,wordpress,nodejs,static}.sh`)
- Lợi ích: Maintainable, extensible, testable

### 3. **Validation**
- V1: Basic checks
- V2: Comprehensive validation
  - Site existence check before SSL install
  - Domain format validation
  - Port availability check
  - PHP version compatibility

### 4. **Complete Cleanup**
- V1: Chỉ xoá Nginx config và thư mục
- V2: 8-step cleanup process:
  1. Stop PM2/Supervisor processes
  2. Remove database + user
  3. Remove Nginx config + logs
  4. Remove all SSL certificates
  5. Remove website files
  6. Remove DB credentials
  7. Remove site from database
  8. Detailed cleanup report

### 5. **Error Messages**
- V1: Generic errors
- V2: Helpful, actionable messages
  ```bash
  # V2 Example
  ✗ Website 'example.com' chưa tồn tại
  
  Danh sách website hiện có:
    • mysite.com (laravel)
    • blog.com (wordpress)
  
  → Tạo website trước: ozi site create example.com
  ```

## Testing Menu Integration

### Test Case 1: Create Laravel Site
```bash
ozi
# Select: 5) Quản lý Website
# Select: 1) Tạo website mới
# Select: 1) Laravel / PHP
# Domain: test.com
# PHP: 8.3
# Should: Complete successfully with database entry
```

### Test Case 2: List Sites
```bash
ozi
# Select: 5) Quản lý Website
# Select: 2) Danh sách website
# Should: Show all sites from database with complete info
```

### Test Case 3: Install SSL
```bash
ozi
# Select: 6) Quản lý SSL
# Select: 1) Cloudflare SSL
# Domain: test.com (existing)
# Should: Install successfully and update database

# Try non-existing domain:
# Domain: nonexist.com
# Should: Show error with site list
```

### Test Case 4: Delete Site
```bash
ozi
# Select: 5) Quản lý Website
# Select: 3) Xoá website
# Domain: test.com
# Should: Complete 8-step cleanup with report
```

## Backward Compatibility

File V1 cũ (`modules/site/manage.sh`) vẫn tồn tại nhưng **KHÔNG được sử dụng**:
- Menu đã cập nhật gọi V2
- CLI `ozi site` sử dụng V2
- V1 có thể xoá hoặc archive sau khi testing hoàn tất

## Migration Path

Nếu có sites được tạo bằng V1:

### Option 1: Manual migration
```bash
# List old sites
ls /etc/nginx/sites-available/

# For each site, add to database
ozi site create example.com
```

### Option 2: Auto-migration script
```bash
# Create migration tool
ozi migrate v1-to-v2
```

Tính năng này sẽ được implement nếu cần thiết.

## Known Issues & Workarounds

### Issue 1: Old sites không có trong database
**Symptom:** Site hoạt động nhưng không hiện trong `ozi site list`

**Fix:** Re-add site to database:
```bash
ozi site create example.com
# Choose existing directory: yes
```

### Issue 2: Menu vẫn gọi V1 functions
**Symptom:** Function not found errors

**Fix:** Verify menu.sh đã được cập nhật:
```bash
grep -n "modules/site/manage.sh" /opt/oziscript/core/menu.sh
# Should return: no matches

grep -n "modules/site/manager.sh" /opt/oziscript/core/menu.sh
# Should return: line numbers
```

## Files Changed

```
core/menu.sh
├── handle_website_menu()    # Updated to call V2
├── handle_ssl_menu()        # Updated to call V2
└── Dependencies updated

Deprecated (not used):
└── modules/site/manage.sh   # V1 code (keep for reference)
```

## Related Documentation

- [V2 Architecture](../README_V2.md)
- [Workflow Guide](../WORKFLOW_V2.md)
- [Site Manager API](../API_REFERENCE.md#site-manager)
- [Migration Tools](../MIGRATION_V2.md)

## Change Log

**2025-01-XX - Menu V2 Integration**
- Fixed menu routing from V1 to V2
- Updated `handle_website_menu()` to call `cmd_create()`, `cmd_list()`, `cmd_delete()`, `cmd_alias()`
- Updated `handle_ssl_menu()` to call `cmd_ssl()`
- Enhanced error handling in menu options
- Added inline implementations for logs and enable/disable
- Improved user prompts and validation

**Impact:**
- ✅ Menu now uses V2 architecture
- ✅ All menu options fully functional
- ✅ Consistent with CLI workflow
- ✅ Complete site management (create/delete/ssl/alias)

---

**Note:** Sau khi testing hoàn tất, file `modules/site/manage.sh` (V1) có thể được xoá hoặc di chuyển vào `archive/` folder.
