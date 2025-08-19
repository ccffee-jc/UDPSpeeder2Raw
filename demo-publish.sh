#!/bin/bash

# Docker镜像发布演示脚本
# 这个脚本会模拟完整的发布流程（不会实际推送）

set -e

echo "🎯 Docker镜像发布演示"
echo "===================="
echo ""

# 检查当前状态
echo "📋 当前项目状态："
echo "- 项目路径: $(pwd)"
echo "- Git分支: $(git branch --show-current 2>/dev/null || echo 'unknown')"
echo "- Docker版本: $(docker --version)"
echo ""

# 检查二进制文件
echo "📦 已下载的二进制文件："
ls -la speederv2_* udp2raw_* 2>/dev/null || echo "暂无多架构二进制文件"
echo ""

# 检查Docker登录状态
echo "🔐 Docker登录状态："
if docker info 2>/dev/null | grep -q "Username"; then
    echo "✅ 已登录到Docker Registry"
    docker info | grep "Username:" || echo "检测到登录状态"
else
    echo "❌ 未登录到Docker Registry"
    echo "请先运行: echo \$GITHUB_TOKEN | docker login ghcr.io -u ccffee-jc --password-stdin"
fi
echo ""

# 模拟构建过程
echo "🏗️  模拟Docker镜像构建过程："
echo "1. 检查Dockerfile..."
if [ -f "Dockerfile" ]; then
    echo "   ✅ Dockerfile 存在"
    echo "   📄 基础镜像: $(grep "^FROM" Dockerfile | head -1)"
else
    echo "   ❌ Dockerfile 不存在"
    exit 1
fi

echo "2. 检查多架构支持..."
if grep -q "TARGETARCH" Dockerfile; then
    echo "   ✅ 支持多架构构建"
else
    echo "   ❌ 不支持多架构构建"
fi

echo "3. 模拟构建命令..."
echo "   docker buildx build --platform linux/amd64,linux/arm64 \\"
echo "     --tag ghcr.io/ccffee-jc/udpspeeder2raw:latest \\"
echo "     --tag ghcr.io/ccffee-jc/udpspeeder2raw:v1.0.0 \\"
echo "     --push ."
echo ""

# 显示实际的发布步骤
echo "🚀 实际发布步骤："
echo "===================="
echo ""
echo "1. 设置GitHub Token:"
echo "   export GITHUB_TOKEN='你的GitHub Token'"
echo ""
echo "2. 登录Docker Registry:"
echo "   echo \$GITHUB_TOKEN | docker login ghcr.io -u ccffee-jc --password-stdin"
echo ""
echo "3. 发布镜像:"
echo "   # 方法一：使用发布脚本"
echo "   ./publish-docker.sh v1.0.0"
echo ""
echo "   # 方法二：手动构建"
echo "   docker buildx create --name multiarch --use"
echo "   docker buildx build --platform linux/amd64,linux/arm64 \\"
echo "     --tag ghcr.io/ccffee-jc/udpspeeder2raw:latest \\"
echo "     --push ."
echo ""
echo "   # 方法三：推送到GitHub触发自动构建"
echo "   git add ."
echo "   git commit -m 'Release v1.0.0'"
echo "   git tag v1.0.0"
echo "   git push origin master"
echo "   git push origin v1.0.0"
echo ""

# 显示验证步骤
echo "✅ 发布后验证："
echo "=================="
echo ""
echo "1. 检查GitHub Packages:"
echo "   https://github.com/ccffee-jc/UDPSpeeder2Raw/pkgs/container/udpspeeder2raw"
echo ""
echo "2. 测试拉取镜像:"
echo "   docker pull ghcr.io/ccffee-jc/udpspeeder2raw:latest"
echo ""
echo "3. 检查多架构支持:"
echo "   docker buildx imagetools inspect ghcr.io/ccffee-jc/udpspeeder2raw:latest"
echo ""

# 显示用户使用方式
echo "👥 用户使用方式："
echo "=================="
echo ""
echo "1. 直接使用预构建镜像:"
echo "   docker pull ghcr.io/ccffee-jc/udpspeeder2raw:latest"
echo "   docker run -d --name udpspeeder2raw \\"
echo "     --network host \\"
echo "     --cap-add NET_ADMIN \\"
echo "     -v ./config.json:/app/config.json \\"
echo "     -v ./logs:/app/logs \\"
echo "     ghcr.io/ccffee-jc/udpspeeder2raw:latest"
echo ""
echo "2. 使用docker-compose:"
echo "   wget https://raw.githubusercontent.com/ccffee-jc/UDPSpeeder2Raw/master/docker-compose.ghcr.yml"
echo "   docker-compose -f docker-compose.ghcr.yml up -d"
echo ""

echo "🎉 发布演示完成！"
echo ""
echo "💡 提示："
echo "- 首次发布前建议先在本地测试构建"
echo "- 使用语义化版本号 (如 v1.0.0, v1.1.0)"
echo "- 发布后记得更新README中的使用说明"
