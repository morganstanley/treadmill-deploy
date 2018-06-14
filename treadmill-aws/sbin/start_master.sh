#!/bin/sh

DISTRO=$(cd $(dirname $0)/.. && pwd)

usage() {
    MSG=$1
    if [ "$MSG" != "" ]; then
        echo Usage error:
        echo 
        echo "  $MSG"
        echo
    fi
    cat << USAGE
Usage: $0 [OPTIONS] <install-dir>

Options:
   -c <CELL>                     : Cell name.
   -l <TREADMILL_LDAP>           : LDAP server - ldap://<host>:<port>.
   -b <TREADMILL_LDAP_SUFFIX>    : LDAP suffix.
   -d <TREADMILL_DNS_DOMAIN>     : DNS domain.
   -h                            : Print help and exit
USAGE

    exit 1
}


usage() {
    echo -n "Usage: $0 -c CELL -i MYID -l LDAP [-L LDAP_LIST] "
    echo "-b LDAP_SEARCH_BASE [-d DNS_DOMAIN]"
    exit 1
}

while getopts "c:i:l:L:b:d:" OPT; do
    case "${OPT}" in
        c)
            TREADMILL_CELL=${OPTARG}
            ;;
        l)
            TREADMILL_LDAP=${OPTARG}
            ;;
        L)
            TREADMILL_LDAP_LIST=${OPTARG}
            ;;
        b)
            TREADMILL_LDAP_SUFFIX=${OPTARG}
            ;;
        d)
            TREADMILL_DNS_DOMAIN=${OPTARG}
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

INSTALL_DIR=$1

if [ -z $TREADMILL_LDAP_LIST ]; then
    TREADMILL_LDAP_LIST=$TREADMILL_LDAP
fi

[ ! -z $INSTALL_DIR ] || usage "Missing argument: <install-dir>."
[ ! -z $TREADMILL_CELL ] || usage "Missing option: -c CELL"
[ ! -z $TREADMILL_LDAP ] || usage "Missing option: -l LDAP"
[ ! -z $TREADMILL_LDAP_LIST ] || usage "Missing option: -L LDAP_LIST"
[ ! -z $TREADMILL_LDAP_SUFFIX ] || usage "Missing option: -b LDAP_SUFFIX"
[ ! -z $TREADMILL_DNS_DOMAIN ] || usage "Missing option: -d DNS_DOMAIN"

export TREADMILL_CELL
export TREADMILL_LDAP
export TREADMILL_LDAP_LIST
export TREADMILL_LDAP_SUFFIX
export TREADMILL_DNS_DOMAIN

echo Configuring Treadmill: $INSTALL_DIR
env | grep TREADMILL_

kinit -k -l 1d

set -e

mkdir -vp ${INSTALL_DIR}

${DISTRO}/bin/treadmill \
    --outfmt yaml \
    admin ldap cell configure ${TREADMILL_CELL} \
    > ${INSTALL_DIR}/cell_config.yml

# TODO: --master-id is not required, it is needed on zk startup but not
#       master startup.

exec ${DISTRO}/bin/treadmill \
    --debug \
    admin install \
        --distro ${DISTRO} \
        --profile aws \
        --install-dir ${INSTALL_DIR} \
        --config ${INSTALL_DIR}/cell_config.yml \
        --override ldap_list=${TREADMILL_LDAP_LIST} \
    master \
	--run
