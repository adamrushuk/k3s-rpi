#!/bin/sh

# Worker node
sudo /usr/local/bin/k3s-agent-uninstall.sh
sudo rm -rf /var/lib/rancher

# Master node
sudo /usr/local/bin/k3s-uninstall.sh
sudo rm -rf /var/lib/rancher
