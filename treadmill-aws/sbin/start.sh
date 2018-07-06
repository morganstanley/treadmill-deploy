#!/bin/sh

source ${0%/*}/opts.sh

exec ${0%.*}_${TREADMILL_ISA}.sh $*
