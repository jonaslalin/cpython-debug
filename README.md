# cpython-debugging

## 1.

```sh
cp templates/* .
```

## 2.

```sh
. ./utils.sh
```

then

```sh
pull_ubuntu_image
```

or

```sh
pull_ubuntu_image registry.example.com/ubuntu:jammy-20240627.1
```

## 3.

```sh
CURL_HTTPS_PROXY= \
podman build \
    --build-arg-file=argfile.conf \
    --no-cache \
    --pull=never \
    --secret=id=apt_sources,src=sources.list \
    --secret=id=ca_certificates,src=ca-certificates.crt \
    --secret=id=curl_https_proxy,env=CURL_HTTPS_PROXY \
    --security-opt=label=disable \
    --tag=cpython-debugging:latest \
    .
```

or

```sh
CURL_HTTPS_PROXY=http://proxy.example.com:8080 \
podman build \
    --build-arg-file=argfile.conf \
    --no-cache \
    --pull=never \
    --secret=id=apt_sources,src=sources.list \
    --secret=id=ca_certificates,src=ca-certificates.crt \
    --secret=id=curl_https_proxy,env=CURL_HTTPS_PROXY \
    --security-opt=label=disable \
    --tag=cpython-debugging:latest \
    .
```

## 4.

```sh
podman run --interactive --rm --tty cpython-debugging:latest
```
