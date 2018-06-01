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

while getopts "hc:l:L:b:d:r:" OPT; do
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

if [ -n "$*" ]; then
    MAYBE_OVERRIDES=$(IFS=, ; echo "--override $*");
else
    MAYBE_OVERRIDES=""
fi

echo Configuring Treadmill: $INSTALL_DIR
env | grep TREADMILL_

set -e

HOSTNAME=$(hostname --fqdn)
export HOSTNAME

# NOTE: Obtaining tickets is needed for the LDAP connection below.
kinit -k -l 1d

mkdir -pv ${INSTALL_DIR}

# Try to get cell and server configuration.
# If LDAP is down, this will fail but if an existing config is already dumped,
# the node will still start.
${DISTRO}/bin/treadmill \
    --outfmt yaml \
    admin ldap cell configure ${TREADMILL_CELL} \
    > ${INSTALL_DIR}/cell_config.yml.tmp \
    && mv -v ${INSTALL_DIR}/cell_config.yml{.tmp,} \
    || true

${DISTRO}/bin/treadmill \
    --outfmt yaml \
    admin ldap server configure ${HOSTNAME} \
    > ${INSTALL_DIR}/server_config.yml.tmp \
    && mv -v ${INSTALL_DIR}/server_config.yml{.tmp,} \
    || true

${DISTRO}/bin/treadmill \
    --debug \
    admin install \
        --distro ${DISTRO} \
        --profile aws \
        --install-dir ${INSTALL_DIR} \
        --config  ${INSTALL_DIR}/cell_config.yml \
        --config  ${INSTALL_DIR}/server_config.yml \
        $MAYBE_OVERRIDES \
    node

echo Starting Treadmill.
exec ${INSTALL_DIR}/bin/run.sh
