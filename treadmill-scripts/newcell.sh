#!/bin/bash

#########################
# The command line help #
#########################
display_help() {
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   -s, --subnet           AWS subnet IDs; e.g. -s subnet-1234 -s subnet-5678 -s subnet-9999"
    echo "   -a, --ami              AWS AMI image; e.g. ami-1234"
    echo "   -c, --cell             New Treadmill cell name; e.g. userdev"
    echo "   -d, --domain           IPA domain; e.g. ipa.foo.com"
    echo "   -l, --ldap             LDAP servers; e.g. -l ldap://ldap.foo.com:389 -l ldap://ldap2.foo.com:389"
    echo "   -r, --registry         Docker registries; e.g -r reg1.foo.com:8000 -r reg2.foo.com:8000"
    echo "   -p, --proid            Zookeeper auth user; e.g admin"
    echo "   --location             Cell location; e.g. us-east-1"
    echo
    exit 0
}
SUBNETS=()
DOCKER_REGISTRIES=()
LDAP_SRVS=()

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
    -c|--cell)
    TREADMILL_CELL="$2"
    shift # past argument
    shift # past value
    ;;
    -d|--domain)
    TREADMILL_DNS_DOMAIN="$2"
    shift # past argument
    shift # past value
    ;;
    -l|--ldap)
    LDAP_SRVS=("${LDAP_SRVS[@]}" "$2")
    shift # past argument
    shift # past value
    ;;
    -r|--registry)
    DOCKER_REGISTRIES=("${DOCKER_REGISTRIES[@]}" "$2")
    shift # past argument
    shift # past value
    ;;
    -p|--proid)
    PROID="$2"
    shift # past argument
    shift # past value
    ;;
    --location)
    LOCATION="$2"
    shift # past argument
    shift # past value
    ;;
    -h|--help)
    display_help
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ -v ${LOCATION} ]; then
	LOCATION="local.local"
fi

if [ ! ${#SUBNETS[@]} -eq 3 ]; then
	echo -e "Please pass exactly three subnets; exiting."
	exit 1
fi

echo 
echo "AWS SUBNETS       = ${SUBNETS[@]}"
echo "AWS AMI           = ${AMI}"
echo "TREADMILL CELL    = ${TREADMILL_CELL}"
echo "TREADMILL DOMAIN  = ${TREADMILL_DNS_DOMAIN}"
echo "TREADMILL LDAPS   = ${LDAP_SRVS[@]}"
echo "DOCKER REGISTRIES = ${DOCKER_REGISTRIES[@]}"
echo "PROID             = ${PROID}"
echo "LOCATION          = ${LOCATION}"
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

# Format LDAP server array to string and set as env variable
TREADMILL_LDAP=$(echo ${LDAP_SRVS[@]} | tr " " ",")

TREADMILL_ZOOKEEPER="zookeeper.sasl://${PROID}@${TREADMILL_CELL}-zk-1.${TREADMILL_DNS_DOMAIN}:2181,${TREADMILL_CELL}-zk-2.${TREADMILL_DNS_DOMAIN}:2181,${TREADMILL_CELL}-zk-3.${TREADMILL_DNS_DOMAIN}:2181/treadmill/${TREADMILL_CELL}"

# Insert null value at pos 0 to index array from 1
SUBNETS=("" "${SUBNETS[@]}")

# Generate tmpdir for cell definitions
tmpdir=$(mktemp -d -p /tmp)
echo "Created temp working directory ${tmpdir}"
if [[ ! "${tmpdir}" || ! -d "${tmpdir}" ]]; then
	echo "Could not create temp dir"
	exit 1
fi

# Deletes the temp directory on exit
function cleanup {      
	rm -rf "${tmpdir}"
	echo "Deleted temp working directory ${tmpdir}"
}
trap cleanup EXIT

# Check if cell already defined
treadmill admin ldap cell list | grep ${TREADMILL_CELL}
RESULT=$?
if [ ${RESULT} -eq 0 ]; then
	echo "Cell already in LDAP"
	exit 1
fi

# Define docker_registry for cell.
echo "{docker_registries: ['$(echo ${DOCKER_REGISTRIES[@]} | tr " " ",")']}" > ${tmpdir}/${TREADMILL_CELL}.json

# Define cell in LDAP
treadmill admin ldap cell configure ${TREADMILL_CELL} \
	--version 3.7 \
	--username ${PROID} \
	--location ${LOCATION} \
	--data ${tmpdir}/${TREADMILL_CELL}.json \
        > /dev/null
        echo ${TREADMILL_CELL} defined in LDAP.

# Define Zookeepers
for i in $(seq 1 3)
do
	treadmill admin ldap cell insert ${TREADMILL_CELL} \
	--idx ${i}  \
	--hostname ${TREADMILL_CELL}-zk-${i}.${TREADMILL_DNS_DOMAIN} \
	--client-port 2181 \
	--jmx-port 8989 \
	--followers-port 2888 \
	--election-port 3888 \
        > /dev/null
        echo ZK ${TREADMILL_CELL}-zk-${i}.${TREADMILL_DNS_DOMAIN} defined in LDAP.
done
echo -e "LDAP configured for cell.\n"


# Create Zookeepers
echo -e "===\nStarting Zookeepers...\n"
for i in $(seq 1 3)
do
    cat << E%O%F > ${tmpdir}/${TREADMILL_CELL}.yaml
---
treadmill_cell: ${TREADMILL_CELL}
treadmill_ldap: ${TREADMILL_LDAP}
treadmill_ldap_suffix: ${TREADMILL_LDAP_SUFFIX}
treadmill_dns_domain: ${TREADMILL_DNS_DOMAIN}
treadmill_zookeeper_myid: "${i}"
treadmill_isa: zookeeper
E%O%F
	hostname=`treadmill admin aws instance create \
                 --image ${AMI} \
                 --subnet ${SUBNETS[$i]} \
                 --size m5.2xlarge \
                 --disk-size 30G \
                 --data ${tmpdir}/${TREADMILL_CELL}.yaml \
                 --hostname ${TREADMILL_CELL}-zk-${i} \
                 --role zookeeper` && echo ${hostname} created.
done

echo -e "Kerberos configured for cell.\n"

# Check Zookeepers online
for i in $(seq 1 3)
do
	# Check host joined domain 
        until ipa host-show ${TREADMILL_CELL}-zk-${i} | grep -q SSH\ public\ key\ fingerprint
	do 
                echo Waiting for ${TREADMILL_CELL}-zk-${i} to join the domain...
		sleep 5
	done
        echo ${TREADMILL_CELL}-zk-${i} has joined the domain.
done
echo -e "All servers have joined the domain.\n"

# Confirm Zookeeper has started
for i in $(seq 1 3)
do
	# Check ZK status
	until echo ruok | nc -w 5 ${TREADMILL_CELL}-zk-${i} 2181 2>/dev/null | grep -q imok
	do
                echo Waiting for ${TREADMILL_CELL}-zk-${i} to start zookeeper...
		sleep 5
	done
        echo ${TREADMILL_CELL}-zk-${i} has started Zookeeper.
done
echo -e "All servers have started Zookeeper.\n"

# Check Zookeeper quorum
for i in $(seq 1 3)
do
        # Check ZK leader/follower status
        until echo mntr | nc -w 5 ${TREADMILL_CELL}-zk-$i 2181 2>/dev/null | grep -q 'zk_server_state'
        do
                echo Waiting for ${TREADMILL_CELL}-zk-$i to signal quorum joined...
                sleep 5
        done
        echo ${TREADMILL_CELL}-zk-$i has joined quorum.

done
echo -e "Zookeeper quorum online.\n"

# Set up Zookeeper namespace
until treadmill sproc --cell ${TREADMILL_CELL} scheduler --once > /dev/null 
do
	sleep 5
	echo -e 'Bootstrapping namespace...\n'
done
echo -e 'Zookeeper namespace initialized.\n'

# Create ZK TXT records
treadmill admin cell --cell ${TREADMILL_CELL} configure-dns >/dev/null && echo 'Configured ZK DNS records.'

# Start ticket locker
echo -e 'Please log in to IPA server and run the following commands to start cell ticketlocker:\n'
echo "cat << E%O%F > /etc/ticketlocker/${TREADMILL_CELL}
TREADMILL_CELL=${TREADMILL_CELL}
E%O%F
"
echo -e "systemctl enable --now ticketlocker@${TREADMILL_CELL}.service\n"

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

# Create 3 nodes
echo -e "===\nStarting nodes to host mgmt APIs..."
for i in `seq 1 3`
do
    cat << E%O%F > $tmpdir/${TREADMILL_CELL}.yaml
---
treadmill_cell: ${TREADMILL_CELL}
treadmill_ldap: ${TREADMILL_LDAP}
treadmill_ldap_suffix: ${TREADMILL_LDAP_SUFFIX}
treadmill_dns_domain: ${TREADMILL_DNS_DOMAIN}
treadmill_isa: node 
E%O%F
        hostname=`treadmill admin aws instance create \
                 --image ${AMI} \
                 --subnet ${SUBNETS[$i]} \
                 --size m5.2xlarge \
                 --disk-size 30G \
                 --data $tmpdir/${TREADMILL_CELL}.yaml \
                 --hostgroup treadmill-nodes \
                 --hostname ${TREADMILL_CELL}-node-$i \
                 --role node`
        echo $hostname created.

	treadmill admin ldap server configure $hostname --cell ${TREADMILL_CELL} > /dev/null
done
echo -e 'Servers configured in LDAP\n'

# Check host joined domain
for i in `seq 1 3`
do
        until ipa host-show ${TREADMILL_CELL}-node-$i | grep -q SSH\ public\ key\ fingerprint
        do
                echo Waiting for ${TREADMILL_CELL}-node-$i to join the domain...
                sleep 5
        done
        echo ${TREADMILL_CELL}-node-$i has joined the domain.
done
echo -e "All nodes have joined the domain\n"

# Check host is in communication with Zookeepers:
for i in `seq 1 3`
do
	hostip=`dig +short ${TREADMILL_CELL}-node-${i}.${TREADMILL_DNS_DOMAIN}`
	echo ${TREADMILL_CELL}-node-${i}.${TREADMILL_DNS_DOMAIN} is at IP ${hostip}
	connected=1

	# Check each ZK to see if IP connected
	until [[ ${connected} -eq 0 ]]
	do
	        connected=$(echo cons | nc -w 5 ${TREADMILL_CELL}-zk-1 2181 2>/dev/null | grep -q ${hostip})
	        connected=$(echo cons | nc -w 5 ${TREADMILL_CELL}-zk-2 2181 2>/dev/null | grep -q ${hostip})
	        connected=$(echo cons | nc -w 5 ${TREADMILL_CELL}-zk-3 2181 2>/dev/null | grep -q ${hostip})
		echo Waiting for ${TREADMILL_CELL}-node-${i} to contact Zookeeper...
        	sleep 5
	done
done

echo -e "All nodes are in communication with Zookeeper.\n"

# Start management APIs
echo -e "Bootstrapping Treadmill...\n"

# Sync ldap to zk
echo "Writing server list to LDAP..."
treadmill sproc cellsync --once --no-lock >/dev/null && echo -e 'Server list synched with LDAP.\n'

# Make sure the server is up:
until [[ $(treadmill admin scheduler view servers | grep node | wc -l) -eq 3 ]]
do
	echo Waiting for nodes to register...
        sleep 5
done
echo -e "Treadmill nodes registed in scheduler. \n"

# Configure system apps and monitors:
echo "Configuring Treadmill management apps..."
treadmill admin cell --cell ${TREADMILL_CELL} configure-apps >/dev/null && echo 'Configured management APIs.'
treadmill admin cell --cell ${TREADMILL_CELL} configure-monitors >/dev/null && echo 'Configured app monitors.'
treadmill admin cell --cell ${TREADMILL_CELL} configure-appgroups >/dev/null && echo 'Configured appgroups.'
treadmill admin cell --cell ${TREADMILL_CELL} restart-apps --wait 0 >/dev/null && echo 'Apps started.'

# Run the scheduler:
treadmill sproc --cell ${TREADMILL_CELL} scheduler --once >/dev/null && echo 'Apps scheduled'

echo -e '\nCell online, apps starting.'
