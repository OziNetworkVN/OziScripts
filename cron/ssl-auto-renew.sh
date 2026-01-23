#!/bin/bash
#================================================================
# Ozi Script - SSL Auto-Renew Cron Job
# Mô tả: Tự động gia hạn SSL sắp hết hạn
# Phiên bản: 2.0.0
# Cron: Daily at 2:00 AM
#================================================================

set -euo pipefail

# Load dependencies
OZI_DIR="/opt/oziscript"
source "$OZI_DIR/core/helpers.sh" 2>/dev/null || true
source "$OZI_DIR/core/colors.sh" 2>/dev/null || true
source "$OZI_DIR/core/ssl-manager.sh" 2>/dev/null || true

# Log file
LOG_FILE="/var/log/oziscript/ssl-auto-renew.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Redirect output to log
exec >> "$LOG_FILE" 2>&1

echo "=================================================="
echo "SSL Auto-Renew - $(date)"
echo "=================================================="

# Run auto-renew
auto_renew_expiring_ssl

echo "Completed at: $(date)"
echo ""
