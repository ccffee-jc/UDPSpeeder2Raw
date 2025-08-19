# UDPSpeeder2Raw Web Interface

基于Docker的UDPSpeeder2Raw Web管理界面，参考wg-easy项目架构设计。

## 功能特性

- 🌐 **Web界面管理** - 简洁直观的Web管理界面
- ⚙️ **全局配置管理** - 统一管理远程主机和密码配置
- 📋 **节点列表管理** - 显示所有配置的节点及其详细信息
- ➕ **节点增删改** - 支持新增、修改、删除节点配置
- 🔄 **自动端口分配** - 智能分配端口，支持端口空位补齐
- 📦 **客户端配置导出** - 一键生成并下载客户端配置包
- 🐳 **Docker容器化** - 完全容器化部署，开箱即用
- 🔄 **自动服务管理** - 配置变更后自动重启服务

## 快速开始

### 前置要求

- Docker
- Docker Compose

### 部署步骤

#### 方式一：使用预构建的Docker镜像（推荐）

1. **下载配置文件模板**
   ```bash
   # 下载docker-compose配置
   wget https://raw.githubusercontent.com/ccffee-jc/UDPSpeeder2Raw/master/docker-compose.ghcr.yml
   
   # 下载示例配置文件
   wget https://raw.githubusercontent.com/ccffee-jc/UDPSpeeder2Raw/master/config.json
   ```

2. **创建必要目录**
   ```bash
   mkdir -p logs client_out
   ```

3. **启动服务**
   ```bash
   docker-compose -f docker-compose.ghcr.yml up -d
   ```

#### 方式二：从源码构建

1. **克隆或下载项目文件**

2. **确保所有必要文件存在**
   ```
   UDPSpeeder2Raw/
   ├── config.json              # 配置文件
   ├── speederv2_amd64          # UDPSpeeder二进制文件
   ├── udp2raw_amd64            # UDP2Raw二进制文件
   ├── *.sh                     # 各种脚本文件
   ├── client/                  # 客户端文件目录
   ├── templates/               # 模板文件目录
   ├── src/                     # Web界面源码
   ├── Dockerfile               # Docker构建文件
   ├── docker-compose.yml       # Docker Compose配置
   └── start-web.sh             # 启动脚本
   ```

3. **启动服务**
   ```bash
   # 方式1: 使用启动脚本
   ./start-web.sh
   
   # 方式2: 使用管理脚本
   ./manage.sh start
   
   # 方式3: 直接使用docker-compose
   sudo docker-compose up -d --build
   ```

4. **访问Web界面**
   
   打开浏览器访问: `http://localhost:3000`

### 管理命令

项目提供了一个便捷的管理脚本 `manage.sh`：

```bash
# 启动服务
./manage.sh start

# 停止服务  
./manage.sh stop

# 重启服务
./manage.sh restart

# 查看服务状态
./manage.sh status

# 查看实时日志
./manage.sh logs

# 更新服务（重新构建并重启）
./manage.sh update

# 仅重新构建镜像
./manage.sh build
```

## 使用说明

### 全局配置

- 点击"修改配置"按钮可以修改远程主机地址和密码
- 这些配置会应用到所有节点

### 节点管理

#### 新增节点
1. 点击"新增节点"按钮
2. 填写节点名称和相关配置参数
3. 端口会自动分配（Speeder端口从10001开始，UDP2Raw端口从10002开始，每个节点间隔10）
4. 点击"创建"完成添加

#### 修改节点
1. 点击节点对应的"修改"按钮
2. 在弹出的窗口中修改配置（端口不可修改）
3. 点击"保存"完成修改

#### 删除节点
1. 点击节点对应的"删除"按钮
2. 在确认对话框中确认删除操作

#### 导出客户端配置
1. 点击节点对应的"导出"按钮
2. 系统会自动调用`generateClient.sh`生成客户端配置
3. 配置文件会以ZIP格式自动下载

### 端口分配规则

- Speeder端口：10001, 10011, 10021, 10031...（步长10）
- UDP2Raw端口：10002, 10012, 10022, 10032...（步长10）
- 如果中间有节点被删除，新增节点时会优先填补空缺的端口位

### 自动服务管理

- 容器启动时会自动调用`start_mapping_server.sh`启动映射服务
- 每次节点配置发生变更（增删改）后，系统会自动调用`restart.sh`重启服务
- 容器关闭时会自动调用`stop_mapping_server.sh`停止映射服务

## Docker命令

### 查看日志
```bash
docker-compose logs -f
```

### 停止服务
```bash
docker-compose down
```

### 重启服务
```bash
docker-compose restart
```

### 重新构建
```bash
docker-compose up -d --build
```

## 端口配置

网络配置：
- **网络模式**：host（主机网络模式）
- **Web界面**：3000端口
- **UDP端口**：根据配置动态分配（通常从10001开始）

使用host网络模式的优势：
- 无需端口映射配置
- 性能更好，延迟更低
- 自动支持所有端口范围
- 简化网络配置

**注意**：host网络模式下，容器直接使用宿主机网络栈，确保所需端口未被其他服务占用。

## 数据持久化

以下数据会自动持久化到宿主机：
- `config.json` - 配置文件
- `logs/` - 日志文件
- `client_out/` - 生成的客户端配置文件

## 故障排除

### 常见问题

1. **端口被占用**
   - 检查3000端口是否被其他服务占用
   - 或修改docker-compose.yml中的端口映射

2. **权限问题**
   - 确保脚本文件有执行权限：`chmod +x *.sh`
   - 确保二进制文件有执行权限

3. **Docker权限问题**
   - 确保当前用户有Docker执行权限
   - 或使用sudo运行

4. **配置文件格式错误**
   - 检查config.json文件格式是否正确
   - 使用JSON验证器验证语法

### 查看详细日志

```bash
# 查看容器日志
docker-compose logs udpspeeder2raw-web

# 查看映射服务日志
docker-compose exec udpspeeder2raw-web cat /app/logs/mapping_server.log

# 进入容器调试
docker-compose exec udpspeeder2raw-web sh
```

## Docker镜像

### 官方镜像仓库

项目提供了预构建的Docker镜像，托管在GitHub Container Registry：

- **镜像地址**: `ghcr.io/ccffee-jc/udpspeeder2raw`
- **支持架构**: linux/amd64, linux/arm64
- **标签**:
  - `latest`: 最新稳定版本
  - `v1.0.0`: 特定版本标签

### 使用预构建镜像

```bash
# 拉取最新镜像
docker pull ghcr.io/ccffee-jc/udpspeeder2raw:latest

# 使用预构建镜像部署
docker-compose -f docker-compose.ghcr.yml up -d
```

### 手动构建镜像

```bash
# 构建本地镜像
docker build -t udpspeeder2raw .

# 构建多架构镜像
docker buildx build --platform linux/amd64,linux/arm64 -t udpspeeder2raw .

# 预下载所有架构的二进制文件
./prepare-binaries.sh

# 下载特定架构的二进制文件
./download-binaries.sh arm64
```

### 多架构支持

本项目支持以下架构：

- **linux/amd64**: Intel/AMD 64位处理器
- **linux/arm64**: ARM 64位处理器 (如树莓派4、Apple M系列)
- **linux/arm**: ARM 32位处理器 (如老版本树莓派)

Docker镜像构建时会自动下载对应架构的UDPspeeder和UDP2Raw二进制文件。如果下载失败，会使用本地的fallback文件。

### 二进制文件管理

```bash
# 预下载所有架构的二进制文件
./manage.sh prepare

# 下载特定架构的二进制文件
./manage.sh download arm64

# 手动下载并管理二进制文件
./download-binaries.sh amd64    # 下载AMD64架构
./download-binaries.sh arm64    # 下载ARM64架构
./download-binaries.sh arm      # 下载ARM架构
```

### 发布镜像到GHCR

如果您想发布自己的镜像版本：

1. **生成GitHub Token**
   - 访问 GitHub Settings > Developer settings > Personal access tokens
   - 创建token，勾选 `write:packages` 权限

2. **登录到GHCR**
   ```bash
   echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin
   ```

3. **构建并推送**
   ```bash
   # 使用发布脚本
   ./publish-docker.sh v1.0.0
   
   # 或者手动构建推送
   docker buildx build --platform linux/amd64,linux/arm64 \
     --tag ghcr.io/YOUR_USERNAME/udpspeeder2raw:latest \
     --push .
   ```

## 技术架构

- **前端**: Vue.js + Tailwind CSS
- **后端**: Node.js + Express
- **容器**: Docker + Docker Compose
- **配置管理**: JSON配置文件
- **文件生成**: 调用原有Shell脚本

## 安全说明

- 本界面设计为内网使用，不建议直接暴露到公网
- 如需公网访问，请配置反向代理并启用HTTPS
- 建议定期备份配置文件

## 许可证

MIT License
