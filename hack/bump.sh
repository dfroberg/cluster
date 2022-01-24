#!/usr/bin/bash
# Bump reconciliation of a helmrelease
flux suspend helmrelease $2 -n $1
flux resume helmrelease $2 -n $1