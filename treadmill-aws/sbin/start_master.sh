#!/bin/sh

DISTRO=$(cd $(dirname $0)/.. && pwd)

usage() {
    cat << USAGE
Usage: $0 [OPTIONS] <install-dir>

Options:
   -c <CELL>                     : Cell name.
   -l <TREADMILL_LDAP>           : LDAP server - ldap://<host>:<port>.
   -b <TREADMILL_LDAP_SUFFIX>    : LDAP suffix.
   -d <TREADMILL_DNS_DOMAIN>     : DNS domain.
   -i <MYID>                     : Master ID (1,2,3)
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
        i)
            MYID=${OPTARG}
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

[ ! -z $INSTALL_DIR ] || usage
[ ! -z $TREADMILL_CELL ] || usage
[ ! -z $TREADMILL_LDAP ] || usage
[ ! -z $TREADMILL_LDAP_LIST ] || usage
[ ! -z $TREADMILL_LDAP_SUFFIX ] || usage
[ ! -z $TREADMILL_DNS_DOMAIN ] || usage
[ ! -z $TREADMILL_RUNTIME ] || usage

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

exec ${DISTRO}/bin/treadmill \
    --debug \
    admin install \
        --distro ${DISTRO} \
        --profile ms \
        --install-dir ${INSTALL_DIR} \
        --config ${INSTALL_DIR}/cell_config.yml \
        --override ldap_list=${TREADMILL_LDAP_LIST} \
    master \
        --master-id $MYID \
        --run
