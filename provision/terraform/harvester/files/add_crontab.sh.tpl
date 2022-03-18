#!/bin/bash
set +e
line="*/5 * * * * /home/dfroberg/postgres_dumpall.sh"
(crontab -u $(whoami) -l; echo "$line" ) | crontab -u $(whoami) -
crontab -u $(whoami) -l