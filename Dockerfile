ARG DOCKER_REGISTRY=docker.io
ARG UBUNTU_IMAGE_NAME=library/ubuntu
ARG UBUNTU_IMAGE_TAG=jammy-20240627.1

ARG CURL_HTTP_PROXY
ARG CPYTHON_VERSION=3.8.19
ARG GDB_VERSION=15.1

################################################################################

FROM $DOCKER_REGISTRY/$UBUNTU_IMAGE_NAME:$UBUNTU_IMAGE_TAG AS ca-certificates-debs

WORKDIR /var/cache/apt/archives/

RUN --mount=type=bind,target=/etc/apt/sources.list,source=sources.list \
    --mount=type=bind,target=/etc/ssl/certs/ca-certificates.crt,source=ca-certificates.crt \
    apt-get update && \
    apt-get install -d \
        ca-certificates \
        openssl \
    && rm -rf /var/lib/apt/lists/*

################################################################################

FROM $DOCKER_REGISTRY/$UBUNTU_IMAGE_NAME:$UBUNTU_IMAGE_TAG AS ca-certificates

RUN --mount=type=bind,target=/var/cache/apt/archives/,source=/var/cache/apt/archives/,from=ca-certificates-debs \
    find /var/cache/apt/archives/ \
        -name "ca-certificates*.deb" \
        -o \
        -name "openssl*.deb" \
    | DEBIAN_FRONTEND=noninteractive xargs dpkg -i

################################################################################

FROM ca-certificates AS build-essential

RUN --mount=type=bind,target=/etc/apt/sources.list,source=sources.list \
    --mount=type=bind,target=/etc/ssl/certs/ca-certificates.crt,source=ca-certificates.crt \
    apt-get update && \
    apt-get install -y \
        build-essential \
    && rm -rf /var/lib/apt/lists/*

################################################################################

FROM build-essential AS cpython

ARG CURL_HTTP_PROXY
ARG CPYTHON_VERSION

WORKDIR /root/

RUN --mount=type=bind,target=/etc/apt/sources.list,source=sources.list \
    --mount=type=bind,target=/etc/ssl/certs/ca-certificates.crt,source=ca-certificates.crt \
    apt-get update && \
    apt-get install -y \
        curl \
        unzip \
        libbz2-dev \
        libffi-dev \
        libgdbm-compat-dev \
        libgdbm-dev \
        liblzma-dev \
        libncurses-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        lzma-dev \
        uuid-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN  --mount=type=bind,target=/etc/ssl/certs/ca-certificates.crt,source=ca-certificates.crt \
    curl -LO ${CURL_HTTP_PROXY:+-x $CURL_HTTP_PROXY} \
        https://github.com/python/cpython/archive/refs/tags/v$CPYTHON_VERSION.zip && \
    unzip v$CPYTHON_VERSION.zip && \
    rm v$CPYTHON_VERSION.zip

WORKDIR /root/cpython-$CPYTHON_VERSION/

RUN ./configure --with-pydebug && \
    make -s -j $(nproc) && \
    make install

################################################################################

FROM cpython AS cpython-with-gdb

ARG CURL_HTTP_PROXY
ARG GDB_VERSION

WORKDIR /root/

RUN --mount=type=bind,target=/etc/apt/sources.list,source=sources.list \
    --mount=type=bind,target=/etc/ssl/certs/ca-certificates.crt,source=ca-certificates.crt \
    apt-get update && \
    apt-get install -y \
        libgmp-dev \
        libmpfr-dev \
    && rm -rf /var/lib/apt/lists/*

RUN  --mount=type=bind,target=/etc/ssl/certs/ca-certificates.crt,source=ca-certificates.crt \
    curl -LO ${CURL_HTTP_PROXY:+-x $CURL_HTTP_PROXY} \
        https://sourceware.org/pub/gdb/releases/gdb-$GDB_VERSION.tar.gz && \
    tar xvzf gdb-$GDB_VERSION.tar.gz && \
    rm gdb-$GDB_VERSION.tar.gz

WORKDIR /root/gdb-$GDB_VERSION/

RUN ./configure --with-python=python3 && \
    make -j $(nproc) && \
    make install

WORKDIR /root/
