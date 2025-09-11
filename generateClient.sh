#!/bin/bash

# generateClient.sh - 根据配置生成客户端包
# 用法: ./generateClient.sh <group_name>

set -e

# 检查参数
if [ $# -ne 1 ]; then
    echo "用法: $0 <group_name>"
    echo "可用的组名:"
    jq -r '.groups[].name' config.json 2>/dev/null || echo "无法读取config.json"
    exit 1
fi

GROUP_NAME="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.json"
CLIENT_SOURCE_DIR="$SCRIPT_DIR/client"
CLIENT_OUT_DIR="$SCRIPT_DIR/client_out"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# 检查必要文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "错误: 配置文件 $CONFIG_FILE 不存在"
    exit 1
fi

if [ ! -d "$CLIENT_SOURCE_DIR" ]; then
    echo "错误: 客户端源目录 $CLIENT_SOURCE_DIR 不存在"
    exit 1
fi

if [ ! -d "$TEMPLATES_DIR" ]; then
    echo "错误: 模板目录 $TEMPLATES_DIR 不存在"
    exit 1
fi

# 检查jq是否可用
if ! command -v jq &> /dev/null; then
    echo "错误: 需要安装 jq 工具来处理JSON配置文件"
    echo "在Ubuntu/Debian上: sudo apt-get install jq"
    echo "在CentOS/RHEL上: sudo yum install jq 或 sudo dnf install jq"
    exit 1
fi

echo "正在为组 '$GROUP_NAME' 生成客户端配置..."

# 从配置文件中提取组配置
GROUP_CONFIG=$(jq --arg name "$GROUP_NAME" '.groups[] | select(.name == $name)' "$CONFIG_FILE")

if [ -z "$GROUP_CONFIG" ]; then
    echo "错误: 在配置文件中找不到组 '$GROUP_NAME'"
    echo "可用的组名:"
    jq -r '.groups[].name' "$CONFIG_FILE"
    exit 1
fi

# 提取全局配置
REMOTE_HOST=$(jq -r '.global.remote_host' "$CONFIG_FILE")
PASSWORD=$(jq -r '.global.password' "$CONFIG_FILE")

# 提取组特定配置
SPEEDER_PORT=$(echo "$GROUP_CONFIG" | jq -r '.speeder_port')
UDP2RAW_PORT=$(echo "$GROUP_CONFIG" | jq -r '.udp2raw_port')
FEC_CONFIG=$(echo "$GROUP_CONFIG" | jq -r '.fec_config')
MODE=$(echo "$GROUP_CONFIG" | jq -r '.mode')
TIMEOUT=$(echo "$GROUP_CONFIG" | jq -r '.timeout')
QUEUE=$(echo "$GROUP_CONFIG" | jq -r '.queue')
INTERVAL=$(echo "$GROUP_CONFIG" | jq -r '.interval')
UDP2RAW_EXTRA=$(echo "$GROUP_CONFIG" | jq -r '.udp2raw_extra')

echo "配置信息:"
echo "  组名: $GROUP_NAME"
echo "  远程主机: $REMOTE_HOST"
echo "  Speeder端口: $SPEEDER_PORT"
echo "  UDP2RAW端口: $UDP2RAW_PORT"
echo "  FEC配置: $FEC_CONFIG"
echo "  模式: $MODE"
echo "  超时: $TIMEOUT"
echo "  队列: $QUEUE"
echo "  间隔: $INTERVAL"
echo "  UDP2RAW额外参数: $UDP2RAW_EXTRA"

# 创建输出目录
OUTPUT_DIR="$CLIENT_OUT_DIR/$GROUP_NAME"
mkdir -p "$OUTPUT_DIR"

echo "正在创建输出目录: $OUTPUT_DIR"

# 复制客户端文件
echo "正在复制客户端文件..."
cp -r "$CLIENT_SOURCE_DIR"/* "$OUTPUT_DIR/"

# 生成配置化的批处理文件
echo "正在生成配置化的批处理文件..."

# 处理 startMapping.bat
if [ -f "$TEMPLATES_DIR/startMapping.bat.template" ]; then
    sed -e "s/{{REMOTE_HOST}}/$REMOTE_HOST/g" \
        -e "s/{{PASSWORD}}/$PASSWORD/g" \
        -e "s/{{SPEEDER_PORT}}/$SPEEDER_PORT/g" \
        -e "s/{{UDP2RAW_PORT}}/$UDP2RAW_PORT/g" \
        -e "s/{{FEC_CONFIG}}/$FEC_CONFIG/g" \
        -e "s/{{MODE}}/$MODE/g" \
        -e "s/{{TIMEOUT}}/$TIMEOUT/g" \
        -e "s/{{QUEUE}}/$QUEUE/g" \
        -e "s/{{INTERVAL}}/$INTERVAL/g" \
        -e "s/{{UDP2RAW_EXTRA}}/$UDP2RAW_EXTRA/g" \
        "$TEMPLATES_DIR/startMapping.bat.template" > "$OUTPUT_DIR/startMapping.bat"
    echo "  ✓ 生成 startMapping.bat"
else
    echo "  ⚠ 警告: 模板文件 startMapping.bat.template 不存在"
fi

# 处理 startMappingWithoutU2R.bat
if [ -f "$TEMPLATES_DIR/startMappingWithoutU2R.bat.template" ]; then
    sed -e "s/{{REMOTE_HOST}}/$REMOTE_HOST/g" \
        -e "s/{{PASSWORD}}/$PASSWORD/g" \
        -e "s/{{SPEEDER_PORT}}/$SPEEDER_PORT/g" \
        -e "s/{{UDP2RAW_PORT}}/$UDP2RAW_PORT/g" \
        -e "s/{{FEC_CONFIG}}/$FEC_CONFIG/g" \
        -e "s/{{MODE}}/$MODE/g" \
        -e "s/{{TIMEOUT}}/$TIMEOUT/g" \
        -e "s/{{QUEUE}}/$QUEUE/g" \
        -e "s/{{INTERVAL}}/$INTERVAL/g" \
        -e "s/{{UDP2RAW_EXTRA}}/$UDP2RAW_EXTRA/g" \
        "$TEMPLATES_DIR/startMappingWithoutU2R.bat.template" > "$OUTPUT_DIR/startMappingWithoutU2R.bat"
    echo "  ✓ 生成 startMappingWithoutU2R.bat"
else
    echo "  ⚠ 警告: 模板文件 startMappingWithoutU2R.bat.template 不存在"
fi

# 创建配置信息文件
echo "正在创建配置信息文件..."
cat > "$OUTPUT_DIR/config_info.txt" << EOF
配置信息 - $GROUP_NAME
=======================

生成时间: $(date)
组名: $GROUP_NAME
远程主机: $REMOTE_HOST
密码: $PASSWORD

Speeder配置:
- 监听端口: $SPEEDER_PORT
- FEC配置: $FEC_CONFIG
- 模式: $MODE
- 超时: ${TIMEOUT}秒
- 队列大小: $QUEUE
- 间隔: ${INTERVAL}毫秒

UDP2RAW配置:
- 端口: $UDP2RAW_PORT
- 额外参数: $UDP2RAW_EXTRA

使用说明:
1. 运行 startMapping.bat 启动带UDP2RAW的连接
2. 运行 startMappingWithoutU2R.bat 启动直连模式
3. WireShark工具用于网络分析调试
EOF

echo "  ✓ 生成配置信息文件"

# 创建ZIP包
echo "正在创建ZIP包..."
cd "$CLIENT_OUT_DIR"

# 检查zip命令是否可用
if command -v zip &> /dev/null; then
    zip -r "${GROUP_NAME}.zip" "$GROUP_NAME"
    echo "  ✓ 创建ZIP包: $CLIENT_OUT_DIR/${GROUP_NAME}.zip"
elif command -v 7z &> /dev/null; then
    7z a "${GROUP_NAME}.zip" "$GROUP_NAME"
    echo "  ✓ 创建ZIP包: $CLIENT_OUT_DIR/${GROUP_NAME}.zip"
else
    echo "  ⚠ 警告: 未找到zip或7z命令，跳过ZIP包创建"
    echo "  你可以手动压缩目录: $OUTPUT_DIR"
fi

cd "$SCRIPT_DIR"

echo ""
echo "✅ 客户端生成完成!"
echo "输出目录: $OUTPUT_DIR"
if [ -f "$CLIENT_OUT_DIR/${GROUP_NAME}.zip" ]; then
    echo "ZIP包: $CLIENT_OUT_DIR/${GROUP_NAME}.zip"
fi
echo ""
echo "文件列表:"
ls -la "$OUTPUT_DIR"
