#!/bin/bash

t1=$1
t2=$2
dt=$(echo "$t2 - $t1" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)

printf "Runtime: %d:%02d:%02d:%02.1f\n" $dd $dh $dm $ds

exit 0

