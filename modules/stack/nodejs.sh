#!/bin/bash
#================================================================
# Ozi Script - Module: Node.js
# Mô tả: Cài đặt Node.js qua NVM (multi-version)
# Phiên bản: 1.0.0
#================================================================

# Load core
OZI_DIR="${OZI_DIR:-/opt/oziscript}"
source "$OZI_DIR/core/helpers.sh"

#================================================================
# CONFIGURATION
#================================================================
NVM_DIR="/opt/nvm"
DEFAULT_NODE_VERSION="20"
SUPPORTED_NODE_VERSIONS=("16" "18" "20" "22")

#================================================================
# INSTALLATION
#================================================================

# Cài đặt NVM
install_nvm() {
    if [[ -d "$NVM_DIR" ]] && [[ -s "$NVM_DIR/nvm.sh" ]]; then
        print_info "NVM đã được cài đặt"
        return 0
    fi
    
    print_info "Đang cài đặt NVM..."
    
    # Download and install NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | NVM_DIR="$NVM_DIR" bash
    
    # Add NVM to profile
    if ! grep -q "NVM_DIR" /etc/profile.d/nvm.sh 2>/dev/null; then
        cat > /etc/profile.d/nvm.sh << EOF
export NVM_DIR="$NVM_DIR"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"
EOF
    fi
    
    print_success "NVM đã được cài đặt"
}

# Load NVM
load_nvm() {
    export NVM_DIR="$NVM_DIR"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
}

# Cài đặt Node.js version
install_nodejs() {
    local version="${1:-$DEFAULT_NODE_VERSION}"
    
    print_header "CÀI ĐẶT NODE.JS ${version}"
    
    # Install NVM first
    install_nvm
    
    # Load NVM
    load_nvm
    
    print_info "Đang cài đặt Node.js ${version}..."
    
    # Install requested version
    nvm install "$version"
    nvm use "$version"
    nvm alias default "$version"
    
    # Create global symlinks
    local node_path=$(which node)
    local npm_path=$(which npm)
    
    ln -sf "$node_path" /usr/local/bin/node
    ln -sf "$npm_path" /usr/local/bin/npm
    
    # Install yarn
    npm install -g yarn 2>/dev/null || true
    
    # Install PM2 if not installed
    if ! command_exists pm2; then
        install_pm2
    fi

    print_success "Node.js $(node -v) đã được cài đặt!"
    print_info "npm: $(npm -v)"
    
    log_info "Installed Node.js $version"
}

# Cài đặt PM2
install_pm2() {
    print_info "Đang cài đặt PM2..."

    if npm install -g pm2; then
        print_success "PM2 đã được cài đặt"
        log_info "Installed PM2"
    else
        print_error "Không thể cài đặt PM2"
    fi
}

# Interactive install
install_nodejs_interactive() {
    print_header "CÀI ĐẶT NODE.JS"
    
    echo "  Các phiên bản Node.js có thể cài đặt:"
    echo ""
    
    local i=1
    for v in "${SUPPORTED_NODE_VERSIONS[@]}"; do
        echo -e "  ${BOLD_CYAN}[$i]${NC} Node.js $v LTS"
        ((i++))
    done
    
    echo ""
    echo -e "  ${BOLD_YELLOW}[0]${NC} Quay lại"
    echo ""
    
    read -p "$(echo -e "${BOLD_WHITE}Chọn phiên bản để cài [0-${#SUPPORTED_NODE_VERSIONS[@]}]: ${NC}")" choice
    
    if [[ "$choice" == "0" ]]; then
        return 0
    fi
    
    if [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#SUPPORTED_NODE_VERSIONS[@]}" ]]; then
        local selected="${SUPPORTED_NODE_VERSIONS[$((choice-1))]}"
        install_nodejs "$selected"
    else
        print_error "Lựa chọn không hợp lệ"
    fi
}

# Liệt kê Node.js versions
list_nodejs_versions() {
    print_header "DANH SÁCH NODE.JS"
    
    load_nvm
    
    echo ""
    if command_exists nvm; then
        nvm list
    else
        if command_exists node; then
            echo -e "  ${BOLD_CYAN}▸ Node.js:${NC} $(node -v)"
            echo -e "  ${BOLD_CYAN}▸ npm:${NC}     $(npm -v)"
        else
            print_warning "Node.js chưa được cài đặt"
        fi
    fi
    echo ""
}

#================================================================
# MAIN
#================================================================
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-}" in
        install)
            install_nodejs "${2:-$DEFAULT_NODE_VERSION}"
            ;;
        pm2)
            install_pm2
            ;;
        list)
            list_nodejs_versions
            ;;
        *)
            install_nodejs_interactive
            ;;
    esac
fi
