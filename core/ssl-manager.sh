#!/bin/bash
#================================================================
# Ozi Script - SSL Lifecycle Manager
# Mô tả: Quản lý vòng đời SSL tập trung
# Phiên bản: 2.0.0
#================================================================

set -euo pipefail

# Load dependencies
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh" 2>/dev/null || true
source "$OZI_DIR/core/colors.sh" 2>/dev/null || true
source "$OZI_DIR/core/site-db.sh" 2>/dev/null || true
source "$OZI_DIR/core/nginx.sh" 2>/dev/null || true

#================================================================
# CONFIGURATION
#================================================================
SSL_BASE_DIR="/etc/oziscript/ssl"
LETSENCRYPT_DIR="/etc/letsencrypt/live"
CLOUDFLARE_DIR="$SSL_BASE_DIR/cloudflare"
CUSTOM_DIR="$SSL_BASE_DIR/custom"

#================================================================
# SSL DIRECTORY SETUP
#================================================================

init_ssl_dirs() {
    mkdir -p "$SSL_BASE_DIR" "$CLOUDFLARE_DIR" "$CUSTOM_DIR"
    chmod 700 "$SSL_BASE_DIR"
}

#================================================================
# LET'S ENCRYPT SSL
#================================================================

install_letsencrypt_ssl() {
    local domain="$1"
    local email="${2:-}"
    
    # Install certbot if not exists
    if ! command -v certbot >/dev/null 2>&1; then
        print_info "Installing Certbot..."
        apt-get update -qq
        apt-get install -y certbot python3-certbot-nginx
    fi
    
    # Stop Nginx temporarily
    systemctl stop nginx
    
    # Request certificate
    local certbot_cmd="certbot certonly --standalone -d $domain"
    
    if [[ -n "$email" ]]; then
        certbot_cmd="$certbot_cmd --email $email --agree-tos --non-interactive"
    else
        certbot_cmd="$certbot_cmd --register-unsafely-without-email --agree-tos --non-interactive"
    fi
    
    if $certbot_cmd; then
        # Start Nginx
        systemctl start nginx
        
        # Get cert paths
        local cert_path="$LETSENCRYPT_DIR/$domain/fullchain.pem"
        local key_path="$LETSENCRYPT_DIR/$domain/privkey.pem"
        
        # Get expiry date
        local expires_at=$(openssl x509 -enddate -noout -in "$cert_path" | cut -d= -f2)
        expires_at=$(date -d "$expires_at" -Iseconds)
        
        # Update site database
        update_site_ssl "$domain" "letsencrypt" "$cert_path" "$key_path" "$expires_at" "true"
        
        # Update Nginx config
        add_ssl_to_config "$domain" "$cert_path" "$key_path"
        
        # Test and reload
        if test_nginx_config >/dev/null 2>&1; then
            reload_nginx
            return 0
        else
            print_error "Nginx config test failed"
            return 1
        fi
    else
        systemctl start nginx
        return 1
    fi
}

#================================================================
# CLOUDFLARE ORIGIN SSL
#================================================================

install_cloudflare_ssl() {
    local domain="$1"
    local cert_content="$2"
    local key_content="$3"
    
    init_ssl_dirs
    
    local domain_dir="$CLOUDFLARE_DIR/$domain"
    mkdir -p "$domain_dir"
    chmod 700 "$domain_dir"
    
    local cert_path="$domain_dir/cert.pem"
    local key_path="$domain_dir/key.pem"
    
    # Write certificate
    echo "$cert_content" > "$cert_path"
    chmod 600 "$cert_path"
    
    # Write private key
    echo "$key_content" > "$key_path"
    chmod 600 "$key_path"
    
    # Validate certificate
    if ! openssl x509 -in "$cert_path" -noout 2>/dev/null; then
        print_error "Invalid certificate"
        rm -rf "$domain_dir"
        return 1
    fi
    
    # Get expiry date (Cloudflare Origin = 15 years)
    local expires_at=$(openssl x509 -enddate -noout -in "$cert_path" | cut -d= -f2)
    expires_at=$(date -d "$expires_at" -Iseconds)
    
    # Update site database
    update_site_ssl "$domain" "cloudflare" "$cert_path" "$key_path" "$expires_at" "false"
    
    # Update Nginx config
    add_ssl_to_config "$domain" "$cert_path" "$key_path"
    
    # Test and reload
    if test_nginx_config >/dev/null 2>&1; then
        reload_nginx
        return 0
    else
        print_error "Nginx config test failed"
        return 1
    fi
}

#================================================================
# CUSTOM SSL
#================================================================

install_custom_ssl() {
    local domain="$1"
    local cert_content="$2"
    local key_content="$3"
    
    init_ssl_dirs
    
    local domain_dir="$CUSTOM_DIR/$domain"
    mkdir -p "$domain_dir"
    chmod 700 "$domain_dir"
    
    local cert_path="$domain_dir/cert.pem"
    local key_path="$domain_dir/key.pem"
    
    # Write certificate
    echo "$cert_content" > "$cert_path"
    chmod 600 "$cert_path"
    
    # Write private key
    echo "$key_content" > "$key_path"
    chmod 600 "$key_path"
    
    # Validate certificate
    if ! openssl x509 -in "$cert_path" -noout 2>/dev/null; then
        print_error "Invalid certificate"
        rm -rf "$domain_dir"
        return 1
    fi
    
    # Get expiry date
    local expires_at=$(openssl x509 -enddate -noout -in "$cert_path" | cut -d= -f2)
    expires_at=$(date -d "$expires_at" -Iseconds)
    
    # Update site database
    update_site_ssl "$domain" "custom" "$cert_path" "$key_path" "$expires_at" "false"
    
    # Update Nginx config
    add_ssl_to_config "$domain" "$cert_path" "$key_path"
    
    # Test and reload
    if test_nginx_config >/dev/null 2>&1; then
        reload_nginx
        return 0
    else
        print_error "Nginx config test failed"
        return 1
    fi
}

#================================================================
# SSL REMOVAL
#================================================================

remove_ssl() {
    local domain="$1"
    
    # Get SSL info from database
    local ssl_type=$(get_site "$domain" | jq -r '.ssl.type')
    local cert_path=$(get_site "$domain" | jq -r '.ssl.cert_path')
    
    # Remove from Nginx config (regenerate without SSL)
    local site_type=$(get_site "$domain" | jq -r '.type')
    local root=$(get_site "$domain" | jq -r '.root')
    
    case "$site_type" in
        laravel)
            local php_version=$(get_site "$domain" | jq -r '.php_version')
            generate_nginx_config "$domain" "$site_type" "$root" "$php_version"
            ;;
        wordpress)
            local php_version=$(get_site "$domain" | jq -r '.php_version')
            generate_nginx_config "$domain" "$site_type" "$root" "$php_version"
            ;;
        nodejs)
            local port=$(get_site "$domain" | jq -r '.features.nodejs_port // "3000"')
            generate_nginx_config "$domain" "$site_type" "$port" "$root"
            ;;
        static)
            generate_nginx_config "$domain" "$site_type" "$root"
            ;;
    esac
    
    # Remove SSL files
    if [[ "$ssl_type" == "letsencrypt" ]]; then
        certbot delete --cert-name "$domain" --non-interactive 2>/dev/null || true
    elif [[ "$ssl_type" == "cloudflare" ]]; then
        rm -rf "$CLOUDFLARE_DIR/$domain"
    elif [[ "$ssl_type" == "custom" ]]; then
        rm -rf "$CUSTOM_DIR/$domain"
    fi
    
    # Update database
    disable_site_ssl "$domain"
    
    # Reload Nginx
    test_nginx_config >/dev/null 2>&1 && reload_nginx
}

#================================================================
# SSL RENEWAL
#================================================================

renew_letsencrypt_ssl() {
    local domain="$1"
    
    if ! command -v certbot >/dev/null 2>&1; then
        print_error "Certbot not installed"
        return 1
    fi
    
    # Renew certificate
    if certbot renew --cert-name "$domain" --non-interactive; then
        # Update expiry date in database
        local cert_path="$LETSENCRYPT_DIR/$domain/fullchain.pem"
        local expires_at=$(openssl x509 -enddate -noout -in "$cert_path" | cut -d= -f2)
        expires_at=$(date -d "$expires_at" -Iseconds)
        
        update_site_field "$domain" "ssl.expires_at" "$expires_at"
        
        # Reload Nginx
        reload_nginx
        return 0
    else
        return 1
    fi
}

auto_renew_expiring_ssl() {
    print_header "Auto-Renew SSL Certificates"
    
    # Get sites with SSL expiring in 30 days
    local expiring_sites=$(get_expiring_ssl_sites 30)
    
    if [[ -z "$expiring_sites" ]]; then
        print_info "No SSL certificates expiring soon"
        return 0
    fi
    
    local renewed=0
    local failed=0
    
    while IFS='|' read -r domain ssl_type expires_at; do
        print_info "Renewing SSL for: $domain (Type: $ssl_type, Expires: $expires_at)"
        
        if [[ "$ssl_type" == "letsencrypt" ]]; then
            if renew_letsencrypt_ssl "$domain"; then
                print_success "Renewed: $domain"
                ((renewed++))
            else
                print_error "Failed to renew: $domain"
                ((failed++))
            fi
        else
            print_warning "Manual renewal required for: $domain (Type: $ssl_type)"
        fi
    done <<< "$expiring_sites"
    
    print_separator
    print_success "Renewed: $renewed certificates"
    [[ $failed -gt 0 ]] && print_error "Failed: $failed certificates"
}

#================================================================
# SSL STATUS
#================================================================

check_ssl_status() {
    local domain="$1"
    
    if ! site_exists "$domain"; then
        print_error "Site not found: $domain"
        return 1
    fi
    
    local ssl_enabled=$(get_site "$domain" | jq -r '.ssl.enabled')
    
    if [[ "$ssl_enabled" != "true" ]]; then
        print_info "SSL is not enabled for $domain"
        return 0
    fi
    
    local ssl_type=$(get_site "$domain" | jq -r '.ssl.type')
    local cert_path=$(get_site "$domain" | jq -r '.ssl.cert_path')
    local expires_at=$(get_site "$domain" | jq -r '.ssl.expires_at')
    
    print_subheader "SSL Status: $domain"
    echo "Type: $ssl_type"
    echo "Certificate: $cert_path"
    echo "Expires: $expires_at"
    
    # Check days until expiry
    if [[ -n "$expires_at" ]]; then
        local expires_epoch=$(date -d "$expires_at" +%s)
        local now_epoch=$(date +%s)
        local days_left=$(( ($expires_epoch - $now_epoch) / 86400 ))
        
        echo "Days remaining: $days_left"
        
        if [[ $days_left -lt 7 ]]; then
            print_error "⚠ SSL expires in less than 7 days!"
        elif [[ $days_left -lt 30 ]]; then
            print_warning "⚠ SSL expires in less than 30 days"
        else
            print_success "✓ SSL is valid"
        fi
    fi
}

list_all_ssl() {
    print_header "SSL Certificates Status"
    
    local sites=$(list_sites_with_ssl)
    
    if [[ -z "$sites" ]]; then
        print_info "No sites with SSL found"
        return 0
    fi
    
    printf "${BOLD_WHITE}%-30s %-15s %-25s %-10s${NC}\n" "Domain" "Type" "Expires" "Status"
    print_separator
    
    while read -r domain; do
        local ssl_type=$(get_site "$domain" | jq -r '.ssl.type')
        local expires_at=$(get_site "$domain" | jq -r '.ssl.expires_at')
        
        # Calculate days remaining
        local status="Valid"
        local color="${GREEN}"
        
        if [[ -n "$expires_at" ]]; then
            local expires_epoch=$(date -d "$expires_at" +%s 2>/dev/null || echo 0)
            local now_epoch=$(date +%s)
            local days_left=$(( ($expires_epoch - $now_epoch) / 86400 ))
            
            if [[ $days_left -lt 0 ]]; then
                status="Expired"
                color="${RED}"
            elif [[ $days_left -lt 7 ]]; then
                status="Critical"
                color="${RED}"
            elif [[ $days_left -lt 30 ]]; then
                status="Warning"
                color="${YELLOW}"
            fi
        fi
        
        printf "${color}%-30s %-15s %-25s %-10s${NC}\n" \
            "$domain" "$ssl_type" "${expires_at:-N/A}" "$status"
    done <<< "$sites"
}

#================================================================
# EXPORT
#================================================================

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    export -f install_letsencrypt_ssl
    export -f install_cloudflare_ssl
    export -f install_custom_ssl
    export -f remove_ssl
    export -f renew_letsencrypt_ssl
    export -f auto_renew_expiring_ssl
    export -f check_ssl_status
    export -f list_all_ssl
fi
