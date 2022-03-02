#!/bin/bash
sudo -i -u postgres pg_dumpall -U postgres | sudo tee /mnt/backups/postgres_all-$(date +"%m-%d-%Y-%H-%M").sql > /dev/null