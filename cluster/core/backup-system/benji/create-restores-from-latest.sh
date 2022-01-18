#!/bin/bash -e
benji ls 'status == "valid" and date >= "$1" and date <= "$2"'  | grep $1 | awk '{print "benji-restore-pvc --pvc-storage-class=ceph-block --force "$4" "$6}' | sed 's/\//\ /g'