#!/bin/bash
#================================================================
# Ozi Script - Setup Git Hooks
# Mô tả: Cài đặt Git hooks để tự động set permissions
#================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$SCRIPT_DIR/.git/hooks"

echo "Setting up Git hooks for auto-permissions..."
echo ""

if [[ ! -d "$HOOKS_DIR" ]]; then
    echo "❌ Error: .git/hooks directory not found"
    echo "   This script must be run from the Git repository root"
    exit 1
fi

# Create post-merge hook
cat > "$HOOKS_DIR/post-merge" << 'EOF'
#!/bin/bash
# Auto-set permissions after git pull/merge
echo "🔧 Setting file permissions..."
chmod +x /opt/oziscript/ozi 2>/dev/null || chmod +x ozi 2>/dev/null || true
find /opt/oziscript -name "*.sh" -exec chmod +x {} \; 2>/dev/null || find . -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
echo "✓ Permissions updated"
EOF

chmod +x "$HOOKS_DIR/post-merge"

# Verify installation
if [[ -x "$HOOKS_DIR/post-merge" ]]; then
    echo "✓ Git post-merge hook installed successfully!"
    echo ""
    echo "Testing hook..."
    bash "$HOOKS_DIR/post-merge"
    echo ""
    echo "Now 'git pull' will automatically set permissions."
else
    echo "❌ Failed to make hook executable"
    exit 1
fi
