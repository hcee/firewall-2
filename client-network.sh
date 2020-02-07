#!/bin/bash

#Internal Client Config
xHost="eno1"
iHost="enp3s2"
internalIP="192.168.11.2"
gateway="192.168.11.1"

ifconfig $xHost down
ifconfig $iHost $internalIP up
route add default gw $gateway