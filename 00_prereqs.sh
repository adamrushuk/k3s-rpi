#!/bin/sh

# https://kauri.io/install-raspbian-operating-system-and-prepare-the-system-for-kubernetes/7df2a9f9cf5f4f6eb217aa7223c01594/a

# aliases
sudo cat <<EOT >> ~/.bash_aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
EOT

# reload .bashrc
source ~/.bashrc

# disable Swap
sudo dphys-swapfile swapoff
sudo dphys-swapfile uninstall
sudo update-rc.d dphys-swapfile remove
echo Adding " cgroup_enable=cpuset cgroup_enable=memory" to /boot/cmdline.txt
sudo cp /boot/cmdline.txt /boot/cmdline_backup.txt
orig="$(head -n1 /boot/cmdline.txt) cgroup_enable=cpuset cgroup_enable=memory"
echo $orig | sudo tee /boot/cmdline.txt

# utils
sudo apt-get update -q
sudo apt-get install -qy tree

# firewall
# Without this step, you may find coredns pods fail to start on app nodes and/or DNS does not work.
sudo iptables -P FORWARD ACCEPT
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

# update windows hosts file for local computer, as wsl overwrites /etc/hosts from this:
# C:\Windows\System32\drivers\etc\hosts
# sudo nano /etc/hosts
192.168.1.10    pi0
192.168.1.11    pi1
192.168.1.12    pi2
192.168.1.13    pi3

# ssh
# copy keys to pi's
ssh-copy-id pi@pi0
ssh-copy-id pi@pi1
ssh-copy-id pi@pi2
ssh-copy-id pi@pi3

# set hostnames and static ips on each node
# master node
sh ./scripts/hostname_and_ip.sh pi0 192.168.1.10 192.168.1.1

# worker nodes
sh ./scripts/hostname_and_ip.sh pi1 192.168.1.11 192.168.1.1
sh ./scripts/hostname_and_ip.sh pi2 192.168.1.12 192.168.1.1
sh ./scripts/hostname_and_ip.sh pi3 192.168.1.13 192.168.1.1
