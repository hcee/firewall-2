#!/bin/bash

# Firewall Network Config
iHost="enp2s0"
externalIP="192.168.11.1"
firewallIP="192.168.0.10"


ifconfig $iHost $externalIP up
echo "1" >/proc/sys/net/ipv4/ip_forward
route add -net 192.168.0.0 netmask 255.255.255.0 gw $firewallIP
route add -net 192.168.11.0/24 gw $externalIP