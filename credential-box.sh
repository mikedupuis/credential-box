#!/bin/sh

# TODO: Use file attributes to add extra protection to files

init () {
    CIPHER=-aes-256-cbc

    CREDENTIAL_DIR=~/credentials
    if [ ! -d ${CREDENTIAL_DIR} ]; then
        mkdir -p ${CREDENTIAL_DIR}
        if [ ! -d ${CREDENTIAL_DIR} ]; then
            echo ERROR: Cannot create credential directory ${CREDENTIAL_DIR}, exiting!
            exit 1
        fi
    fi
}

list_credentials() {
    find ${CREDENTIAL_DIR} -name "*.enc" | sort
}

set_credential() {
    CREDENTIAL_FILE=${CREDENTIAL_DIR}/$1.enc
    if [ -f "$CREDENTIAL_FILE" ]; then
        while :
        do
            echo "Credential $1 is already stored, do you want to overwrite it? [Y/n]: "
            read -r OVERWRITE
            OVERWRITE=$(echo "$OVERWRITE" | tr 'a-z A-Z')
            echo got overwrite "$OVERWRITE"
            
            if [ 'Y' = "${OVERWRITE}" -o 'N' = "${OVERWRITE}" ]; then
                break;
            fi

            echo "I don't understand, please try again"
        done

        if [ 'N' = "${OVERWRITE}" ]; then
            echo "Okay, I'll leave it alone"
            exit 0
        fi
    fi

    echo "Please enter your data: "
    read -r DATA

    echo "$DATA" | openssl enc ${CIPHER} -salt -a > "$CREDENTIAL_FILE"

    if [ -f "$CREDENTIAL_FILE" ]; then
        chmod 600 "$CREDENTIAL_FILE"
    else
        echo >&2 "Failed to save credential $1 !"
        exit 2
    fi
}

get_credential() {
    CREDENTIAL_FILE=${CREDENTIAL_DIR}/$1.enc
    if [ ! -f "$CREDENTIAL_FILE" ]; then
        echo >&2 "Unknown credential $1 !"
        exit 3
    fi

    openssl enc ${CIPHER} -a -d -in "$CREDENTIAL_FILE"
}

remove_credential() {
    CREDENTIAL_FILE=${CREDENTIAL_DIR}/$1.enc
    if [ ! -f "$CREDENTIAL_FILE" ]; then
        echo >&2 "Unknown credential $1 !"
        exit 3
    fi

    rm "$CREDENTIAL_FILE"
}

usage () {
    echo "$(basename $0) mode [args]"
    echo ""
    echo "MODE              ARGS"
    echo "------------------------"
    echo "list|ls           [none]"
    echo "get               key"
    echo "set               key"
    echo "remove|rm         key"
    echo ""
    echo "list|ls"
    echo "Required arguments: [none]"
    echo "Lists all stored keys"
    echo ""
    echo "get"
    echo "Required arguments: key"
    echo "Returns data stored for the given key"
    echo ""
    echo "set"
    echo "Required arguments: key"
    echo "Prompts the user for data, then stores the data under the given key"
    echo ""
    echo "remove|rm"
    echo "Required arguments: key"
    echo "Remove the given key"
}

init

case "$#" in
    1)
        case $1 in
            list)
                list_credentials
                ;;
            ls)
                list_credentials
                ;;
            *)
                usage
                exit 1
        esac
        exit 0
        ;;
    2)
        case $1 in
            get)
                get_credential "$2"
                ;;
            set)
                set_credential "$2"
                ;;
            remove)
                remove_credential "$2"
                ;;
            rm)
                remove_credential "$2"
                ;;
            *)
                usage
                exit 1
        esac
        exit 0
        ;;
    *)
        usage
        exit 1
        ;;
esac
