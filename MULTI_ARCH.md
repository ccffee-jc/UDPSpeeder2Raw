# 多架构支持说明

## 概述

UDPSpeeder2Raw项目现已支持多架构Docker镜像构建，可以在不同的CPU架构上运行：

- **linux/amd64**: Intel/AMD 64位处理器
- **linux/arm64**: ARM 64位处理器 (树莓派4、Apple M系列等)
- **linux/arm**: ARM 32位处理器 (旧版树莓派等)

## 架构自动检测

Docker镜像构建时会：

1. **自动下载**: 根据目标架构自动下载对应的UDPspeeder和UDP2Raw二进制文件
2. **备用方案**: 如果下载失败，使用本地的amd64版本作为fallback
3. **文件验证**: 验证下载的二进制文件是否有效

## 使用方法

### 1. 使用预构建镜像（推荐）

```bash
# 自动拉取适合当前架构的镜像
docker pull ghcr.io/ccffee-jc/udpspeeder2raw:latest

# 使用docker-compose部署
docker-compose -f docker-compose.ghcr.yml up -d
```

### 2. 本地构建多架构镜像

```bash
# 预下载所有架构的二进制文件
./prepare-binaries.sh

# 构建多架构镜像
docker buildx build --platform linux/amd64,linux/arm64 -t udpspeeder2raw .
```

### 3. 手动管理二进制文件

```bash
# 下载特定架构的二进制文件
./download-binaries.sh arm64

# 查看已下载的文件
ls -la speederv2_* udp2raw_*

# 强制重新下载
./download-binaries.sh amd64 true
```

## 管理命令

使用增强的管理脚本：

```bash
# 预下载所有架构的二进制文件
./manage.sh prepare

# 下载特定架构的二进制文件
./manage.sh download arm64

# 构建和启动服务
./manage.sh start
```

## 架构映射

| Docker架构 | UDPspeeder | UDP2Raw | 说明 |
|-----------|------------|---------|------|
| linux/amd64 | x86_64 | x86_64 | Intel/AMD 64位 |
| linux/arm64 | aarch64 | arm | ARM 64位 |
| linux/arm | arm | arm | ARM 32位 |

## 注意事项

1. **网络要求**: 构建时需要能访问GitHub releases页面下载二进制文件
2. **备用文件**: 建议保留本地的`speederv2_amd64`和`udp2raw_amd64`作为备用
3. **验证机制**: 构建过程会验证下载的二进制文件是否为有效的ELF格式
4. **权限设置**: 所有二进制文件会自动设置执行权限

## 故障排除

### 下载失败
如果二进制文件下载失败：
1. 检查网络连接
2. 手动运行 `./download-binaries.sh [arch]`
3. 查看下载日志

### 架构不匹配
如果遇到架构不匹配的问题：
1. 确认目标架构是否支持
2. 手动指定架构构建: `docker buildx build --platform linux/arm64`
3. 检查二进制文件是否正确下载

### 文件验证失败
如果二进制文件验证失败：
1. 重新下载: `./download-binaries.sh [arch] true`
2. 检查文件完整性: `file speederv2_[arch]`
3. 使用备用文件: 确保有可用的fallback文件
