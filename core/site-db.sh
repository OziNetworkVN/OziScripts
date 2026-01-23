#!/bin/bash
#================================================================
# Ozi Script - Site Database Management
# Mô tả: Quản lý database sites tập trung
# Phiên bản: 2.0.0
#================================================================

set -euo pipefail

# Load dependencies
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh" 2>/dev/null || true
source "$OZI_DIR/core/colors.sh" 2>/dev/null || true

#================================================================
# CONFIGURATION
#================================================================
SITE_DB="/etc/oziscript/sites.db"
SITE_DB_BACKUP="/etc/oziscript/sites.db.backup"

#================================================================
# DATABASE INITIALIZATION
#================================================================

# Khởi tạo database nếu chưa tồn tại
init_site_db() {
    if [[ ! -f "$SITE_DB" ]]; then
        mkdir -p "$(dirname "$SITE_DB")"
        echo '{"sites":{},"version":"2.0.0"}' > "$SITE_DB"
        chmod 600 "$SITE_DB"
    fi
}

# Backup database
backup_site_db() {
    if [[ -f "$SITE_DB" ]]; then
        cp "$SITE_DB" "$SITE_DB_BACKUP.$(date +%Y%m%d_%H%M%S)"
        # Keep only last 10 backups
        ls -t "$SITE_DB_BACKUP".* 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
    fi
}

#================================================================
# CRUD OPERATIONS
#================================================================

# Tạo site mới
create_site_entry() {
    local domain="$1"
    local type="$2"
    local php_version="${3:-}"
    local root="${4:-/var/www/$domain}"
    
    init_site_db
    backup_site_db
    
    # Generate unique ID
    local site_id="site_$(date +%s)_$(echo $RANDOM | md5sum | head -c 8)"
    
    # Create site entry
    local site_json=$(cat <<EOF
{
  "id": "$site_id",
  "domain": "$domain",
  "type": "$type",
  "status": "active",
  "created_at": "$(date -Iseconds)",
  "updated_at": "$(date -Iseconds)",
  "root": "$root",
  "php_version": "$php_version",
  "nginx": {
    "config": "/etc/nginx/sites-available/${domain}.conf",
    "enabled": true
  },
  "ssl": {
    "enabled": false,
    "type": "none",
    "cert_path": "",
    "key_path": "",
    "expires_at": "",
    "auto_renew": false
  },
  "aliases": [],
  "database": {
    "name": "",
    "user": "",
    "type": "none"
  },
  "features": {}
}
EOF
)
    
    # Add to database using jq
    if command -v jq >/dev/null 2>&1; then
        jq --argjson site "$site_json" ".sites[\"$domain\"] = \$site" "$SITE_DB" > "$SITE_DB.tmp"
        mv "$SITE_DB.tmp" "$SITE_DB"
        echo "$site_id"
        return 0
    else
        echo "ERROR: jq is not installed" >&2
        return 1
    fi
}

# Lấy thông tin site
get_site() {
    local domain="$1"
    
    if [[ ! -f "$SITE_DB" ]]; then
        echo "{}"
        return 1
    fi
    
    jq -r ".sites[\"$domain\"] // {}" "$SITE_DB"
}

# Kiểm tra site có tồn tại không
site_exists() {
    local domain="$1"
    local result=$(jq -r ".sites | has(\"$domain\")" "$SITE_DB" 2>/dev/null)
    [[ "$result" == "true" ]]
}

# Cập nhật field của site
update_site_field() {
    local domain="$1"
    local field="$2"
    local value="$3"
    
    if ! site_exists "$domain"; then
        echo "ERROR: Site $domain not found" >&2
        return 1
    fi
    
    backup_site_db
    
    # Update timestamp
    jq ".sites[\"$domain\"].$field = \"$value\" | .sites[\"$domain\"].updated_at = \"$(date -Iseconds)\"" "$SITE_DB" > "$SITE_DB.tmp"
    mv "$SITE_DB.tmp" "$SITE_DB"
}

# Cập nhật nested object
update_site_object() {
    local domain="$1"
    local path="$2"
    local json="$3"
    
    if ! site_exists "$domain"; then
        echo "ERROR: Site $domain not found" >&2
        return 1
    fi
    
    backup_site_db
    
    jq --argjson obj "$json" ".sites[\"$domain\"].$path = \$obj | .sites[\"$domain\"].updated_at = \"$(date -Iseconds)\"" "$SITE_DB" > "$SITE_DB.tmp"
    mv "$SITE_DB.tmp" "$SITE_DB"
}

# Lấy tất cả sites
list_all_sites() {
    if [[ ! -f "$SITE_DB" ]]; then
        echo "[]"
        return
    fi
    
    jq -r '.sites | keys[]' "$SITE_DB" 2>/dev/null || echo "[]"
}

# Lấy sites theo filter
list_sites_by_type() {
    local type="$1"
    jq -r ".sites | to_entries[] | select(.value.type == \"$type\") | .key" "$SITE_DB" 2>/dev/null
}

list_sites_with_ssl() {
    jq -r '.sites | to_entries[] | select(.value.ssl.enabled == true) | .key' "$SITE_DB" 2>/dev/null
}

# Xóa site
delete_site_entry() {
    local domain="$1"
    
    if ! site_exists "$domain"; then
        echo "ERROR: Site $domain not found" >&2
        return 1
    fi
    
    backup_site_db
    
    jq "del(.sites[\"$domain\"])" "$SITE_DB" > "$SITE_DB.tmp"
    mv "$SITE_DB.tmp" "$SITE_DB"
}

#================================================================
# SSL OPERATIONS
#================================================================

# Cập nhật SSL info
update_site_ssl() {
    local domain="$1"
    local ssl_type="$2"
    local cert_path="$3"
    local key_path="$4"
    local expires_at="$5"
    local auto_renew="${6:-false}"
    
    local ssl_json=$(cat <<EOF
{
  "enabled": true,
  "type": "$ssl_type",
  "cert_path": "$cert_path",
  "key_path": "$key_path",
  "expires_at": "$expires_at",
  "auto_renew": $auto_renew
}
EOF
)
    
    update_site_object "$domain" "ssl" "$ssl_json"
}

# Disable SSL
disable_site_ssl() {
    local domain="$1"
    
    local ssl_json=$(cat <<EOF
{
  "enabled": false,
  "type": "none",
  "cert_path": "",
  "key_path": "",
  "expires_at": "",
  "auto_renew": false
}
EOF
)
    
    update_site_object "$domain" "ssl" "$ssl_json"
}

# Lấy sites có SSL sắp hết hạn
get_expiring_ssl_sites() {
    local days="${1:-30}"
    local cutoff_date=$(date -d "+$days days" -Iseconds)
    
    jq -r --arg cutoff "$cutoff_date" '
        .sites | to_entries[] | 
        select(.value.ssl.enabled == true and .value.ssl.expires_at != "" and .value.ssl.expires_at < $cutoff) | 
        "\(.key)|\(.value.ssl.type)|\(.value.ssl.expires_at)"
    ' "$SITE_DB" 2>/dev/null
}

#================================================================
# ALIAS OPERATIONS
#================================================================

# Thêm domain alias
add_site_alias() {
    local domain="$1"
    local alias="$2"
    
    if ! site_exists "$domain"; then
        echo "ERROR: Site $domain not found" >&2
        return 1
    fi
    
    # Check if alias already exists
    local exists=$(jq -r ".sites[\"$domain\"].aliases | any(. == \"$alias\")" "$SITE_DB")
    if [[ "$exists" == "true" ]]; then
        echo "ERROR: Alias $alias already exists" >&2
        return 1
    fi
    
    backup_site_db
    
    jq ".sites[\"$domain\"].aliases += [\"$alias\"] | .sites[\"$domain\"].updated_at = \"$(date -Iseconds)\"" "$SITE_DB" > "$SITE_DB.tmp"
    mv "$SITE_DB.tmp" "$SITE_DB"
}

# Xóa domain alias
remove_site_alias() {
    local domain="$1"
    local alias="$2"
    
    if ! site_exists "$domain"; then
        echo "ERROR: Site $domain not found" >&2
        return 1
    fi
    
    backup_site_db
    
    jq ".sites[\"$domain\"].aliases |= (. - [\"$alias\"]) | .sites[\"$domain\"].updated_at = \"$(date -Iseconds)\"" "$SITE_DB" > "$SITE_DB.tmp"
    mv "$SITE_DB.tmp" "$SITE_DB"
}

# Lấy aliases của site
get_site_aliases() {
    local domain="$1"
    jq -r ".sites[\"$domain\"].aliases[]?" "$SITE_DB" 2>/dev/null
}

#================================================================
# DATABASE OPERATIONS
#================================================================

# Cập nhật database info
update_site_database() {
    local domain="$1"
    local db_name="$2"
    local db_user="$3"
    local db_type="$4"
    
    local db_json=$(cat <<EOF
{
  "name": "$db_name",
  "user": "$db_user",
  "type": "$db_type"
}
EOF
)
    
    update_site_object "$domain" "database" "$db_json"
}

#================================================================
# FEATURES OPERATIONS
#================================================================

# Enable feature
enable_site_feature() {
    local domain="$1"
    local feature="$2"
    
    backup_site_db
    
    jq ".sites[\"$domain\"].features.\"$feature\" = true | .sites[\"$domain\"].updated_at = \"$(date -Iseconds)\"" "$SITE_DB" > "$SITE_DB.tmp"
    mv "$SITE_DB.tmp" "$SITE_DB"
}

# Disable feature
disable_site_feature() {
    local domain="$1"
    local feature="$2"
    
    backup_site_db
    
    jq ".sites[\"$domain\"].features.\"$feature\" = false | .sites[\"$domain\"].updated_at = \"$(date -Iseconds)\"" "$SITE_DB" > "$SITE_DB.tmp"
    mv "$SITE_DB.tmp" "$SITE_DB"
}

#================================================================
# STATISTICS
#================================================================

# Lấy thống kê
get_site_stats() {
    local total=$(jq -r '.sites | length' "$SITE_DB" 2>/dev/null || echo 0)
    local active=$(jq -r '.sites | to_entries[] | select(.value.status == "active") | .key' "$SITE_DB" 2>/dev/null | wc -l)
    local with_ssl=$(jq -r '.sites | to_entries[] | select(.value.ssl.enabled == true) | .key' "$SITE_DB" 2>/dev/null | wc -l)
    
    cat <<EOF
{
  "total": $total,
  "active": $active,
  "with_ssl": $with_ssl,
  "types": $(jq -r '[.sites[].type] | group_by(.) | map({(.[0]): length}) | add // {}' "$SITE_DB" 2>/dev/null)
}
EOF
}

#================================================================
# MIGRATION FROM V1
#================================================================

# Migrate existing sites to database
migrate_existing_sites() {
    print_info "Scanning existing Nginx sites..."
    
    local count=0
    
    if [[ -d /etc/nginx/sites-available ]]; then
        for conf in /etc/nginx/sites-available/*.conf; do
            [[ -f "$conf" ]] || continue
            
            local domain=$(basename "$conf" .conf)
            local server_name=$(grep -Po 'server_name\s+\K[^;]+' "$conf" | head -1 | awk '{print $1}')
            
            # Skip if already exists
            if site_exists "$server_name"; then
                continue
            fi
            
            # Detect type
            local type="static"
            if grep -q "laravel" "$conf" || grep -q "artisan" "$conf"; then
                type="laravel"
            elif grep -q "wordpress" "$conf" || grep -q "wp-content" "$conf"; then
                type="wordpress"
            elif grep -q "proxy_pass" "$conf"; then
                type="nodejs"
            fi
            
            # Detect PHP version
            local php_version=""
            if grep -q "php.*-fpm" "$conf"; then
                php_version=$(grep -Po 'php\K[0-9.]+' "$conf" | head -1)
            fi
            
            # Detect root
            local root=$(grep -Po 'root\s+\K[^;]+' "$conf" | head -1 | tr -d ' ')
            
            # Detect SSL
            local has_ssl=false
            if grep -q "ssl_certificate" "$conf"; then
                has_ssl=true
            fi
            
            # Create entry
            create_site_entry "$server_name" "$type" "$php_version" "$root"
            
            if [[ "$has_ssl" == "true" ]]; then
                local cert_path=$(grep -Po 'ssl_certificate\s+\K[^;]+' "$conf" | head -1 | tr -d ' ')
                local key_path=$(grep -Po 'ssl_certificate_key\s+\K[^;]+' "$conf" | head -1 | tr -d ' ')
                
                if [[ -n "$cert_path" && -n "$key_path" ]]; then
                    # Detect SSL type
                    local ssl_type="custom"
                    if [[ "$cert_path" =~ "letsencrypt" ]]; then
                        ssl_type="letsencrypt"
                    elif [[ "$cert_path" =~ "oziscript" ]]; then
                        ssl_type="cloudflare"
                    fi
                    
                    # Get expiry date
                    local expires_at=""
                    if [[ -f "$cert_path" ]]; then
                        expires_at=$(openssl x509 -enddate -noout -in "$cert_path" 2>/dev/null | cut -d= -f2)
                        expires_at=$(date -d "$expires_at" -Iseconds 2>/dev/null || echo "")
                    fi
                    
                    update_site_ssl "$server_name" "$ssl_type" "$cert_path" "$key_path" "$expires_at" "false"
                fi
            fi
            
            ((count++))
            print_success "Imported: $server_name ($type)"
        done
    fi
    
    print_success "Migrated $count sites to database"
}

#================================================================
# EXPORT
#================================================================

# Export functions for other modules
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    export -f init_site_db
    export -f create_site_entry
    export -f get_site
    export -f site_exists
    export -f update_site_field
    export -f update_site_object
    export -f list_all_sites
    export -f delete_site_entry
    export -f update_site_ssl
    export -f disable_site_ssl
    export -f get_expiring_ssl_sites
    export -f add_site_alias
    export -f remove_site_alias
    export -f get_site_aliases
    export -f update_site_database
    export -f enable_site_feature
    export -f disable_site_feature
    export -f get_site_stats
    export -f migrate_existing_sites
fi
