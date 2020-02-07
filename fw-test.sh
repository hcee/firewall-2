#!/bin/bash

#user configurable section
ALLOW_TCP=("80" "22" "443" "21" "20")
ALLOW_UDP=("53" "67" "68")
ALLOW_ICMP="0,8"
EXTERNAL_IP="192.168.0.10" #####External IP of the Firewall#####
FILE_NAME="c8006-assignment2-testresults-hazel.txt"

if [[ -f "$FILE_NAME" ]]; then
    echo "$FILE_NAME exists and will be recreated"
    rm $FILE_NAME
    touch $FILE_NAME
else
    echo "New Test file is being created...."
    touch $FILE_NAME
fi


#start of test script
{
    echo "Firewall test starting..." 
    echo "=========================================================================" 
    echo "NMAP Test" 
    echo "Open Ports to be tested: ${ALLOW_TCP[*]}" 
    echo "=========================================================================" 
    echo ""
    nmap -v $EXTERNAL_IP 
    echo ""
    echo "=========================================================================" 
    echo "TCP Test" 
    echo "=========================================================================" 
    echo "" 

    for PORT in "${ALLOW_TCP[@]}"; do
	    echo "---------------------------------------------------------------------" 
	    echo "Testing: TCP packets on allowed port $PORT" 
	    echo "Expected result: 0% packet loss" 
	    echo "" 
	    hping3 $EXTERNAL_IP -c 3 -k -S -p "$PORT" 
        echo "" 
    done

    echo "=========================================================================" 
    echo "UDP Test" 
    echo "Open Ports to be tested: ${ALLOW_UDP[*]}" 
    echo "=========================================================================" 
    echo "" 

    for PORT in "${ALLOW_UDP[@]}"; do
        echo "-----------------------------------------" 
        echo "Testing: UDP packets on allowed port $PORT" 
        echo "Expected result: open/filtered" 
        echo "" 
        nmap $EXTERNAL_IP -sU -p "$PORT" 
        echo "" 
    done

    echo "=========================================================================" 
    echo "ICMP Test" 
    echo "Testing: ICMP for $ALLOW_ICMP" 
    echo "=========================================================================" 
    echo "Expected result: 0% packet loss" 
    echo "" 
    ping -c 5 $EXTERNAL_IP
    echo "---------------------------------------" 
    echo -e "\n\n" 

    echo "=========================================================================" 
    echo "Fragment test" 
    echo "=========================================================================" 
    echo "Expected result: 0% packet loss" 
    echo "" 
    hping3 $EXTERNAL_IP -c 3 -f -S -p 22 
    echo "---------------------------------------" 
    echo -e "\n\n" 

    echo "=========================================================================" 
    echo "Testing: SYN packets on high ports" 
    echo "=========================================================================" 
    echo "Expected result: 100% packet loss" 
    echo "" 
    hping3 $EXTERNAL_IP -c 3 -S -p 20000 
    echo "---------------------------------------" 
    echo -e "\n\n" 

    echo "=========================================================================" 
    echo "Testing: Telnet packets should be dropped" 
    echo "=========================================================================" 
    echo "Expected result: 100% packet loss" 
    echo "" 
    hping3 $EXTERNAL_IP -c 3 -S -p 23 
    echo "---------------------------------------" 
    echo -e "\n\n" 

    echo "=========================================================================" 
    echo "Blocked ports from 32768-32775 test" 
    echo "=========================================================================" 
    echo "Expected result: 100% packet loss" 
    echo "" 
    hping3 $EXTERNAL_IP -c 8 -S -p ++32768 
    hping3 $EXTERNAL_IP -2 -c 8 -p ++32768 
    echo "---------------------------------------" 
    echo -e "\n\n" 

    echo "=========================================================================" 
    echo "Blocked ports 137-139" 
    echo "=========================================================================" 
    echo "Expected result: 100% packet loss" 
    echo "" 
    hping3 $EXTERNAL_IP -c 3 -S -p ++137 
    hping3 $EXTERNAL_IP -2 -c 3 -p ++137 
    echo "---------------------------------------" 
    echo -e "\n\n" 

    echo "=========================================================================" 
    echo "Blocked TCP port 111 and 515 test" 
    echo "=========================================================================" 
    echo "Expected result: 100% packet loss" 
    hping3 $EXTERNAL_IP -c 2 -S -p 111 
    echo "" 
    hping3 $EXTERNAL_IP -c 2 -S -p 515 
    echo "---------------------------------------" 
    echo -e "\n\n" 

    echo "=========================================================================" 
    echo "Blocking Spoof" 
    echo "=========================================================================" 
    echo "Expected result: 100% packet loss" 
    hping3 $EXTERNAL_IP -c 3 --spoof 192.168.11.2 
    echo "---------------------------------------" 
    echo -e "\n\n" 
    echo "Firewall test complete" 
} >> $FILE_NAME

clear
echo "=======================================================" 
echo "Menu"
echo "=======================================================" 
cat << 'MENU'
1...........................Cat the test file
Q...........................Quit
MENU
echo '           Press letter for choice, then Return >'
read -r ltr rest
case ${ltr} in
		1)    cat $FILE_NAME;;
		[Qq])    exit    ;;
		*)    echo; echo Unrecognized choice: "${ltr}" ;;
esac