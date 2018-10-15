#!/bin/sh

# TODO: Use file attributes to add extra protection to files

init () {
    CIPHER=-aes-256-cbc
    GENERATOR='pwgen -nB1s 20'

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
    ls -r ${CREDENTIAL_DIR} | sed s/\.enc//g | sort
}

# Return 1 if it's okay to write to the given file, 0 otherwise
check_credential_overwrite() {
    echo check_credential_overwrite starting for $1
    CREDENTIAL_FILE=${CREDENTIAL_DIR}/$1.enc
    if [ -f "$CREDENTIAL_FILE" ]; then
        while :
        do
            echo "Credential $1 is already stored, do you want to overwrite it? [Y/n]: "
            read -r OVERWRITE
            OVERWRITE=$(echo "$OVERWRITE" | tr [a-z] [A-Z])
            
            if [ 'Y' = "${OVERWRITE}" -o 'N' = "${OVERWRITE}" ]; then
                break;
            fi

            echo "I don't understand, please try again"
        done

        if [ 'N' = "${OVERWRITE}" ]; then
            echo "Okay, I'll leave it alone"
            return 0
        fi
    fi

    return 1
}

write_credential() {
    echo "$1" | openssl enc ${CIPHER} -salt -a > "$2"

    if [ -f "$2" ]; then
        chmod 600 "$2"
    else
        echo >&2 "Failed to save credential: $2!"
        exit 2
    fi
}

set_credential() {
    CREDENTIAL_FILE=${CREDENTIAL_DIR}/$1.enc
    if [ -f "$CREDENTIAL_FILE" ]; then
        while :
        do
            echo "Credential $1 is already stored, do you want to overwrite it? [Y/n]: "
            read -r OVERWRITE
            OVERWRITE=$(echo "$OVERWRITE" | tr [a-z] [A-Z])
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
        echo >&2 "Failed to save credential: $1!"
        exit 2
    fi
}

read_credential() {
    CREDENTIAL_FILE=${CREDENTIAL_DIR}/$1.enc
    if [ ! -f "$CREDENTIAL_FILE" ]; then
        echo >&2 "Unknown credential: $1!"
        exit 3
    fi

    openssl enc ${CIPHER} -a -d -in "$CREDENTIAL_FILE"
}

get_credential() {
    CREDENTIAL=$(read_credential $1)
    if [ -z ${CREDENTIAL} ]; then
        exit 1
    fi

    echo ${CREDENTIAL}
}

remove_credential() {
    CREDENTIAL_FILE=${CREDENTIAL_DIR}/$1.enc
    if [ ! -f "$CREDENTIAL_FILE" ]; then
        echo >&2 "Unknown credential: $1!"
        exit 3
    fi

    read_credential $1 > /dev/null

    rm "$CREDENTIAL_FILE"

    echo removed credential $1
}

generate_credential() {
    CREDENTIAL_FILE=${CREDENTIAL_DIR}/$2.enc
    check_credential_overwrite $2
    can_overwrite=$?

    if [ 1 -ne ${can_overwrite} ]; then
        exit 1
    fi

    credential=$(${GENERATOR})
    data=$(echo ${@:3} ${credential})

    write_credential "${data}" ${CREDENTIAL_FILE}
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
    echo "generate|gen      key [prefix...]"
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
    echo ""
    echo "generate|gen"
    echo "Required arguments: key"
    echo "Optional arguments: prefix"
    echo "Generate a strong password for key, with the given prefixes appearing before the password"

}

init

case "$#" in
    # For modes which require EXACTLY 1 argument
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

    # For modes which require EXACTLY 2 arguments
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
            generate)
                generate_credential $@
                ;;
            gen)
                generate_credential $@
                ;;
            *)
                usage
                exit 1
        esac
        exit 0
        ;;
    *)
        case $1 in
            generate)
                generate_credential $@
                ;;
            gen)
                generate_credential $@
                ;;
            *)
                usage
                exit 1
        esac
esac
