# Docker镜像发布指南

## 准备工作

### 1. 生成GitHub Personal Access Token

1. 访问 GitHub Settings: https://github.com/settings/tokens
2. 点击 "Generate new token" → "Generate new token (classic)"
3. 设置权限：
   - 勾选 `write:packages` (写入包权限)
   - 勾选 `read:packages` (读取包权限)
   - 可选择设置过期时间
4. 复制生成的token

### 2. 设置环境变量

```bash
# 设置GitHub Token (替换为您的真实token)
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# 验证token设置
echo $GITHUB_TOKEN
```

### 3. 登录到GitHub Container Registry

```bash
# 登录到GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u ccffee-jc --password-stdin
```

## 发布方式

### 方式一：使用发布脚本（推荐）

```bash
# 发布latest版本
./publish-docker.sh

# 发布特定版本
./publish-docker.sh v1.0.0

# 发布测试版本
./publish-docker.sh beta
```

### 方式二：手动构建和推送

```bash
# 创建multi-arch构建器
docker buildx create --name multiarch --use

# 构建并推送多架构镜像
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --tag ghcr.io/ccffee-jc/udpspeeder2raw:latest \
    --tag ghcr.io/ccffee-jc/udpspeeder2raw:v1.0.0 \
    --push \
    .
```

### 方式三：使用GitHub Actions（自动化）

项目已配置GitHub Actions，会在以下情况自动构建和发布：

- 推送到 `master` 分支
- 创建版本标签 (如 `v1.0.0`)
- 提交Pull Request时构建测试

```bash
# 推送代码触发自动构建
git add .
git commit -m "Update Docker configuration"
git push origin master

# 创建版本标签触发发布
git tag v1.0.0
git push origin v1.0.0
```

## 验证发布

### 1. 检查镜像是否成功发布

访问: https://github.com/ccffee-jc/UDPSpeeder2Raw/pkgs/container/udpspeeder2raw

### 2. 测试拉取镜像

```bash
# 拉取最新镜像
docker pull ghcr.io/ccffee-jc/udpspeeder2raw:latest

# 拉取特定版本
docker pull ghcr.io/ccffee-jc/udpspeeder2raw:v1.0.0

# 查看镜像信息
docker images | grep udpspeeder2raw
```

### 3. 测试多架构支持

```bash
# 查看镜像支持的架构
docker buildx imagetools inspect ghcr.io/ccffee-jc/udpspeeder2raw:latest
```

## 使用发布的镜像

### 用户使用方式

```bash
# 下载并使用预构建镜像
wget https://raw.githubusercontent.com/ccffee-jc/UDPSpeeder2Raw/master/docker-compose.ghcr.yml
docker-compose -f docker-compose.ghcr.yml up -d
```

## 常见问题

### 1. 登录失败
```
Error: unauthorized: unauthenticated: User cannot be authenticated with the token provided.
```
**解决**: 检查token权限，确保包含 `write:packages`

### 2. 构建失败
```
Error: failed to solve: process "/bin/sh -c ..." returned non-zero code: 1
```
**解决**: 检查Dockerfile语法，运行本地测试

### 3. 推送权限被拒绝
```
Error: denied: permission_denied
```
**解决**: 确保repository名称正确，token权限足够

## 版本管理建议

- `latest`: 最新稳定版本
- `v1.0.0`: 具体版本号
- `beta`: 测试版本
- `dev`: 开发版本

```bash
# 示例：发布不同版本
./publish-docker.sh latest
./publish-docker.sh v1.0.0
./publish-docker.sh beta
```
