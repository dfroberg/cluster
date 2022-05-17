#!/bin/bash
# This script restores everything from the latest backup made.
sudo -i -u postgres psql -U postgres -f $(find /mnt/backups/ -size +100k -name "*.sql" -type f -exec stat -c "%y %n" {} + | sort -r | head -n1 | cut -d " " -f 4-)
# Nuke kine from the restored dump
sudo -i -u postgres psql cluster -c "TRUNCATE kine;" && true