#!/bin/bash

# Docker镜像发布脚本
# 用于手动构建和推送镜像到GitHub Container Registry

set -e

REGISTRY="ghcr.io"
REPOSITORY="ccffee-jc/udpspeeder2raw"
VERSION=${1:-latest}

echo "🚀 开始构建和发布Docker镜像..."
echo "📦 镜像: $REGISTRY/$REPOSITORY:$VERSION"

# 检查是否登录到GHCR
echo "🔐 检查Docker登录状态..."
if ! docker info | grep -q "Username"; then
    echo "❌ 请先登录到GitHub Container Registry:"
    echo "   echo \$GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin"
    exit 1
fi

# 创建构建器（如果不存在）
echo "🔧 设置Docker Buildx..."
docker buildx create --name multiarch --use 2>/dev/null || docker buildx use multiarch 2>/dev/null || true

# 构建多架构镜像并推送
echo "🏗️  构建多架构镜像..."
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --tag "$REGISTRY/$REPOSITORY:$VERSION" \
    --tag "$REGISTRY/$REPOSITORY:latest" \
    --build-arg BUILDTIME=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
    --build-arg VERSION=$VERSION \
    --push \
    .

echo "✅ 镜像发布成功!"
echo "📋 可用标签:"
echo "   $REGISTRY/$REPOSITORY:$VERSION"
echo "   $REGISTRY/$REPOSITORY:latest"
echo ""
echo "📖 使用方法:"
echo "   docker pull $REGISTRY/$REPOSITORY:$VERSION"
echo "   docker-compose -f docker-compose.ghcr.yml up -d"
