#!/bin/bash

# UDPSpeeder2Raw 配置备份脚本
# 用法: ./backup.sh [backup_name]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.json"
BACKUP_DIR="$SCRIPT_DIR/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 确定备份文件名
if [ $# -eq 1 ]; then
    BACKUP_NAME="$1"
    BACKUP_FILE="$BACKUP_DIR/config_${BACKUP_NAME}_${TIMESTAMP}.json"
else
    BACKUP_FILE="$BACKUP_DIR/config_${TIMESTAMP}.json"
fi

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "错误: 配置文件 $CONFIG_FILE 不存在"
    exit 1
fi

# 创建备份
cp "$CONFIG_FILE" "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ 配置备份成功"
    echo "备份文件: $BACKUP_FILE"
    
    # 显示备份文件大小
    SIZE=$(stat -c%s "$BACKUP_FILE" 2>/dev/null || stat -f%z "$BACKUP_FILE" 2>/dev/null)
    echo "文件大小: ${SIZE} 字节"
    
    # 列出最近的5个备份
    echo ""
    echo "最近的备份文件:"
    ls -lt "$BACKUP_DIR"/config_*.json | head -5
else
    echo "❌ 备份失败"
    exit 1
fi
