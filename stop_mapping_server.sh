#!/bin/sh
# Stop services defined in config.json by reading each group's ports
# and killing processes that listen on those ports using lsof+kill.

set -eu

DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
CONFIG_FILE="$DIR/config.json"

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
	echo "错误: 配置文件 $CONFIG_FILE 不存在"
	exit 1
fi

# 检查 jq 命令是否可用
if ! command -v jq >/dev/null 2>&1; then
	echo "错误: 需要安装 jq 命令来解析 JSON 配置"
	echo "请安装 jq: apt-get install jq 或 yum install jq"
	exit 1
fi

# 读取组数量
GROUP_COUNT=$(jq '.groups | length' "$CONFIG_FILE")

if [ "$GROUP_COUNT" -eq 0 ]; then
	echo "配置中未发现任何组，跳过。"
	exit 0
fi

echo "将按配置停止 $GROUP_COUNT 个组中的服务（使用 lsof+kill）。"

for i in $(seq 0 $((GROUP_COUNT - 1))); do
	group_id=$((i + 1))
	GROUP_NAME=$(jq -r ".groups[$i].name" "$CONFIG_FILE")
	SPEEDER_PORT=$(jq -r ".groups[$i].speeder_port" "$CONFIG_FILE")
	UDP2RAW_PORT=$(jq -r ".groups[$i].udp2raw_port" "$CONFIG_FILE")

	echo "停止组 $group_id: $GROUP_NAME (speeder:$SPEEDER_PORT udp2raw:$UDP2RAW_PORT)"

	for p in "$SPEEDER_PORT" "$UDP2RAW_PORT"; do
		if [ -z "$p" ] || [ "$p" = "null" ]; then
			continue
		fi
		# 使用 lsof 获取在该端口监听的 PID 列表，然后 kill -9
		PIDS=$(lsof -t -i :"$p" 2>/dev/null || true)
		if [ -n "$PIDS" ]; then
			echo "  杀死端口 $p 对应的进程: $PIDS"
			kill -9 $PIDS 2>/dev/null || true
		else
			echo "  端口 $p 没有找到进程。"
		fi
	done
done

echo "停止完成。"
