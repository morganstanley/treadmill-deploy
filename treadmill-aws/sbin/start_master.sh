#!/bin/sh

source ${0%/*}/opts.sh

kinit -k -l 1d

set -e

if [ -z $TREADMILL_INSTALL_DIR ]; then
    TREADMILL_INSTALL_DIR=/var/lib/treadmill-master
fi    

INSTALL_DIR=$TREADMILL_INSTALL_DIR
unset TREADMILL_INSTALL_DIR
unset TREADMILL_ISA

echo "Installing Treadmill master: $INSTALL_DIR"

mkdir -vp ${INSTALL_DIR}

${DISTRO}/bin/treadmill \
    --outfmt yaml \
    admin ldap cell configure ${TREADMILL_CELL} \
    > ${INSTALL_DIR}/cell_config.yml


echo "Starting Treadmill master."
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
