#!/bin/bash
export PATH=$PATH:/usr/bin
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
BUSY="0"
while [ true ]
do
    ps -C apt,apt-get,dpkg >/dev/null && BUSY="1" || BUSY="0"
    if [ "$BUSY" == "0" ]; then 
        sudo apt-get update
        sudo apt-get -y install postgresql-${version} postgresql-client-${version}
        break;
    fi
    echo "Waiting for APT to be available"
    sleep 5
done
