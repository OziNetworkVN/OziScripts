#!/bin/bash
#================================================================
# Ozi Script - Module: System Update
# Mô tả: Kiểm tra và cập nhật Ozi Script từ Git
# Phiên bản: 1.0.2
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"
source "$OZI_DIR/core/config.sh"

#================================================================
# UPDATE FUNCTIONS
#================================================================

# Kiểm tra phiên bản mới từ GitHub
get_remote_version() {
    cd "$OZI_DIR" 2>/dev/null || return 1
    git fetch -q origin 2>/dev/null || return 1
    
    # Get version from remote ozi file
    local remote_version=$(git show origin/main:ozi 2>/dev/null | grep '^OZI_VERSION=' | cut -d'"' -f2)
    echo "$remote_version"
}

# So sánh version
compare_versions() {
    local v1="$1"
    local v2="$2"
    
    # Convert version to comparable number (1.0.1 -> 10001)
    local v1_num=$(echo "$v1" | awk -F. '{printf "%d%03d%03d", $1, $2, $3}')
    local v2_num=$(echo "$v2" | awk -F. '{printf "%d%03d%03d", $1, $2, $3}')
    
    if [[ $v1_num -lt $v2_num ]]; then
        return 1  # v1 < v2 (có bản mới hơn)
    else
        return 0  # v1 >= v2
    fi
}

# Kiểm tra phiên bản mới
check_for_updates() {
    local silent="${1:-false}"
    
    [[ "$silent" != "true" ]] && print_info "Đang kiểm tra phiên bản mới..."
    
    if [[ ! -d "$OZI_DIR/.git" ]]; then
        [[ "$silent" != "true" ]] && print_error "Không tìm thấy thư mục .git. Script không được cài đặt qua Git."
        return 1
    fi
    
    # Get remote version
    local remote_version=$(get_remote_version)
    
    if [[ -z "$remote_version" ]]; then
        [[ "$silent" != "true" ]] && print_error "Không thể kiểm tra phiên bản từ GitHub."
        return 1
    fi
    
    # Compare versions
    if compare_versions "$OZI_VERSION" "$remote_version"; then
        [[ "$silent" != "true" ]] && print_success "Bạn đang sử dụng phiên bản mới nhất (v${OZI_VERSION})"
        return 0
    else
        if [[ "$silent" != "true" ]]; then
            print_warning "Đã có phiên bản mới: v${remote_version} (hiện tại: v${OZI_VERSION})"
            echo ""
            
            # Show changelog
            cd "$OZI_DIR"
            local changes=$(git log HEAD..origin/main --oneline --pretty=format:"  • %s" | head -10)
            if [[ -n "$changes" ]]; then
                echo -e "${BOLD_CYAN}Các thay đổi mới:${NC}"
                echo "$changes"
                echo ""
            fi
        fi
        return 2 # Có bản cập nhật
    fi
}

# Tự động cập nhật (gọi khi khởi động)
auto_update_check() {
    # Kiểm tra silent mode - không hiển thị lỗi
    check_for_updates true 2>/dev/null
    local status=$?
    
    if [[ $status -eq 2 ]]; then
        # Có bản cập nhật mới
        local remote_version=$(get_remote_version 2>/dev/null)
        
        if [[ -z "$remote_version" ]]; then
            # Không lấy được version, bỏ qua
            return 0
        fi
        
        echo ""
        print_warning "⚠ Phát hiện phiên bản mới: v${remote_version} (hiện tại: v${OZI_VERSION})"
        echo ""
        
        if confirm "Bạn có muốn cập nhật ngay bây giờ?"; then
            update_script_silent
        else
            print_info "Bạn có thể cập nhật sau bằng lệnh: ozi update"
            echo ""
        fi
    fi
}

# Thực hiện cập nhật (silent mode - không hiển thị header)
update_script_silent() {
    print_info "Đang sao lưu phiên bản hiện tại..."
    local backup_dir="/tmp/oziscript-backup"
    mkdir -p "$backup_dir"
    local backup_name="pre-update-$(date +%Y%m%d-%H%M%S)"
    cp -r "$OZI_DIR" "$backup_dir/$backup_name" 2>/dev/null
    
    print_info "Đang tải bản cập nhật..."
    cd "$OZI_DIR"
    
    if git pull origin main 2>/dev/null; then
        # Cập nhật lại quyền
        chmod +x "$OZI_DIR/ozi" 2>/dev/null
        find "$OZI_DIR" -name "*.sh" -exec chmod +x {} \; 2>/dev/null
        
        print_success "✓ Cập nhật thành công lên phiên bản mới!"
        print_info "Khởi động lại menu..."
        echo ""
        sleep 2
        
        # Reload script
        exec "$OZI_DIR/ozi"
    else
        print_error "Cập nhật thất bại. Giữ nguyên phiên bản hiện tại."
        return 1
    fi
}

# Thực hiện cập nhật (interactive mode - với header)
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
            check_for_updates false
            ;;
        apply|update)
            update_script
            ;;
        auto)
            auto_update_check
            ;;
        *)
            echo "Sử dụng: $0 {check|apply}"
            ;;
    esac
fi
