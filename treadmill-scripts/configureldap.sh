#!/bin/bash

#########################
# The command line help #
#########################
display_help() {
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   -s, --subnet           AWS subnet IDs; e.g. -s subnet-1234 -s subnet-5678."
    echo "                          One server will be created per subnet."
    echo "   -a, --ami              AWS AMI image; e.g. ami-1234"
    echo "   -d, --domain           IPA domain; e.g. ipa.foo.com"
    echo "   -l, --ldapsuffix       LDAP suffix; e.g. dc=foo,dc=com"
    echo "   -r, --realm            Realm; e.g. FOO.COM"
    echo "   -p, --proid            LDAP auth user; e.g admin"
    echo
    exit 0
}
SUBNETS=()

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -s|--subnet)
    SUBNETS=("${SUBNETS[@]}" "$2")
    shift # past argument
    shift # past value
    ;;
    -a|--ami)
    AMI="$2"
    shift # past argument
    shift # past value
    ;;
    -d|--domain)
    TREADMILL_DNS_DOMAIN="$2"
    shift # past argument
    shift # past value
    ;;
    -l|--ldapsuffix)
    TREADMILL_LDAP_SUFFIX="$2"
    shift # past argument
    shift # past value
    ;;
    -r|--realm)
    REALM="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--proid)
    TREADMILL_PROID="$2"
    shift # past argument
    shift # past value
    ;;
    -h|--help)
    display_help
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

echo 
echo "AWS SUBNETS       = ${SUBNETS[@]}"
echo "AWS AMI           = ${AMI}"
echo "TREADMILL DOMAIN  = ${TREADMILL_DNS_DOMAIN}"
echo "LDAP SUFFIX       = ${TREADMILL_LDAP_SUFFIX}"
echo "REALM             = ${REALM}"
echo "PROID             = ${TREADMILL_PROID}"
echo

echo "==="
while true
do
	read -p "Continue (y/n)? " answer
	case $answer in
		[yY]* ) break;;
		[nN]* ) echo "Exiting."; exit 1;;
		* )     echo "Invalid input";;
	esac
done

#########################
# 	 Setup		#
#########################

COUNT=${#SUBNETS[@]}

# Insert null value at pos 0 to index array from 1
SUBNETS=("" "${SUBNETS[@]}")

# Generate list of LDAP masters
TREADMILL_LDAP=''
for i in `seq 1 ${COUNT}`
do
        TREADMILL_LDAP+=ldap://ldap-${i}.${TREADMILL_DNS_DOMAIN}:22389,
done
# Trim trailing comma
TREADMILL_LDAP="${TREADMILL_LDAP::-1}"

# Generate tmpdir for cell definitions
tmpdir=$(mktemp -d -p /tmp)
if [[ ! "${tmpdir}" || ! -d "${tmpdir}" ]]; then
	echo "Could not create temp dir"
	exit 1
fi

# Deletes the temp directory on exit
function cleanup {      
	rm -rf "${tmpdir}"
}
trap cleanup EXIT

# Write userdata to file
cat << E%O%F > ${tmpdir}/LDAP.yaml
---
treadmill_cell: -
treadmill_dns_domain: ${TREADMILL_DNS_DOMAIN}
treadmill_ldap: ${TREADMILL_LDAP}
treadmill_ldap_suffix: ${TREADMILL_LDAP_SUFFIX}
treadmill_krb5_realm: ${REALM}
treadmill_proid: ${TREADMILL_PROID}
treadmill_isa: openldap
E%O%F

#########################
#    Start LDAP hosts   #
#########################

# Build hosts
new_hosts=0
for i in `seq 1 ${COUNT}`
do
	# Check that host does not already exist:
	if $(ipa host-show ldap-${i}.${TREADMILL_DNS_DOMAIN} >/dev/null 2>&1); then
		echo 'Host exists; skipping'
		continue
	fi

        hostname=`treadmill admin aws instance create \
                 --image ${AMI} \
                 --subnet ${SUBNETS[$i]} \
                 --size m5.large \
                 --disk-size 30G \
                 --data ${tmpdir}/LDAP.yaml \
                 --hostname ldap-${i} \
                 --role ldap`
        echo ${hostname}
	ipa service-add --force ldap/${hostname}.@${REALM} >/dev/null 2>&1 && echo "IPA Service Created"
        new_hosts+=1
done

if [ $new_hosts -eq 0 ]; then
	echo "All LDAP hosts exist; exiting"
	exit 0
fi

#########################
#   Check LDAP hosts    #
#########################

# Check hosts have joined domain 
for i in `seq 1 ${COUNT}`
do
        until ipa host-show ldap-${i}.${TREADMILL_DNS_DOMAIN} | grep -q SSH\ public\ key\ fingerprint
        do
                echo Waiting for ldap-${i} to join the domain...
                sleep 5
        done
        echo ldap-${i} has joined the domain.
done
echo -e "All servers have joined the domain.\n"


# Check LDAP online
until nc -z -w 5 ldap-1.${TREADMILL_DNS_DOMAIN} 22389 2>/dev/null 
do 
	echo 'Waiting for LDAP to start'
	sleep 5
done

echo -e "LDAP online.\n"

#########################
#    Bootstrap LDAP     #
#########################

echo -e "Bootstrapping LDAP:.\n"
sleep 5
treadmill admin ldap init
sleep 2
treadmill admin ldap schema --update

