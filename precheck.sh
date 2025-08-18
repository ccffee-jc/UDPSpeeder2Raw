#!/bin/bash

# precheck.sh - 检测并安装项目依赖
# 检测项目所需的命令是否存在，如果不存在则询问是否安装

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 依赖列表 - 命令名和包名的映射
declare -A DEPENDENCIES=(
    ["jq"]="jq"
    ["zip"]="zip"
    ["7z"]="p7zip-full"
)

# 可选依赖（不是必须的）
declare -A OPTIONAL_DEPENDENCIES=(
    ["curl"]="curl"
    ["wget"]="wget"
)

echo -e "${BLUE}=== 项目依赖检测工具 ===${NC}"
echo "正在检测项目所需的依赖..."
echo ""

# 检测系统包管理器
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt-get"
    elif command -v apt &> /dev/null; then
        echo "apt"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

PACKAGE_MANAGER=$(detect_package_manager)

if [ "$PACKAGE_MANAGER" = "unknown" ]; then
    echo -e "${RED}错误: 未能检测到支持的包管理器${NC}"
    echo "支持的包管理器: apt, apt-get, yum, dnf, pacman"
    exit 1
fi

echo -e "${GREEN}检测到包管理器: $PACKAGE_MANAGER${NC}"
echo ""

# 检测是否有sudo权限
check_sudo() {
    if sudo -n true 2>/dev/null; then
        return 0
    else
        echo -e "${YELLOW}注意: 安装软件包需要sudo权限${NC}"
        return 1
    fi
}

# 安装包的函数
install_package() {
    local package_name="$1"
    local cmd_name="$2"
    
    echo -e "${YELLOW}正在安装 $package_name...${NC}"
    
    case "$PACKAGE_MANAGER" in
        "apt"|"apt-get")
            if sudo apt-get update && sudo apt-get install -y "$package_name"; then
                echo -e "${GREEN}✓ $package_name 安装成功${NC}"
                return 0
            else
                echo -e "${RED}✗ $package_name 安装失败${NC}"
                return 1
            fi
            ;;
        "yum")
            if sudo yum install -y "$package_name"; then
                echo -e "${GREEN}✓ $package_name 安装成功${NC}"
                return 0
            else
                echo -e "${RED}✗ $package_name 安装失败${NC}"
                return 1
            fi
            ;;
        "dnf")
            if sudo dnf install -y "$package_name"; then
                echo -e "${GREEN}✓ $package_name 安装成功${NC}"
                return 0
            else
                echo -e "${RED}✗ $package_name 安装失败${NC}"
                return 1
            fi
            ;;
        "pacman")
            if sudo pacman -S --noconfirm "$package_name"; then
                echo -e "${GREEN}✓ $package_name 安装成功${NC}"
                return 0
            else
                echo -e "${RED}✗ $package_name 安装失败${NC}"
                return 1
            fi
            ;;
        *)
            echo -e "${RED}✗ 不支持的包管理器: $PACKAGE_MANAGER${NC}"
            return 1
            ;;
    esac
}

# 询问用户是否安装
ask_install() {
    local cmd_name="$1"
    local package_name="$2"
    
    echo -e "${YELLOW}命令 '$cmd_name' 未找到${NC}"
    echo -e "需要安装软件包: ${BLUE}$package_name${NC}"
    read -p "是否现在安装? (y/n/s=跳过): " choice
    
    case "$choice" in
        [Yy]|[Yy][Ee][Ss])
            return 0
            ;;
        [Ss]|[Ss][Kk][Ii][Pp])
            echo -e "${YELLOW}跳过安装 $package_name${NC}"
            return 2
            ;;
        *)
            echo -e "${YELLOW}跳过安装 $package_name${NC}"
            return 1
            ;;
    esac
}

# 检测单个命令
check_command() {
    local cmd_name="$1"
    local package_name="$2"
    local is_optional="$3"
    
    if command -v "$cmd_name" &> /dev/null; then
        local version=""
        case "$cmd_name" in
            "jq")
                version=$(jq --version 2>/dev/null || echo "unknown")
                ;;
            "zip")
                version=$(zip -v 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
                ;;
            "7z")
                version=$(7z 2>/dev/null | head -1 | awk '{print $3}' || echo "unknown")
                ;;
            *)
                version=$($cmd_name --version 2>/dev/null | head -1 || echo "unknown")
                ;;
        esac
        echo -e "${GREEN}✓ $cmd_name${NC} - 已安装 ($version)"
        return 0
    else
        if [ "$is_optional" = "true" ]; then
            echo -e "${YELLOW}○ $cmd_name${NC} - 可选依赖，未安装"
            return 0
        else
            echo -e "${RED}✗ $cmd_name${NC} - 未安装"
            
            if ask_install "$cmd_name" "$package_name"; then
                if install_package "$package_name" "$cmd_name"; then
                    return 0
                else
                    return 1
                fi
            else
                return 1
            fi
        fi
    fi
}

# 主检测流程
missing_required=()
failed_installs=()

echo "=== 检测必需依赖 ==="
for cmd in "${!DEPENDENCIES[@]}"; do
    package="${DEPENDENCIES[$cmd]}"
    if ! check_command "$cmd" "$package" "false"; then
        if command -v "$cmd" &> /dev/null; then
            # 安装成功了
            continue
        else
            missing_required+=("$cmd")
        fi
    fi
done

echo ""
echo "=== 检测可选依赖 ==="
for cmd in "${!OPTIONAL_DEPENDENCIES[@]}"; do
    package="${OPTIONAL_DEPENDENCIES[$cmd]}"
    check_command "$cmd" "$package" "true"
done

echo ""
echo "=== 检测结果 ==="

if [ ${#missing_required[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ 所有必需依赖都已安装！${NC}"
    echo ""
    echo "项目依赖状态良好，可以正常使用 generateClient.sh 脚本。"
else
    echo -e "${RED}❌ 缺少以下必需依赖:${NC}"
    for cmd in "${missing_required[@]}"; do
        echo -e "  - ${RED}$cmd${NC}"
    done
    echo ""
    echo -e "${YELLOW}请手动安装缺失的依赖或重新运行此脚本。${NC}"
    echo ""
    echo "手动安装命令示例："
    case "$PACKAGE_MANAGER" in
        "apt"|"apt-get")
            echo "sudo apt-get update && sudo apt-get install -y jq zip"
            ;;
        "yum")
            echo "sudo yum install -y jq zip"
            ;;
        "dnf")
            echo "sudo dnf install -y jq zip"
            ;;
        "pacman")
            echo "sudo pacman -S jq zip"
            ;;
    esac
fi

# 检测脚本文件权限
echo ""
echo "=== 检测脚本文件权限 ==="

# 需要检测的脚本文件列表
SCRIPT_FILES=("generateClient.sh" "start_mapping_server.sh" "stop_mapping_server.sh" "restart.sh")

script_issues=()

for script in "${SCRIPT_FILES[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo -e "${GREEN}✓ $script 已存在且可执行${NC}"
        else
            echo -e "${YELLOW}○ $script 存在但不可执行，正在添加执行权限...${NC}"
            chmod +x "$script"
            if [ -x "$script" ]; then
                echo -e "${GREEN}✓ 已为 $script 添加执行权限${NC}"
            else
                echo -e "${RED}✗ 无法为 $script 添加执行权限${NC}"
                script_issues+=("$script")
            fi
        fi
    else
        echo -e "${RED}✗ $script 不存在${NC}"
        script_issues+=("$script")
    fi
done

# 检测二进制文件权限
echo ""
echo "=== 检测二进制文件权限 ==="

# 需要检测的二进制文件列表
BINARY_FILES=("speederv2_amd64" "udp2raw_amd64")

binary_issues=()

for binary in "${BINARY_FILES[@]}"; do
    if [ -f "$binary" ]; then
        if [ -x "$binary" ]; then
            echo -e "${GREEN}✓ $binary 已存在且可执行${NC}"
        else
            echo -e "${YELLOW}○ $binary 存在但不可执行，正在添加执行权限...${NC}"
            chmod +x "$binary"
            if [ -x "$binary" ]; then
                echo -e "${GREEN}✓ 已为 $binary 添加执行权限${NC}"
            else
                echo -e "${RED}✗ 无法为 $binary 添加执行权限${NC}"
                binary_issues+=("$binary")
            fi
        fi
    else
        echo -e "${RED}✗ $binary 不存在${NC}"
        binary_issues+=("$binary")
    fi
done

# 额外检查：UDP2Raw权限提醒
if [ -f "udp2raw_amd64" ] && [ -x "udp2raw_amd64" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  重要提醒: udp2raw_amd64 需要 root 权限运行${NC}"
    echo -e "   使用服务器启动/停止脚本时，请使用 sudo 权限："
    echo -e "   ${BLUE}sudo ./start_mapping_server.sh${NC}"
    echo -e "   ${BLUE}sudo ./stop_mapping_server.sh${NC}"
    echo -e "   ${BLUE}sudo ./restart.sh${NC}"
fi

# 最终总结
echo ""
echo "=== 最终检测总结 ==="

total_issues=$((${#missing_required[@]} + ${#script_issues[@]} + ${#binary_issues[@]}))

if [ $total_issues -eq 0 ]; then
    echo -e "${GREEN}🎉 所有检查都通过了！项目可以正常使用。${NC}"
else
    echo -e "${RED}❌ 发现 $total_issues 个问题需要解决：${NC}"
    
    if [ ${#missing_required[@]} -gt 0 ]; then
        echo -e "${RED}  缺少必需依赖: ${missing_required[*]}${NC}"
    fi
    
    if [ ${#script_issues[@]} -gt 0 ]; then
        echo -e "${RED}  脚本文件问题: ${script_issues[*]}${NC}"
    fi
    
    if [ ${#binary_issues[@]} -gt 0 ]; then
        echo -e "${RED}  二进制文件问题: ${binary_issues[*]}${NC}"
    fi
fi

exit $total_issues
