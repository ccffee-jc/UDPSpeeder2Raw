#!/bin/bash

# UDPSpeeder2Raw Web 管理脚本
# 用法: ./manage.sh [start|stop|restart|status|logs|update]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

show_usage() {
    echo "UDPSpeeder2Raw Web 管理脚本"
    echo ""
    echo "用法: $0 [命令]"
    echo ""
    echo "可用命令:"
    echo "  start     启动服务"
    echo "  stop      停止服务"
    echo "  restart   重启服务"
    echo "  status    查看服务状态"
    echo "  logs      查看服务日志"
    echo "  update    更新并重启服务"
    echo "  build     重新构建镜像"
    echo ""
    echo "示例:"
    echo "  $0 start    # 启动服务"
    echo "  $0 logs     # 查看日志"
    echo ""
}

check_requirements() {
    if ! command -v docker &> /dev/null; then
        echo "错误: Docker 未安装，请先安装 Docker"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        echo "错误: Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi

    if [ ! -f "$COMPOSE_FILE" ]; then
        echo "错误: docker-compose.yml 文件不存在"
        exit 1
    fi
}

start_service() {
    echo "正在启动 UDPSpeeder2Raw Web 界面..."
    
    # 创建必要的目录
    mkdir -p logs client_out
    chmod 755 logs client_out
    
    # 启动服务
    docker-compose up -d --build
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ 服务启动成功！"
        echo ""
        echo "访问地址: http://localhost:3000"
        echo ""
        echo "管理命令："
        echo "  查看日志: $0 logs"
        echo "  停止服务: $0 stop"
        echo "  重启服务: $0 restart"
        echo ""
    else
        echo "❌ 服务启动失败"
        exit 1
    fi
}

stop_service() {
    echo "正在停止 UDPSpeeder2Raw Web 界面..."
    docker-compose down
    
    if [ $? -eq 0 ]; then
        echo "✅ 服务已停止"
    else
        echo "❌ 停止服务失败"
        exit 1
    fi
}

restart_service() {
    echo "正在重启 UDPSpeeder2Raw Web 界面..."
    docker-compose restart
    
    if [ $? -eq 0 ]; then
        echo "✅ 服务已重启"
    else
        echo "❌ 重启服务失败"
        exit 1
    fi
}

show_status() {
    echo "=== 服务状态 ==="
    docker-compose ps
    echo ""
    
    # 检查健康状态
    HEALTH=$(docker inspect --format='{{.State.Health.Status}}' udpspeeder2raw-web 2>/dev/null)
    if [ "$HEALTH" = "healthy" ]; then
        echo "✅ 服务健康状态: 正常"
        echo "🌐 Web界面: http://localhost:3000"
    elif [ "$HEALTH" = "unhealthy" ]; then
        echo "❌ 服务健康状态: 异常"
    else
        echo "ℹ️  健康状态: 未知"
    fi
}

show_logs() {
    echo "=== 服务日志 ==="
    docker-compose logs -f --tail=50
}

update_service() {
    echo "正在更新服务..."
    
    # 停止服务
    docker-compose down
    
    # 重新构建
    docker-compose build --no-cache
    
    # 启动服务
    docker-compose up -d
    
    if [ $? -eq 0 ]; then
        echo "✅ 服务更新完成"
    else
        echo "❌ 服务更新失败"
        exit 1
    fi
}

build_service() {
    echo "正在重新构建镜像..."
    docker-compose build --no-cache
    
    if [ $? -eq 0 ]; then
        echo "✅ 镜像构建完成"
        echo "运行 '$0 start' 启动服务"
    else
        echo "❌ 镜像构建失败"
        exit 1
    fi
}

# 主程序
main() {
    cd "$SCRIPT_DIR"
    
    # 检查需求
    check_requirements
    
    case "${1:-}" in
        start)
            start_service
            ;;
        stop)
            stop_service
            ;;
        restart)
            restart_service
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        update)
            update_service
            ;;
        build)
            build_service
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

# 运行主程序
main "$@"
