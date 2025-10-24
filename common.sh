#!/bin/bash

# common functions

cli_version() {
    echo `container --version | awk '{print $4}'`
}

dns_default() {
    local VERSION=$(cli_version)
    if [[ $VERSION == 0.4.* ]]; then
        local NAME=`container system dns default inspect`
        if [ $? -ne 0 ]; then
            return ""
        fi
    else
        # v0.5.0-
        local NAME=`container system property get dns.domain`
        if [ $? -ne 0 ]; then
            return ""
        fi
    fi
    echo $NAME
}

volume_exists() {
    local VOLUME=$1

    container volume inspect $VOLUME > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        return 0
    fi
    return 1
}

volume_create() {
    local VOLUME=$1

    container volume create $VOLUME > /dev/null
    if [ $? -ne 0 ]; then
        echo "Failed to create volume $VOLUME"
        exit 1
    fi
    echo "Volume $VOLUME created."
}

volume_delete() {
    local VOLUME=$1

    volume_exists $VOLUME
    if [ $? -eq 0 ]; then
        return
    fi

    container volume delete $VOLUME > /dev/null
    if [ $? -ne 0 ]; then
        echo "Failed to delete volume $VOLUME"
        #exit 1
    fi
    echo "Volume $VOLUME deleted."
}

image_exists() {
    local IMAGE=$1

    container images inspect $IMAGE > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        return 0
    fi
    return 1
}

image_rm() {
    local IMAGE=$1

    image_exists $IMAGE
    if [ $? -eq 0 ]; then
        return
    fi

    container images rm $IMAGE > /dev/null
    if [ $? -ne 0 ]; then
        echo "Failed to remove image $IMAGE"
        #exit 1
    fi
    echo "Image $IMAGE removed."
}

container_exists() {
    local CONTAINER=$1

    local RESULT=`container inspect $CONTAINER`
    # container inspect returns '[]' instead of an error 
    # when container doesn't exist.
    if [ $? -ne 0 ]; then
        return 0
    fi
    if [ "$RESULT" = "[]" ]; then
        return 0
    fi
    return 1
}

container_rm() {
    local CONTAINER=$1
    container_exists $CONTAINER
    if [ $? -eq 0 ]; then
        return
    fi
    container rm $CONTAINER > /dev/null
    if [ $? -ne 0 ]; then
        echo "Failed to remove $CONTAINER container"
        #exit 1
    fi
    echo "Container $CONTAINER removed."
}

container_start() {
    local CONTAINER=$1
    container start $CONTAINER > /dev/null
    if [ $? -ne 0 ]; then
        echo "Failed to start $CONTAINER container"
        #exit 1
    fi
    echo "Container $CONTAINER started."
}

container_stop() {
    local CONTAINER=$1
    container_exists $CONTAINER
    if [ $? -eq 0 ]; then
        return
    fi
    container stop $CONTAINER > /dev/null
    if [ $? -ne 0 ]; then
        echo "Failed to stop $CONTAINER container"
        #exit 1
    fi
    echo "Container $CONTAINER stopped."
}

# Reverse a string of words
# "foo bar baz" -> "baz bar foo"
reverse_string() {
    local array=($1)  # To array
    local reversed=""

    for ((i=${#array[@]}-1; i>=0; i--)); do
        reversed="$reversed ${array[i]}"
    done
    echo $reversed
}

# Stop and remove containers
cleanup_all_containers() {
    local CONTAINERS=$@
    CONTAINERS=`reverse_string "$CONTAINERS"`

    for CONTAINER in $CONTAINERS; do
        container_stop $CONTAINER
    done
    for CONTAINER in $CONTAINERS; do
        container_rm $CONTAINER
    done
}

start_all() {
    local CONTAINERS=$@

    for CONTAINER in $CONTAINERS; do
        container_start $CONTAINER
    done
}

stop_all() {
    local CONTAINERS=$@
    CONTAINERS=`reverse_string "$CONTAINERS"`

    for CONTAINER in $CONTAINERS; do
        container_stop $CONTAINER
    done
}
