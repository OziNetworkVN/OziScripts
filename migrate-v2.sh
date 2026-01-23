#!/bin/bash
#================================================================
# Ozi Script - V1 to V2 Migration Tool
# Mô tả: Migrate existing V1 sites to V2 architecture
# Phiên bản: 2.0.0
#================================================================

set -euo pipefail

# Load dependencies
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"
source "$OZI_DIR/core/colors.sh"
source "$OZI_DIR/core/site-db.sh"

#================================================================
# MAIN MIGRATION
#================================================================

main() {
    require_root
    
    print_header "Ozi Script V1 → V2 Migration"
    
    echo
    print_warning "⚠ QUAN TRỌNG:"
    echo "  - Tool này sẽ quét tất cả Nginx configs hiện có"
    echo "  - Import vào site database mới (V2)"
    echo "  - Không làm thay đổi configs hoặc files hiện tại"
    echo "  - An toàn cho hệ thống đang chạy"
    echo
    
    if ! confirm "Bắt đầu migration?"; then
        print_info "Đã hủy"
        exit 0
    fi
    
    # Check if jq is installed
    if ! command -v jq >/dev/null 2>&1; then
        print_info "Installing jq..."
        apt-get update -qq
        apt-get install -y jq
    fi
    
    # Initialize site database
    init_site_db
    
    # Run migration
    migrate_existing_sites
    
    # Show results
    echo
    print_separator
    print_header "Migration Statistics"
    
    local stats=$(get_site_stats)
    local total=$(echo "$stats" | jq -r '.total')
    local active=$(echo "$stats" | jq -r '.active')
    local with_ssl=$(echo "$stats" | jq -r '.with_ssl')
    
    echo "Total sites: $total"
    echo "Active sites: $active"
    echo "Sites with SSL: $with_ssl"
    
    echo
    print_subheader "Site Types"
    echo "$stats" | jq -r '.types | to_entries[] | "  \(.key): \(.value)"'
    
    echo
    print_separator
    print_success "✓ Migration completed successfully!"
    
    echo
    print_subheader "Next Steps"
    echo "1. Review migrated sites: ozi site list"
    echo "2. Check site details: ozi site info <domain>"
    echo "3. Start using V2 commands:"
    echo "   - ozi site create"
    echo "   - ozi site ssl install <domain>"
    echo "   - ozi site alias add <domain> <alias>"
    
    echo
    print_info "Site database location: /etc/oziscript/sites.db"
    print_info "Backups location: /etc/oziscript/sites.db.backup.*"
}

# Run
main "$@"
