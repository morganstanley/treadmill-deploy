#!/bin/sh

source ${0%/*}/opts.sh

set -e

if [ -z $TREADMILL_INSTALL_DIR ]; then
    TREADMILL_INSTALL_DIR=/var/lib/treadmill
fi    

INSTALL_DIR=$TREADMILL_INSTALL_DIR
unset TREADMILL_INSTALL_DIR
unset TREADMILL_ISA

echo "Installing Treadmill node: $INSTALL_DIR"

/bin/mount --make-rprivate /

# NOTE: Obtaining tickets is needed for the LDAP connection below.
export KRB5CCNAME=$(mktemp)

# Repeat kinit until successful
until kinit -k -l 1d;
do
    echo Sleeping until server joined to IPA...
    sleep 10
done

klist

until HOSTNAME=$(hostname --fqdn)
do 
  echo "Waiting for D-BUS to return hostname..."
  sleep 2
done
export HOSTNAME
export TREADMILL_HOSTNAME=${HOSTNAME}

mkdir -pv ${INSTALL_DIR}

# Try to get cell and server configuration.
# If LDAP is down, this will fail but if an existing config is already dumped,
# the node will still start.
while [ ! -f ${INSTALL_DIR}/cell_config.yml]
do
    ${DISTRO}/bin/treadmill \
        --outfmt yaml \
        --debug \
        admin ldap cell configure ${TREADMILL_CELL} \
        > ${INSTALL_DIR}/cell_config.yml.tmp \
        && mv -v ${INSTALL_DIR}/cell_config.yml{.tmp,} \
        || sleep 1
done

while [ ! -f ${INSTALL_DIR}/server_config.yml]
do
    ${DISTRO}/bin/treadmill \
        --outfmt yaml \
        --debug \
        admin ldap server configure ${HOSTNAME} \
        > ${INSTALL_DIR}/server_config.yml.tmp \
        && mv -v ${INSTALL_DIR}/server_config.yml{.tmp,} \
        || sleep 1
done

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
