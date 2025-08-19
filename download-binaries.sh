#!/bin/bash

# 多架构二进制文件下载脚本
# 用于下载UDPspeeder和UDP2Raw的对应架构版本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCH=${1:-$(uname -m)}
FORCE_DOWNLOAD=${2:-false}

# 版本配置
SPEEDERV2_VERSION="20230206.0"
UDP2RAW_VERSION="20200818.0"

# 架构映射
get_speederv2_arch() {
    case "$1" in
        x86_64|amd64) echo "x86_64" ;;
        aarch64|arm64) echo "aarch64" ;;
        armv7l|arm) echo "arm" ;;
        *) echo "x86_64" ;; # 默认使用x86_64
    esac
}

get_udp2raw_arch() {
    case "$1" in
        x86_64|amd64) echo "x86_64" ;;
        aarch64|arm64) echo "arm" ;;
        armv7l|arm) echo "arm" ;;
        *) echo "x86_64" ;; # 默认使用x86_64
    esac
}

download_speederv2() {
    local arch=$(get_speederv2_arch "$1")
    local output_file="$SCRIPT_DIR/speederv2_${1}"
    
    if [ -f "$output_file" ] && [ "$FORCE_DOWNLOAD" != "true" ]; then
        echo "✅ UDPspeeder ($arch) already exists: $output_file"
        return 0
    fi
    
    echo "📥 Downloading UDPspeeder for $arch..."
    
    local temp_dir=$(mktemp -d)
    local download_url="https://github.com/wangyu-/UDPspeeder/releases/download/${SPEEDERV2_VERSION}/speederv2_binaries.tar.gz"
    
    if curl -L -o "$temp_dir/speederv2.tar.gz" "$download_url"; then
        cd "$temp_dir"
        tar -xzf speederv2.tar.gz
        
        # 查找对应架构的文件
        local binary_file=$(find . -name "*${arch}*" -type f -executable | head -1)
        
        if [ -n "$binary_file" ] && [ -f "$binary_file" ]; then
            cp "$binary_file" "$output_file"
            chmod +x "$output_file"
            echo "✅ Downloaded UDPspeeder: $output_file"
        else
            echo "❌ Could not find UDPspeeder binary for $arch"
            return 1
        fi
    else
        echo "❌ Failed to download UDPspeeder"
        return 1
    fi
    
    rm -rf "$temp_dir"
}

download_udp2raw() {
    local arch=$(get_udp2raw_arch "$1")
    local output_file="$SCRIPT_DIR/udp2raw_${1}"
    
    if [ -f "$output_file" ] && [ "$FORCE_DOWNLOAD" != "true" ]; then
        echo "✅ UDP2Raw ($arch) already exists: $output_file"
        return 0
    fi
    
    echo "📥 Downloading UDP2Raw for $arch..."
    
    local temp_dir=$(mktemp -d)
    local download_url="https://github.com/wangyu-/udp2raw/releases/download/${UDP2RAW_VERSION}/udp2raw_binaries.tar.gz"
    
    if curl -L -o "$temp_dir/udp2raw.tar.gz" "$download_url"; then
        cd "$temp_dir"
        tar -xzf udp2raw.tar.gz
        
        # 查找对应架构的文件
        local binary_file=$(find . -name "*${arch}*" -type f -executable | head -1)
        
        if [ -n "$binary_file" ] && [ -f "$binary_file" ]; then
            cp "$binary_file" "$output_file"
            chmod +x "$output_file"
            echo "✅ Downloaded UDP2Raw: $output_file"
        else
            echo "❌ Could not find UDP2Raw binary for $arch"
            return 1
        fi
    else
        echo "❌ Failed to download UDP2Raw"
        return 1
    fi
    
    rm -rf "$temp_dir"
}

show_usage() {
    echo "Usage: $0 [ARCH] [FORCE]"
    echo ""
    echo "ARCH: Target architecture (amd64, arm64, arm, x86_64, aarch64, armv7l)"
    echo "FORCE: Set to 'true' to force re-download existing files"
    echo ""
    echo "Examples:"
    echo "  $0                    # Download for current architecture"
    echo "  $0 arm64              # Download for arm64"
    echo "  $0 amd64 true         # Force download for amd64"
    echo ""
    echo "Supported architectures:"
    echo "  - amd64/x86_64: Intel/AMD 64-bit"
    echo "  - arm64/aarch64: ARM 64-bit"
    echo "  - arm/armv7l: ARM 32-bit"
}

main() {
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi
    
    echo "🚀 Multi-architecture Binary Downloader"
    echo "Target architecture: $ARCH"
    echo "Force download: $FORCE_DOWNLOAD"
    echo ""
    
    # 下载UDPspeeder
    if download_speederv2 "$ARCH"; then
        echo "✅ UDPspeeder download completed"
    else
        echo "❌ UDPspeeder download failed"
        exit 1
    fi
    
    echo ""
    
    # 下载UDP2Raw
    if download_udp2raw "$ARCH"; then
        echo "✅ UDP2Raw download completed"
    else
        echo "❌ UDP2Raw download failed"
        exit 1
    fi
    
    echo ""
    echo "🎉 All binaries downloaded successfully!"
    echo ""
    echo "Files created:"
    ls -la "$SCRIPT_DIR"/speederv2_* "$SCRIPT_DIR"/udp2raw_* 2>/dev/null || true
}

main "$@"
