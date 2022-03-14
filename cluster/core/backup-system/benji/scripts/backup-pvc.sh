#!/bin/bash -e
NAMESPACE="$1"
HEALTHCHECKID="$2"
if [[ "$NAMESPACE" != "" ]]
then
    if [[ "$HEALTHCHECKID" != "" ]]
    then
        echo "Backing up $NAMESPACE and pinging $HEALTHCHECKID"
        benji-backup-pvc --namespace $NAMESPACE && curl -s https://healthchecks.k8s.aml.ink/ping/$HEALTHCHECKID --connect-timeout 5 --max-time 10 -o /dev/null
    else
        echo "Backing up $NAMESPACE without ping"
        benji-backup-pvc --namespace $NAMESPACE
    fi
else
    echo "ERROR no namespace"
    exit 1
fi
