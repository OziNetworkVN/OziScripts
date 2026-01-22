#!/bin/bash
#================================================================
# Ozi Script - Module: System Update
# Mô tả: Kiểm tra và cập nhật Ozi Script từ Git
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"
source "$OZI_DIR/core/config.sh"

#================================================================
# UPDATE FUNCTIONS
#================================================================

# Kiểm tra phiên bản mới
check_for_updates() {
    print_info "Đang kiểm tra phiên bản mới..."
    
    if [[ ! -d "$OZI_DIR/.git" ]]; then
        print_error "Không tìm thấy thư mục .git. Script không được cài đặt qua Git."
        return 1
    fi
    
    # Fetch changes
    cd "$OZI_DIR"
    git fetch -q origin
    
    local local_hash=$(git rev-parse HEAD)
    local remote_hash=$(git rev-parse @{u})
    
    if [[ "$local_hash" == "$remote_hash" ]]; then
        print_success "Bạn đang sử dụng phiên bản mới nhất (v${OZI_VERSION})"
        return 0
    else
        print_warning "Đã có phiên bản mới!"
        local changes=$(git log HEAD..@{u} --oneline)
        echo -e "Các thay đổi mới:\n$changes"
        return 2 # Trả về 2 để báo hiệu có bản cập nhật
    fi
}

# Thực hiện cập nhật
update_script() {
    print_header "CẬP NHẬT OZI SCRIPT"
    
    # Check update status
    check_for_updates
    local status=$?
    
    if [[ $status -eq 0 ]]; then
        return 0
    fi
    
    if ! confirm "Bạn có muốn cập nhật lên phiên bản mới ngay bây giờ?"; then
        return 0
    fi
    
    print_info "Đang sao lưu phiên bản hiện tại..."
    local backup_name="pre-update-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR/updates"
    cp -r "$OZI_DIR" "$BACKUP_DIR/updates/$backup_name"
    print_success "Đã sao lưu vào $BACKUP_DIR/updates/$backup_name"
    
    print_info "Đang tải bản cập nhật..."
    if git pull origin main; then
        print_success "Bản cập nhật đã được tải về thành công!"
        
        # Cập nhật lại quyền
        chmod +x "$OZI_DIR/ozi"
        find "$OZI_DIR" -name "*.sh" -exec chmod +x {} \;
        
        print_success "Cập nhật hoàn tất!"
        print_info "Vui lòng chạy lại lệnh 'ozi' để áp dụng các thay đổi."
        
        # Log update
        log_info "Updated Ozi Script to latest version. Backup: $backup_name"
        
        exit 0
    else
        print_error "Cập nhật thất bại. Đang khôi phục từ bản sao lưu..."
        rm -rf "$OZI_DIR"
        cp -r "$BACKUP_DIR/updates/$backup_name" "$OZI_DIR"
        print_success "Đã khôi phục phiên bản cũ."
        return 1
    fi
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-check}" in
        check)
            check_for_updates
            ;;
        apply)
            update_script
            ;;
        *)
            echo "Sử dụng: $0 {check|apply}"
            ;;
    esac
fi
