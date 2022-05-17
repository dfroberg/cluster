#!/bin/bash
set +e
line="0 */2 * * * /home/dfroberg/postgres_dumpall.sh"
(crontab -u $(whoami) -l; echo "$line" ) | crontab -u $(whoami) -
crontab -u $(whoami) -l