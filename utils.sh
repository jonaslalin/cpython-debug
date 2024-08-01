#!/usr/bin/env bash

pull_ubuntu_image()
{
    local CUSTOM_UBUNTU_IMAGE=$1
    local UBUNTU_IMAGE=$(. ./argfile.conf && echo $UBUNTU_IMAGE)

    podman pull ${CUSTOM_UBUNTU_IMAGE:-$UBUNTU_IMAGE}

    if [[ -n "$CUSTOM_UBUNTU_IMAGE" ]]; then
        echo "Obfuscating origin..."
        podman tag $CUSTOM_UBUNTU_IMAGE $UBUNTU_IMAGE
        podman rmi $CUSTOM_UBUNTU_IMAGE
    fi
}
