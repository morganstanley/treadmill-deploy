#!/bin/sh

source ${0%/*}/opts.sh

echo Configuring Treadmill $TREADMILL_ISA: $INSTALL_DIR
env | grep TREADMILL_

exec ${0%.*}_${TREADMILL_ISA}.sh $*
