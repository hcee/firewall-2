#!/bin/bash

#===============================user configuration==============================
DEFAULT_CHAINS=("OUTPUT" "INPUT" "FORWARD")
iHost=enp3s2
xHost=eno1
TCP_ALLOWED=("80","22","443","21","20","56","1200")
UDP_ALLOWED=53,67,68
ICMP_ALLOWED=8,0
TCP_DENY="32768:32775 137:139 11 515"
UDP_DENY="32768:32775 137:139"
internalIP=192.168.11.2
externalIPRange=192.168.0.0/24
internalIPRange=192.168.11.0/24
externalIP=192.168.0.10

# shortcut to resetting the default policy
if [ "$1" = "flush" ]; then
  iptables -F
  iptables -X
  iptables -t nat -X
  iptables -t nat -F
  iptables -P INPUT ACCEPT
  iptables -P OUTPUT ACCEPT
  iptables -P FORWARD ACCEPT
  echo -e "Firewall rules reset!"
  echo -e "-------------------------------------------\n"
  iptables -L -n
  exit 0
fi

#===========================implementation section================================

# Set the default policies to DROP
for CHAIN in "${DEFAULT_CHAINS[@]}"; do
    iptables -P "$CHAIN" DROP
    RESULT=$?
    if [ $RESULT -eq 0 ]; then
        echo "Default policy set to DROP for $CHAIN"
    else
        echo "Failed to set default policy to drop"
    fi   
done

# User-defined chains
iptables -N denied_packets
iptables -N bad_tcp_packets
iptables -N tcpout
iptables -N tcpin
iptables -N udpout
iptables -N icmpout

# Possible stealth scans
iptables -A bad_tcp_packets -p tcp ! --syn -m state --state NEW -j DROP
iptables -A bad_tcp_packets -p tcp --tcp-flags ALL NONE -j DROP
iptables -A bad_tcp_packets -p tcp --tcp-flags ALL ALL -j DROP
iptables -A bad_tcp_packets -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
iptables -A bad_tcp_packets -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
iptables -A bad_tcp_packets -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
iptables -A bad_tcp_packets -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP

#------ Accept Rules-------

for PORT in "${TCP_ALLOWED[@]}"; do
    iptables -A FORWARD -p tcp --sport $PORT -m state --state NEW,ESTABLISHED -j ACCEPT
    iptables -A FORWARD -p tcp --dport $PORT -m state --state NEW,ESTABLISHED -j ACCEPT
done

# Do not accept any packets with a source address from the outside matching your internal network
iptables -A denied_packets -i $xHost -o $iHost -s 192.168.11.0/24 -j DROP