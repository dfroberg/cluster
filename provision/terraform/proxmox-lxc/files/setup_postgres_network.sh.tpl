#!/bin/bash
export PATH=$PATH:/usr/bin
sudo sed -i 's/host    all             all             127.0.0.1\/32            scram-sha-256/host    all             all             127.0.0.1\/32            scram-sha-256\nhost    all             all             192.168.0.0\/16          trust/' /etc/postgresql/${version}/main/pg_hba.conf
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'        /" /etc/postgresql/${version}/main/postgresql.conf
sudo sed -i "s/max_connections = 100/max_connections = 500/" /etc/postgresql/${version}/main/postgresql.conf
sudo sed -i "s/shared_buffers = 128MB/shared_buffers = 512MB/" /etc/postgresql/${version}/main/postgresql.conf
sudo sed -i "s/#temp_buffers = 8MB/temp_buffers = 128MB/" /etc/postgresql/${version}/main/postgresql.conf
