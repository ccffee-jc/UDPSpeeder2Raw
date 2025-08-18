#!/bin/sh
set -eu

# Start groups of UDPSpeeder + UDP2Raw server on Linux with JSON config.
# Logs are written to ./logs/ under this script directory.
# Configuration is read from config.json in the same directory.

DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
LOG_DIR="$DIR/logs"
CONFIG_FILE="$DIR/config.json"

mkdir -p "$LOG_DIR"

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "错误: 配置文件 $CONFIG_FILE 不存在"
    echo "请创建配置文件，参考格式:"
    cat << 'EOF'
{
  "global": {
    "remote_host": "47.122.153.182:51820",
    "password": "password123"
  },
  "groups": [
    {
      "name": "台式电脑",
      "speeder_port": 10001,
      "udp2raw_port": 10002,
      "fec_config": "1:1,2:1,10:3,20:5",
      "timeout": 4,
      "queue": 20,
      "interval": 5,
      "udp2raw_extra": ""
    }
  ]
}
EOF
    exit 1
fi

# 检查 jq 命令是否可用
if ! command -v jq >/dev/null 2>&1; then
    echo "错误: 需要安装 jq 命令来解析 JSON 配置"
    echo "请安装 jq: apt-get install jq 或 yum install jq"
    exit 1
fi

# 读取全局配置
REMOTE_HOST=$(jq -r '.global.remote_host' "$CONFIG_FILE")
PASSWORD=$(jq -r '.global.password' "$CONFIG_FILE")

# 服务器端 speeder 应该连接到本地 WireGuard
WIREGUARD_HOST="127.0.0.1:51820"

# 启动单个组的函数
start_group() {
    local group_name="$1"
    local speeder_port="$2"
    local udp2raw_port="$3"
    local fec_config="$4"
    local mode="$5"
    local timeout="$6"
    local queue="$7"
    local interval="$8"
    local udp2raw_extra="$9"
    local group_id="${10}"
    
    echo "启动组 $group_id: $group_name"
    
    # 启动 speederv2
    nohup "$DIR/speederv2_amd64" \
        -s -l "0.0.0.0:$speeder_port" -r "$WIREGUARD_HOST" \
        -k "$PASSWORD" \
        -f"$fec_config" \
        --mode $mode --timeout $timeout -q $queue -i $interval \
        >>"$LOG_DIR/speeder_g$group_id.log" 2>&1 &
    
    sleep 2
    
    # 启动 udp2raw
    local udp2raw_cmd="nohup \"$DIR/udp2raw_amd64\" --raw-mode faketcp -s -l \"0.0.0.0:$udp2raw_port\" -r \"127.0.0.1:$speeder_port\" -a -k \"$PASSWORD\""
    
    if [ -n "$udp2raw_extra" ] && [ "$udp2raw_extra" != "null" ]; then
        udp2raw_cmd="$udp2raw_cmd $udp2raw_extra"
    fi
    
    udp2raw_cmd="$udp2raw_cmd >>\"$LOG_DIR/udp2raw_g$group_id.log\" 2>&1 &"
    
    eval "$udp2raw_cmd"
}

# 获取组的数量
GROUP_COUNT=$(jq '.groups | length' "$CONFIG_FILE")

# 遍历所有组进行启动
for i in $(seq 0 $((GROUP_COUNT - 1))); do
    group_id=$((i + 1))
    
    # 从 JSON 中读取每个组的配置
    GROUP_NAME=$(jq -r ".groups[$i].name" "$CONFIG_FILE")
    SPEEDER_PORT=$(jq -r ".groups[$i].speeder_port" "$CONFIG_FILE")
    UDP2RAW_PORT=$(jq -r ".groups[$i].udp2raw_port" "$CONFIG_FILE")
    FEC_CONFIG=$(jq -r ".groups[$i].fec_config" "$CONFIG_FILE")
    MODE=$(jq -r ".groups[$i].mode" "$CONFIG_FILE")
    TIMEOUT=$(jq -r ".groups[$i].timeout" "$CONFIG_FILE")
    QUEUE=$(jq -r ".groups[$i].queue" "$CONFIG_FILE")
    INTERVAL=$(jq -r ".groups[$i].interval" "$CONFIG_FILE")
    UDP2RAW_EXTRA=$(jq -r ".groups[$i].udp2raw_extra" "$CONFIG_FILE")
    
    start_group "$GROUP_NAME" "$SPEEDER_PORT" "$UDP2RAW_PORT" "$FEC_CONFIG" "$MODE" "$TIMEOUT" "$QUEUE" "$INTERVAL" "$UDP2RAW_EXTRA" "$group_id"
done

echo "所有服务已启动完成。日志目录: $LOG_DIR"
echo "配置文件: $CONFIG_FILE"