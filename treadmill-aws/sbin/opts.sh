#!/bin/sh

DISTRO=$(cd $(dirname $0)/.. && pwd)

function usage {
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
   -t <TREADMILL_ISA>            : node|master|... - default "node".
   -i <INSTALL_DIR>              : install directory.
   -h                            : Print help and exit
USAGE

    exit 1
}

while getopts "c:l:L:b:d:t:" OPT; do
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
        t)
            TREADMILL_ISA=${OPTARG}
            ;;
        i)
            TREADMILL_INSTALL_DIR=${OPTARG}
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

# Default to node startup.
if [ -z $TREADMILL_ISA ]; then
    TREADMILL_ISA=node
fi    

echo Configuring Treadmill $TREADMILL_ISA"
env | grep TREADMILL_


