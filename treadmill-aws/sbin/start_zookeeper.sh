#!/bin/sh

source ${0%/*}/opts.sh

set -e

if [ -z $TREADMILL_INSTALL_DIR ]; then
    TREADMILL_INSTALL_DIR=/var/lib/treadmill-zookeeper
fi    

INSTALL_DIR=$TREADMILL_INSTALL_DIR
unset TREADMILL_INSTALL_DIR
unset TREADMILL_ISA

function zookeeper_usage {
    MSG=$1
    if [ "$MSG" != "" ]; then
        echo Usage error:
        echo 
        echo "  $MSG"
        echo
    fi
    cat << USAGE
Usage: 
    $0 [OPTIONS]

Options:
   -m <myid>                     : Zookeeper node id.
   -h                            : Print help and exit
USAGE

    exit 1
}

OPTIND=1
while getopts "m:" OPT; do
    case "${OPT}" in
        m)
            TREADMILL_ZOOKEEPER_MYID=${OPTARG}
            ;;
        h)
            zookeeper_usage
            ;;
        *)
            zookeeper_usage
            ;;
    esac
done
shift $((OPTIND-1))

[ ! -z $TREADMILL_ZOOKEEPER_MYID ] || zookeeper_usage "Missing option: -m MYID"

echo "Installing Treadmill Zookeeper: $INSTALL_DIR"

if [ $UID == 0 ]; then
    /bin/mount --make-rprivate /

    # NOTE: Obtaining tickets is needed for the LDAP connection below.
    export KRB5CCNAME=$(mktemp)

    until kinit -k -l 1d
    do
        echo Sleeping until server joined to IPA...
        sleep 5
    done
fi    
klist

until HOSTNAME=$(hostname --fqdn)
do
  echo "Waiting for D-BUS to return hostname..."
  sleep 2
done
export HOSTNAME

export TREADMILL_KRB_REALM=$(k-realm)

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
    --debug \
    admin install \
        --distro ${DISTRO} \
        --profile aws \
        --install-dir ${INSTALL_DIR} \
        --config  ${INSTALL_DIR}/cell_config.yml \
    zookeeper \
        --master-id ${TREADMILL_ZOOKEEPER_MYID} \
        --no-run

echo Starting Treadmill Zookeeper.
if [ $UID == 0 ]; then
    exec ${INSTALL_DIR}/treadmill/bin/run.sh
else
    echo run as root: ${INSTALL_DIR}/treadmill/bin/run.sh
fi
