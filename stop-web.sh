#!/bin/bash

# 停止 UDPSpeeder2Raw Web 界面
echo "正在停止 UDPSpeeder2Raw Web 界面..."

# 检查 Docker Compose 是否安装
if ! command -v docker-compose &> /dev/null; then
    echo "错误: Docker Compose 未安装"
    exit 1
fi

# 停止服务
echo "正在停止容器..."
docker-compose down

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ UDPSpeeder2Raw Web 界面已停止"
    echo ""
else
    echo "❌ 停止失败，请检查错误信息"
    exit 1
fi
