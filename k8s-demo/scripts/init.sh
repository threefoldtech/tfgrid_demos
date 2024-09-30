#!/bin/bash

apt update && apt upgrade --yes

apt install --yes git wget

wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz && \
    tar xvfz node_exporter-1.8.2.linux-amd64.tar.gz && \
    mv node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin

echo "exec: node_exporter --web.listen-address=:9501" > /etc/zinit/exporter.yaml

zinit monitor exporter
