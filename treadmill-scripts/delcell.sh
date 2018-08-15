#!/bin/bash

#########################
# The command line help #
#########################
display_help() {
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   -c, --cell             Treadmill cell name; e.g. userdev"
    echo
    exit 0
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -c|--cell)
    TREADMILL_CELL="$2"
    shift # past argument
    shift # past value
    ;;
    -h|--help)
    display_help
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

echo "TREADMILL CELL    = ${TREADMILL_CELL}"

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

treadmill admin ldap cell delete ${TREADMILL_CELL}
${0%/*}/delserver.sh ${TREADMILL_CELL}-zk-{1..3} 
${0%/*}/delserver.sh ${TREADMILL_CELL}-node-{1..3}

