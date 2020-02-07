#=======================User configurable section======================

# Change the ports and network configurations as necessary

TCP_ALLOWED="53,67,68,80,443,22,20,21"               
UDP_ALLOWED="53,67,68"                              
ALLOWED_ICMP=("echo-request" "echo-reply")

TCP_DROP="32768:32775,137:139,111,515"
UDP_DROP="32768:32775,137:139"

FW_IP="192.168.0.21"
FW_INT="eno1"

CLNT_IP="192.168.11.1"
CLNT_NET="192.168.11.0/24"
CLNT_INT="enp2s0"

IPT=/usr/sbin/iptables

#===================Implementation section DO NOT TOUCH=================

# Flush the Tables and clean up
$IPT -F
$IPT -X
$IPT -t mangle -F
$IPT -t nat -F
$IPT -t filter -F

# Set default policies
$IPT -P INPUT DROP
$IPT -P OUTPUT DROP
$IPT -P FORWARD DROP

# User-Defined Chains
$IPT -N tcp-traffic
$IPT -A tcp-traffic
$IPT -N tcp_in
$IPT -N tcp_out
$IPT -A tcp_in
$IPT -A tcp_out

$IPT -N udp-traffic
$IPT -A udp-traffic
$IPT -N udp_in
$IPT -N udp_out
$IPT -A udp_in
$IPT -A udp_out

# User-Defined chains for accounting
$IPT -A INPUT -i $FW_INT -p tcp -j tcp-traffic
$IPT -A OUTPUT -o $FW_INT -p tcp -j tcp-traffic
$IPT -A INPUT -i $CLNT_INT -p tcp -j tcp-traffic
$IPT -A OUTPUT -o $CLNT_INT -p tcp -j tcp-traffic

$IPT -A INPUT -i $FW_INT -p udp -j udp-traffic
$IPT -A OUTPUT -o $FW_INT -p udp -j udp-traffic
$IPT -A INPUT -i $CLNT_INT -p udp -j udp-traffic
$IPT -A OUTPUT -o $CLNT_INT -p udp -j udp-traffic

$IPT -A tcp-traffic -i $FW_INT -p tcp -j tcp_in
$IPT -A tcp-traffic -o $FW_INT -p tcp -j tcp_out
$IPT -A tcp-traffic -i $CLNT_INT -p tcp -j tcp_in
$IPT -A tcp-traffic -o $CLNT_INT -p tcp -j tcp_out

$IPT -A udp-traffic -i $FW_INT -p udp -j udp_in
$IPT -A udp-traffic -o $FW_INT -p udp -j udp_out
$IPT -A udp-traffic -i $CLNT_INT -p udp -j udp_in
$IPT -A udp-traffic -o $CLNT_INT -p udp -j udp_out

# Drop traffic destined for the firewall
$IPT -A tcp_in -i $FW_INT -p tcp -m multiport ! --dports $TCP_ALLOWED -j DROP
$IPT -A udp_in -i $FW_INT -p udp -m multiport ! --dports $UDP_ALLOWED -j DROP

# Drop packets with source IP that match our internal network
$IPT -A tcp_in -i $FW_INT -s $CLNT_NET -p tcp -j DROP
$IPT -A udp_in -i $FW_INT -s $CLNT_NET -p udp -j DROP

# Drop all inbound SYN packets unless permitted && drop all TCP packets with flags SYN and FIN
$IPT -A tcp_in -i $FW_INT -p tcp ! --syn -m state --state NEW -j DROP
$IPT -A tcp_in -i $FW_INT -p tcp --tcp-flags ALL ACK,RST,SYN,FIN -m state --state NEW -j DROP
$IPT -A tcp_in -i $FW_INT -p tcp --tcp-flags SYN,FIN SYN,FIN -m state --state NEW -j DROP
$IPT -A tcp_in -i $FW_INT -p tcp --tcp-flags SYN,RST SYN,RST -m state --state NEW -j DROP

$IPT -A tcp_out -o $FW_INT -p tcp ! --syn -m state --state NEW -j DROP
$IPT -A tcp_out -o $FW_INT -p tcp --tcp-flags ALL ACK,RST,SYN,FIN -m state --state NEW -j DROP
$IPT -A tcp_out -o $FW_INT -p tcp --tcp-flags SYN,FIN SYN,FIN -m state --state NEW -j DROP
$IPT -A tcp_out -o $FW_INT -p tcp --tcp-flags SYN,RST SYN,RST -m state --state NEW -j DROP

# Drop all Telnet packets
$IPT -A tcp_in -i $FW_INT -p tcp --dport 23 -j DROP
$IPT -A tcp_out -i $FW_INT -p tcp --sport 23 -j DROP
$IPT -A tcp_in -i $CLNT_INT -p tcp --dport 23 -j DROP
$IPT -A tcp_out -i $CLNT_INT -p tcp --sport 23 -j DROP

# Drop all external traffic directed to ports: 32768-32775, 137-139, and TCP ports 111 and 515
$IPT -A tcp_in -i $FW_INT -p tcp -m multiport --dport $TCP_DROP -j DROP
$IPT -A udp_in -i $FW_INT -p udp -m multiport --dport $UDP_DROP -j DROP

# Accept incoming fragments
$IPT -A tcp_in -i $FW_INT -f -m state --state ESTABLISHED -j ACCEPT
$IPT -A tcp_in -i $CLNT_INT -f -m state --state ESTABLISHED -j ACCEPT
$IPT -A udp_in -i $FW_INT -f -m state --state ESTABLISHED -j ACCEPT
$IPT -A udp_in -i $CLNT_INT -f -m state --state ESTABLISHED -j ACCEPT

# Set control connection for FTP and SSH to "Minimum Delay"
# Set control connection for FTP to "Maximum Throughput"
$IPT -A PREROUTING -t mangle -p tcp --sport ssh -j TOS --set-tos Minimize-Delay
$IPT -A PREROUTING -t mangle -p tcp --sport ftp -j TOS --set-tos Minimize-Delay
$IPT -A PREROUTING -t mangle -p tcp --sport ftp-data -j TOS --set-tos Maximize-Throughput

# Inbound / Outbound permitted on these ports (TCP)
$IPT -A tcp_in -i $FW_INT -p tcp -m multiport --sport $TCP_ALLOWED -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A tcp_out -o $FW_INT -p tcp -m multiport --sport $TCP_ALLOWED -m state --state ESTABLISHED -j ACCEPT
$IPT -A tcp_in -i $FW_INT -p tcp -m multiport --dport $TCP_ALLOWED -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A tcp_out -o $FW_INT -p tcp -m multiport --dport $TCP_ALLOWED -m state --state ESTABLISHED -j ACCEPT

$IPT -A tcp_in -i $CLNT_INT -p tcp -m multiport --sport $TCP_ALLOWED -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A tcp_out -o $CLNT_INT -p tcp -m multiport --sport $TCP_ALLOWED -m state --state ESTABLISHED -j ACCEPT
$IPT -A tcp_in -i $CLNT_INT -p tcp -m multiport --dport $TCP_ALLOWED -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A tcp_out -o $CLNT_INT -p tcp -m multiport --dport $TCP_ALLOWED -m state --state ESTABLISHED -j ACCEPT

# Inbound / Outbound permitted on these ports (UDP)
$IPT -A udp_in -i $FW_INT -p udp -m multiport --sport $UDP_ALLOWED -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A udp_out -o $FW_INT -p udp -m multiport --sport $UDP_ALLOWED -m state --state ESTABLISHED -j ACCEPT
$IPT -A udp_in -i $FW_INT -p udp -m multiport --dport $UDP_ALLOWED -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A udp_out -o $FW_INT -p udp -m multiport --dport $UDP_ALLOWED -m state --state ESTABLISHED -j ACCEPT

$IPT -A udp_in -i $CLNT_INT -p udp -m multiport --sport $UDP_ALLOWED -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A udp_out -o $CLNT_INT -p udp -m multiport --sport $UDP_ALLOWED -m state --state ESTABLISHED -j ACCEPT
$IPT -A udp_in -i $CLNT_INT -p udp -m multiport --dport $UDP_ALLOWED -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A udp_out -o $CLNT_INT -p udp -m multiport --dport $UDP_ALLOWED -m state --state ESTABLISHED -j ACCEPT

# Inbound / Outbound permitted on these type numbers (ICMP)
for TYPE in "${ALLOWED_ICMP[@]}"; do
	$IPT -A INPUT -i $FW_INT -p icmp -m icmp --icmp-type $TYPE -m state --state NEW,ESTABLISHED -j ACCEPT
	$IPT -A INPUT -i $CLNT_INT -p icmp -m icmp --icmp-type $TYPE -m state --state NEW,ESTABLISHED -j ACCEPT
	$IPT -A OUTPUT -o $FW_INT -p icmp -m icmp --icmp-type $TYPE -m state --state ESTABLISHED -j ACCEPT
	$IPT -A OUTPUT -o $CLNT_INT -p icmp -m icmp --icmp-type $TYPE -m state --state ESTABLISHED -j ACCEPT
done

# IP Forwarding
$IPT -t nat -A POSTROUTING -o $FW_INT -j SNAT --to $FW_IP
$IPT -t nat -A PREROUTING -i $FW_INT -p tcp -m multiport --dports $TCP_ALLOWED -j DNAT --to-destination $CLNT_IP
$IPT -t nat -A PREROUTING -i $FW_INT -p udp -m multiport --dports $UDP_ALLOWED -j DNAT --to-destination $CLNT_IP
$IPT -A FORWARD -i $FW_INT -o $CLNT_INT -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A FORWARD -i $CLNT_INT -o $FW_INT -m state --state NEW,ESTABLISHED -j ACCEPT

$IPT -L -n -v -x
