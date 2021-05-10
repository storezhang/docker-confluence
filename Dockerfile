FROM storezhang/ubuntu AS builder


# 版本
ENV VERSION 7.12.0


WORKDIR /opt/atlassian


RUN apt update && apt install -y axel curl

# 安装Bitbucket
RUN axel --num-connections 64 --insecure "https://product-downloads.atlassian.com/software/confluence/downloads/atlassian-confluence-${VERSION}.tar.gz"
RUN tar -xzf atlassian-confluence-${VERSION}.tar.gz
RUN mv atlassian-confluence-${VERSION} confluence

# 删除不需要的文件
RUN rm -rf confluence/bin/*.bat





# 打包真正的镜像
FROM storezhang/atlassian


MAINTAINER storezhang "storezhang@gmail.com"
LABEL architecture="AMD64/x86_64" version="latest" build="2021-05-10"
LABEL Description="Atlassian公司产品Confluence，一个非常好的知识管理系统。在原来的基础上增加了MySQL/MariaDB驱动以及太了解程序。"



# 开放端口
# Confluence本身的端口
EXPOSE 8090



# 复制文件
COPY --from=builder /opt/atlassian/confluence /opt/atlassian/confluence
COPY docker /



RUN set -ex \
    \
    \
    \
    # 安装cronolog，转接catalina.out日志到Confluence主目录
    && apt update -y \
    && apt upgrade -y \
    && apt install cronolog -y \
    \
    \
    \
    # 安装Confluence并增加执行权限
    && chmod +x /etc/s6/confluence/* \
    \
    \
    \
    # 安装MySQL/MariaDB驱动
    && cp -r /opt/oracle/mysql/lib/ /opt/atlassian/confluence/confluence/WEB-INF/lib \
    \
    \
    \
    # 清理镜像，减少无用包
    && rm -rf /var/lib/apt/lists/* \
    && apt autoclean



# 设置Confluence各种环境变量
ENV CONFLUENCE_HOME /config
ENV CATALINA_PID ${CONFLUENCE_HOME}/work/catalina.pid
ENV CATALINA_TMPDIR ${CONFLUENCE_HOME}/tmp
ENV CATALINA_OUT ${CONFLUENCE_HOME}/log/catalina.out
ENV CATALINA_OUT_CMD "cronolog ${CONFLUENCE_HOME}/log/catalina.%Y-%m-%d.out"
ENV CATALINA_OPTS ""
