# 多架构支持的Dockerfile
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETARCH
ARG TARGETOS

FROM --platform=$BUILDPLATFORM node:18-alpine AS builder

# 安装构建依赖
RUN apk add --no-cache \
    bash \
    jq \
    curl \
    wget \
    ca-certificates

WORKDIR /app

# 复制并安装Node.js依赖
COPY src/package.json ./
RUN npm ci --only=production && npm cache clean --force

# 下载对应架构的二进制文件
FROM --platform=$BUILDPLATFORM alpine:latest AS downloader

ARG TARGETARCH
ARG TARGETOS

# 安装下载工具
RUN apk add --no-cache curl wget ca-certificates

WORKDIR /downloads

# 定义版本和下载链接
ENV SPEEDERV2_VERSION=20230206.0
ENV UDP2RAW_VERSION=20200818.0

# 根据架构映射下载链接
RUN set -ex; \
    case "${TARGETARCH}" in \
        amd64) \
            SPEEDERV2_ARCH="x86_64"; \
            UDP2RAW_ARCH="x86_64"; \
            ;; \
        arm64) \
            SPEEDERV2_ARCH="aarch64"; \
            UDP2RAW_ARCH="arm"; \
            ;; \
        arm) \
            SPEEDERV2_ARCH="arm"; \
            UDP2RAW_ARCH="arm"; \
            ;; \
        *) \
            echo "Unsupported architecture: ${TARGETARCH}"; \
            exit 1; \
            ;; \
    esac; \
    \
    echo "Downloading binaries for ${TARGETARCH} (speeder: ${SPEEDERV2_ARCH}, udp2raw: ${UDP2RAW_ARCH})"; \
    \
    # 下载 UDPspeeder
    wget -O speederv2 "https://github.com/wangyu-/UDPspeeder/releases/download/${SPEEDERV2_VERSION}/speederv2_binaries.tar.gz" || \
    curl -L -o speederv2.tar.gz "https://github.com/wangyu-/UDPspeeder/releases/download/${SPEEDERV2_VERSION}/speederv2_binaries.tar.gz" && \
    tar -xzf speederv2.tar.gz && \
    find . -name "*${SPEEDERV2_ARCH}*" -type f -executable | head -1 | xargs -I {} cp {} speederv2 || \
    cp speederv2_amd64 speederv2; \
    \
    # 下载 UDP2Raw
    wget -O udp2raw "https://github.com/wangyu-/udp2raw/releases/download/${UDP2RAW_VERSION}/udp2raw_binaries.tar.gz" || \
    curl -L -o udp2raw.tar.gz "https://github.com/wangyu-/udp2raw/releases/download/${UDP2RAW_VERSION}/udp2raw_binaries.tar.gz" && \
    tar -xzf udp2raw.tar.gz && \
    find . -name "*${UDP2RAW_ARCH}*" -type f -executable | head -1 | xargs -I {} cp {} udp2raw || \
    cp udp2raw_amd64 udp2raw; \
    \
    # 确保文件存在且可执行
    chmod +x speederv2 udp2raw; \
    ls -la speederv2 udp2raw

# 运行时镜像
FROM node:18-alpine

# 安装系统依赖
RUN apk add --no-cache \
    bash \
    jq \
    zip \
    p7zip \
    curl \
    wget \
    lsof \
    procps \
    iproute2 \
    iptables \
    ca-certificates \
    tzdata

# 设置时区
ENV TZ=Asia/Shanghai

# 创建应用目录
WORKDIR /app

# 从构建阶段复制node_modules
COPY --from=builder /app/node_modules ./node_modules

# 复制应用源码
COPY src/ ./

# 复制UDPSpeeder2Raw相关文件
COPY config.json ./
COPY *.sh ./
COPY client/ ./client/
COPY templates/ ./templates/

# 从下载阶段复制对应架构的二进制文件
COPY --from=downloader /downloads/speederv2 ./speederv2
COPY --from=downloader /downloads/udp2raw ./udp2raw

# 备用：如果下载失败，使用本地文件
COPY speederv2_amd64 ./speederv2_fallback
COPY udp2raw_amd64 ./udp2raw_fallback

# 设置文件权限并处理备用文件
RUN set -ex; \
    chmod +x *.sh; \
    if [ ! -f speederv2 ] || [ ! -s speederv2 ]; then \
        echo "Using fallback speederv2"; \
        cp speederv2_fallback speederv2; \
    fi; \
    if [ ! -f udp2raw ] || [ ! -s udp2raw ]; then \
        echo "Using fallback udp2raw"; \
        cp udp2raw_fallback udp2raw; \
    fi; \
    chmod +x speederv2 udp2raw; \
    rm -f speederv2_fallback udp2raw_fallback; \
    find client/ -name "*.exe" -exec chmod +x {} \; 2>/dev/null || true

# 创建必要的目录
RUN mkdir -p logs client_out

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1

# 启动应用
CMD ["node", "server.js"]
