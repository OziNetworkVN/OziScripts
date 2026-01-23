#!/bin/bash
#================================================================
# Ozi Script - Setup Git Hooks
# Mô tả: Cài đặt Git hooks để tự động set permissions
#================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$SCRIPT_DIR/.git/hooks"

echo "Setting up Git hooks..."

# Create post-merge hook
cat > "$HOOKS_DIR/post-merge" << 'EOF'
#!/bin/bash
# Auto-set permissions after git pull/merge
echo "🔧 Setting file permissions..."
chmod +x /opt/oziscript/ozi 2>/dev/null || chmod +x ozi 2>/dev/null
find . -name "*.sh" -exec chmod +x {} \; 2>/dev/null
echo "✓ Permissions updated"
EOF

chmod +x "$HOOKS_DIR/post-merge"

echo "✓ Git hooks installed successfully!"
echo ""
echo "Now git pull/reset will automatically set permissions."
