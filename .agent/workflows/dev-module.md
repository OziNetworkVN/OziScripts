---
description: Phát triển module Ozi Script mới hoặc sửa module hiện có
---

# Ozi Script Development Workflow

## Bước 1: Xác định module cần phát triển
Kiểm tra `task.md` để xem module nào đang cần làm.

## Bước 2: Tạo file module mới
```bash
# Template file mới
touch packages/oziDebianScript/modules/{category}/{module_name}.sh
```

## Bước 3: Cấu trúc module chuẩn
Mỗi module phải tuân theo cấu trúc sau:

```bash
#!/bin/bash
#================================================================
# Ozi Script - Module: {Tên module}
# Mô tả: {Mô tả ngắn}
#================================================================

# Load core
source "$(dirname "$0")/../../core/helpers.sh"
source "$(dirname "$0")/../../core/colors.sh"

# Hàm chính
module_main() {
    print_header "Tên Module"
    # Logic ở đây
}

# Chạy nếu gọi trực tiếp
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    module_main "$@"
fi
```

## Bước 4: Thêm vào menu chính
Cập nhật file `ozi` để thêm lệnh mới:

```bash
case "$1" in
    new-command)
        source "$OZI_DIR/modules/{category}/{module}.sh"
        module_main "${@:2}"
        ;;
esac
```

## Bước 5: Test trên VPS
// turbo
```bash
# Upload lên VPS
scp -r packages/oziDebianScript root@vps-ip:/opt/
```

## Bước 6: Cập nhật task.md
Đánh dấu [x] cho task đã hoàn thành.
