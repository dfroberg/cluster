#!/bin/bash -e
benji-backup-pvc -n $1 && wget https://healthchecks.k8s.aml.ink/ping/$2 -q -T 10 -t 5 -O /dev/null