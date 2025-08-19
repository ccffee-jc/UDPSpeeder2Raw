FROM node:16-alpine

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
    iptables

# 创建应用目录
WORKDIR /app

# 复制package.json并安装Node.js依赖
COPY src/package.json ./
RUN npm install --production

# 复制应用源码
COPY src/ ./

# 复制UDPSpeeder2Raw相关文件
COPY config.json ./
COPY *.sh ./
COPY speederv2_amd64 ./
COPY udp2raw_amd64 ./
COPY client/ ./client/
COPY templates/ ./templates/

# 设置文件权限
RUN chmod +x *.sh speederv2_amd64 udp2raw_amd64 client/*.exe

# 创建必要的目录
RUN mkdir -p logs client_out

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1

# 启动应用
CMD ["node", "server.js"]
