FROM ubuntu:22.04

LABEL org.opencontainers.image.source="https://github.com/srvcd/ubuntu"

# --- 修正：将多行 ENV 拆分成单行，确保正确的赋值格式 ---
ENV TZ=Asia/Shanghai
ENV SSH_USER=ubuntu
ENV SSH_PASSWORD=ubuntu!23
ENV PHP_VERSION=8.1

# 假设你的配置文件位于 Dockerfile 同目录下
COPY entrypoint.sh /entrypoint.sh
COPY reboot.sh /usr/local/sbin/reboot

RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    # 安装基础工具、openssh-server、sudo、supervisor
    apt-get install -y tzdata openssh-server sudo curl ca-certificates wget vim net-tools supervisor cron unzip iputils-ping telnet git iproute2 software-properties-common lsb-release --no-install-recommends; \
    \
    # --- 安装 Nginx 和 PHP 8.1 FPM ---
    # PHP 8.1 在 Ubuntu 22.04 默认仓库中，因此无需 PPA
    apt-get install -y nginx \
                       php${PHP_VERSION}-fpm \
                       php${PHP_VERSION}-cli \
                       php${PHP_VERSION}-mysql \
                       php${PHP_VERSION}-curl \
                       php${PHP_VERSION}-mbstring \
                       php${PHP_VERSION}-xml \
                       php${PHP_VERSION}-zip --no-install-recommends; \
    \
    # 清理
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    \
    # 常用配置和权限设置
    mkdir /var/run/sshd; \
    chmod +x /entrypoint.sh; \
    chmod +x /usr/local/sbin/reboot; \
    \
    # 启用 Nginx 配置 (将 sites-available/default 软链接到 sites-enabled/)
    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default; \
    rm -f /etc/nginx/sites-enabled/default-backup; \
    \
    # 时区设置
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime; \
    echo $TZ > /etc/timezone; \
    \
    # 确保 /run/php/ 目录存在，PHP-FPM socket 将在这里创建
    mkdir -p /run/php;
    
COPY default.conf /etc/nginx/sites-available/default
COPY supervisord.sample.conf /etc/supervisor/conf.d/supervisord.conf

# --- 端口暴露 ---
EXPOSE 22
EXPOSE 80

# --- 容器启动命令调整为 Supervisor ---
ENTRYPOINT ["/entrypoint.sh"]
# CMD 启动 Supervisor
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
