#!/bin/bash

# 启动 UDPSpeeder2Raw Web 界面
echo "正在启动 UDPSpeeder2Raw Web 界面..."

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "错误: Docker 未安装，请先安装 Docker"
    exit 1
fi

# 检查 Docker Compose 是否安装
if ! command -v docker-compose &> /dev/null; then
    echo "错误: Docker Compose 未安装，请先安装 Docker Compose"
    exit 1
fi

# 创建必要的目录
mkdir -p logs client_out

# 设置权限
chmod 755 logs client_out

# 启动服务
echo "正在构建和启动容器..."
docker-compose up -d --build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ UDPSpeeder2Raw Web 界面启动成功！"
    echo ""
    echo "访问地址: http://localhost:3000"
    echo ""
    echo "常用命令："
    echo "  查看日志: docker-compose logs -f"
    echo "  停止服务: docker-compose down"
    echo "  重启服务: docker-compose restart"
    echo ""
else
    echo "❌ 启动失败，请检查错误信息"
    exit 1
fi
