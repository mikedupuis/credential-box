#!/bin/sh

# TODO: Use file attributes to add extra protection to files

if [ 1 -gt $# -o 3 -lt $# ]; then
    echo "$0 list"
    echo "$0 get key"
    echo "$0 set key value"
    exit 1
fi

if [ 1 = $# -a "list" != "$1" ]; then
    echo "$0 list"
    echo "$0 get key"
    echo "$0 set key value"
    exit 1
fi
    
if [ 2 = $# -a "get" != "$1" ]; then
    echo "$0 list"
    echo "$0 get key"
    echo "$0 set key value"
    exit 1
fi

if [ 3 = $# -a "set" != "$1" ]; then
    echo "$0 list"
    echo "$0 get key"
    echo "$0 set key value"
    exit 1
fi

CREDENTIAL_DIR=/tmp/credentials
if [ ! -d ${CREDENTIAL_DIR} ]; then
    mkdir -p ${CREDENTIAL_DIR}
    if [ ! -d ${CREDENTIAL_DIR} ]; then
        echo ERROR: Cannot create credential directory ${CREDENTIAL_DIR}, exiting!
        exit 1
    fi
fi

CREDENTIAL_FILE=${CREDENTIAL_DIR}/$2.enc
CIPHER=-aes-256-cbc

if [ "$1" = "list" ]; then
    ls ${CREDENTIAL_DIR} | sed s/\.enc//g | sort
fi

if [ "$1" = "set" ]; then
    if [ -f ${CREDENTIAL_FILE} ]; then
        while :
        do
            echo "Credential $2 is already stored, do you want to overwrite it? [Y/n]: "
            read OVERWRITE
            OVERWRITE=$(echo ${OVERWRITE} | tr [a-z] [A-Z])
            
            if [ 'Y' = "${OVERWRITE}" -o 'N' = "${OVERWRITE}" ]; then
                echo "I don't understand, please try again"
                break;
            fi
        done

        if [ 'N' = "${OVERWRITE}" ]; then
            echo "Okay, I'll leave it alone"
            exit 0
        fi
    fi
    
    echo $3 | openssl enc ${CIPHER} -salt -a > /tmp/credentials/$2.enc

    if [ -f /tmp/credentials/$2.enc ]; then
        chmod 600 $2.enc
    else
        echo Failed to save credential $2! >2
        exit 2
    fi
fi

if [ "$1" = "get" ]; then
    if [ ! -f /tmp/credentials/$2.enc ]; then
        echo Unknown credential $2! >2
        exit 3
    fi

    openssl enc ${CIPHER} -a -d -in /tmp/credentials/$2.enc
fi

