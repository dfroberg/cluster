#!/bin/bash -e
NAMESPACE=$1
HEALTHCHECKID=$2
if [[ "$NAMESPACE" != "" ]]
then
    if [[ "$HEALTHCHECKID" != "" ]]
    then
        benji-backup-pvc -n $1 && wget https://healthchecks.k8s.aml.ink/ping/$2 -q -T 10 -t 5 -O /dev/null
    else
        benji-backup-pvc -n $1
    fi
else
    echo "ERROR no namespace"
    exit 1
fi