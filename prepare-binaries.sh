#!/bin/bash

# 预下载多架构二进制文件脚本
# 在Docker构建前准备所有架构的二进制文件

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Pre-downloading binaries for all supported architectures..."

# 支持的架构列表
ARCHITECTURES=("amd64" "arm64" "arm")

# 确保下载脚本存在且可执行
if [ ! -f "$SCRIPT_DIR/download-binaries.sh" ]; then
    echo "❌ download-binaries.sh not found!"
    exit 1
fi

chmod +x "$SCRIPT_DIR/download-binaries.sh"

# 为每个架构下载二进制文件
for arch in "${ARCHITECTURES[@]}"; do
    echo ""
    echo "📥 Downloading binaries for $arch..."
    
    if "$SCRIPT_DIR/download-binaries.sh" "$arch" true; then
        echo "✅ Successfully downloaded binaries for $arch"
    else
        echo "⚠️ Failed to download binaries for $arch, but continuing..."
    fi
done

echo ""
echo "📋 Downloaded binary files:"
ls -la "$SCRIPT_DIR"/speederv2_* "$SCRIPT_DIR"/udp2raw_* 2>/dev/null || echo "No binary files found"

echo ""
echo "🎉 Pre-download completed!"
echo ""
echo "You can now build the Docker image with:"
echo "  docker build -t udpspeeder2raw ."
echo "  or"
echo "  ./publish-docker.sh"
