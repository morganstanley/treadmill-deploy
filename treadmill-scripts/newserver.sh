#!/bin/bash

#########################
# The command line help #
#########################
display_help() {
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   -s, --subnet           AWS subnet ID; e.g. subnet-1234"
    echo "   -a, --ami              AWS AMI image; e.g. ami-1234"
    echo "   -c, --cell             Treadmill cell name; e.g. userdev"
    echo "   -t, --type             EC2 Instance Type; e.g. t2.large"
    echo "   -n, --number           Number of instances; e.g. 5"
    echo
    exit 0
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -s|--subnet)
    SUBNET="$2"
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
    -t|--type)
    TYPE="$2"
    shift # past argument
    shift # past value
    ;;
    -n|--number)
    NUMBER="$2"
    shift # past argument
    shift # past value
    ;;
    -h|--help)
    display_help
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

echo "AWS SUBNET        = ${SUBNET}"
echo "AWS AMI           = ${AMI}"
echo "TREADMILL CELL    = ${TREADMILL_CELL}"
echo "EC2 TYPE          = ${TYPE}"
echo "NUMBER            = ${NUMBER}"

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


for i in $(seq 1 ${NUMBER})
do
	hostname=`treadmill admin aws instance create \
                 --image ${AMI} \
                 --subnet ${SUBNET} \
                 --size ${TYPE} \
                 --role node`
	echo ${hostname}

	treadmill admin ldap server configure ${hostname} --cell ${TREADMILL_CELL} > /dev/null
        RESULT=$?
        if [ ${RESULT} -eq 0 ]; then
		echo "LDAP Updated" 
	else
		echo "LDAP Failed; deleting server"
		./delserver.sh ${hostname} >/dev/null
        fi

done
