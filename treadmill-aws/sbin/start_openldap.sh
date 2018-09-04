#!/bin/sh

set -e

if [ -z $TREADMILL_INSTALL_DIR ]; then
    TREADMILL_INSTALL_DIR=/var/lib/treadmill-openldap
fi    

if [ -z $DISTRO ]; then
    DISTRO=$(cd $(dirname $0)/.. && pwd)
fi

INSTALL_DIR=$TREADMILL_INSTALL_DIR
unset TREADMILL_INSTALL_DIR
unset TREADMILL_ISA

function openldap_usage {
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
   -m master1,master2            : List of openldap masters
   -h                            : Print help and exit
USAGE

    exit 1
}

OPTIND=1
while getopts "m:" OPT; do
    case "${OPT}" in
        m)
            TREADMILL_OPENLDAP_MASTERS=${OPTARG}
            ;;
        h)
            openldap_usage
            ;;
        *)
            openldap_usage
            ;;
    esac
done
shift $((OPTIND-1))

echo "Installing Treadmill OpenLDAP: $INSTALL_DIR"

/bin/mount --make-rprivate /

HOSTNAME=$(hostname --fqdn)
export HOSTNAME

# Repeat kinit until successful
until kinit -k -l 1d;
do
    echo Sleeping until server joined to IPA...
    sleep 10
done

klist

mkdir -pv ${INSTALL_DIR}

mkdir -p /var/spool/keytabs-services/
response=$(ipa service-add ldap/$(hostname)@$(k-realm) 2>&1)
RESULT=$?
if [ $RESULT -eq 0 ]; then
	ipa-getkeytab -p ldap/$(hostname)@$(k-realm) -k /var/spool/keytabs-services/ldap-$(hostname).keytab
else
	echo $response | grep -q 'already exists' && echo 'Service already exists' || echo $response
fi

chown -R treadmld:treadmld /var/spool/keytabs-services/*

export TREADMILL_KRB_REALM=$(k-realm)
export KRB5_KTNAME=/var/spool/keytabs-services/ldap-`hostname`.keytab

${DISTRO}/bin/treadmill \
    --debug \
    admin install \
        --distro ${DISTRO} \
        --profile aws \
        --install-dir ${INSTALL_DIR} \
    openldap \
        --owner treadmld \
        --uri ldap://`hostname`:22389 \
	--env linux \
        --gssapi \
        --masters $TREADMILL_OPENLDAP_MASTERS 


echo Starting Openldap.
exec ${INSTALL_DIR}/bin/run.sh

