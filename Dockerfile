ARG UBUNTU_IMAGE=docker.io/library/ubuntu:jammy-20240627.1

ARG CPYTHON_VERSION=3.8.19
ARG GDB_VERSION=15.1

###############################################################################
#                          debs-for-ca-certificates                           #
###############################################################################

FROM $UBUNTU_IMAGE AS debs-for-ca-certificates

RUN --mount=type=secret,id=apt_sources,target=/etc/apt/sources.list,required=true,mode=0444 \
    --mount=type=secret,id=ca_certificates,target=/etc/ssl/certs/ca-certificates.crt,required=true,mode=0444 \
    apt-get update && \
    apt-get install -d \
        ca-certificates \
        openssl \
    && rm -rf /var/lib/apt/lists/*

###############################################################################
#                               ca-certificates                               #
###############################################################################

FROM $UBUNTU_IMAGE AS ca-certificates

RUN --mount=type=bind,target=/var/cache/apt/archives/,source=/var/cache/apt/archives/,from=debs-for-ca-certificates \
    find /var/cache/apt/archives/ \
        -name "ca-certificates*.deb" \
        -o \
        -name "openssl*.deb" \
    | DEBIAN_FRONTEND=noninteractive xargs dpkg -i

###############################################################################
#                               build-essential                               #
###############################################################################

FROM ca-certificates AS build-essential

RUN --mount=type=secret,id=apt_sources,target=/etc/apt/sources.list,required=true,mode=0444 \
    --mount=type=secret,id=ca_certificates,target=/etc/ssl/certs/ca-certificates.crt,required=true,mode=0444 \
    apt-get update && \
    apt-get install -y \
        build-essential \
    && rm -rf /var/lib/apt/lists/*

###############################################################################
#                                   cpython                                   #
###############################################################################

FROM build-essential AS cpython

ARG CPYTHON_VERSION

RUN --mount=type=secret,id=apt_sources,target=/etc/apt/sources.list,required=true,mode=0444 \
    --mount=type=secret,id=ca_certificates,target=/etc/ssl/certs/ca-certificates.crt,required=true,mode=0444 \
    --mount=type=secret,id=curl_https_proxy,required=true,mode=0444 \
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
    && rm -rf /var/lib/apt/lists/* && \
    cd /tmp/ && \
    HTTPS_PROXY=$(cat /run/secrets/curl_https_proxy) \
    curl -LO https://github.com/python/cpython/archive/refs/tags/v$CPYTHON_VERSION.zip && \
    unzip v$CPYTHON_VERSION.zip && \
    rm v$CPYTHON_VERSION.zip && \
    cd cpython-$CPYTHON_VERSION/ && \
    ./configure --with-pydebug && \
    make -s -j $(nproc) && \
    make install && \
    cd .. && \
    rm -rf cpython-$CPYTHON_VERSION/

###############################################################################
#                              cpython-with-gdb                               #
###############################################################################

FROM cpython AS cpython-with-gdb

ARG GDB_VERSION

RUN --mount=type=secret,id=apt_sources,target=/etc/apt/sources.list,required=true,mode=0444 \
    --mount=type=secret,id=ca_certificates,target=/etc/ssl/certs/ca-certificates.crt,required=true,mode=0444 \
    --mount=type=secret,id=curl_https_proxy,required=true,mode=0444 \
    apt-get update && \
    apt-get install -y \
        libgmp-dev \
        libmpfr-dev \
    && rm -rf /var/lib/apt/lists/* && \
    cd /tmp/ && \
    HTTPS_PROXY=$(cat /run/secrets/curl_https_proxy) \
    curl -LO https://sourceware.org/pub/gdb/releases/gdb-$GDB_VERSION.tar.gz && \
    tar xvzf gdb-$GDB_VERSION.tar.gz && \
    rm gdb-$GDB_VERSION.tar.gz && \
    cd gdb-$GDB_VERSION/ && \
    ./configure --with-python=python3 && \
    make -s -j $(nproc) && \
    make install && \
    cd .. && \
    rm -rf gdb-$GDB_VERSION/
