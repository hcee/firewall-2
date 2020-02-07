#!/bin/bash

#user configurable section
ALLOW_TCP="80,22,443,21,20"
ALLOW_UDP="53,67,68"
ALLOW_ICMP="0,8"
EXTERNAL_IP="192.168.0.10" #####External IP of the Firewall#####
FILE_NAME="c8006-assignment2-testresults-hazel.txt"

clear
#remove any pre-existing file with the same name
removeFile=`rm $FILE_NAME`
echo $removeFile "New Test file is being created...."

#create an firewall test output file
touch $FILE_NAME

#start of test script
echo "Firewall test starting..." >> $FILE_NAME
echo "=========================================================================" >> $FILE_NAME
echo "NMAP Test" >> $FILE_NAME
echo "Open Ports to be tested: $ALLOW_TCP" >> $FILE_NAME
echo "=========================================================================" >> $FILE_NAME
echo ""
nmap -v $EXTERNAL_IP >> $FILE_NAME
echo ""
echo "=========================================================================" >> $FILE_NAME
echo "TCP Test" >> $FILE_NAME
echo "=========================================================================" >> $FILE_NAME
echo "" >> $FILE_NAME

array=$(echo $ALLOW_TCP | tr "," "\n")
for port in $array
do	
	echo "---------------------------------------------------------------------" >> $FILE_NAME
	echo "Testing: TCP packets on allowed port $port" >> $FILE_NAME
	echo "Expected result: 0% packet loss" >> $FILE_NAME
	echo "" >> $FILE_NAME
	hping3 $EXTERNAL_IP -c 3 -k -S -p $port >> $FILE_NAME
    echo "" >> $FILE_NAME
done

echo "=========================================================================" >> $FILE_NAME
echo "UDP Test" >> $FILE_NAME
echo "Open Ports to be tested: $ALLOW_UDP" >> $FILE_NAME
echo "=========================================================================" >> $FILE_NAME
echo "" >> $FILE_NAME

array=$(echo $ALLOW_UDP | tr "," "\n")
for port in $array
do
	echo "-----------------------------------------" >> $FILE_NAME
	echo "Testing: UDP packets on allowed port $port" >> $FILE_NAME
	echo "Expected result: open/filtered" >> $FILE_NAME
	echo "" >> $FILE_NAME
	nmap $EXTERNAL_IP -sU -p $port >> $FILE_NAME
	echo "" >> $FILE_NAME
done

echo "=========================================================================" >> $FILE_NAME
echo "ICMP Test" >> $FILE_NAME
echo "Testing: ICMP for echo request and reply" >> $FILE_NAME
echo "=========================================================================" >> $FILE_NAME
echo "Expected result: 0% packet loss" >> $FILE_NAME
echo "" >> $FILE_NAME
ping -c 5 $EXTERNAL_IP>> $FILE_NAME
echo "---------------------------------------" >> $FILE_NAME
echo -e "\n\n" >> $FILE_NAME

echo "=========================================================================" >> $FILE_NAME
echo "Fragment test" >> $FILE_NAME
echo "=========================================================================" >> $FILE_NAME
echo "Expected result: 0% packet loss" >> $FILE_NAME
echo "" >> $FILE_NAME
hping3 $EXTERNAL_IP -c 3 -f -S -p 22 >> $FILE_NAME
echo "---------------------------------------" >> $FILE_NAME
echo -e "\n\n" >> $FILE_NAME

echo "=========================================================================" >> $FILE_NAME
echo "Testing: SYN packets on high ports" >> $FILE_NAME
echo "=========================================================================" >> $FILE_NAME
echo "Expected result: 100% packet loss" >> $FILE_NAME
echo "" >> $FILE_NAME
hping3 $EXTERNAL_IP -c 3 -S -p 20000 >> $FILE_NAME
echo "---------------------------------------" >> $FILE_NAME
echo -e "\n\n" >> $FILE_NAME

echo "=========================================================================" >> $FILE_NAME
echo "Testing: Telnet packets should be dropped" >> $FILE_NAME
echo "=========================================================================" >> $FILE_NAME
echo "Expected result: 100% packet loss" >> $FILE_NAME
echo "" >> $FILE_NAME
hping3 $EXTERNAL_IP -c 3 -S -p 23 >> $FILE_NAME
echo "---------------------------------------" >> $FILE_NAME
echo -e "\n\n" >> $FILE_NAME

echo "=========================================================================" >> $FILE_NAME
echo "Blocked ports from 32768-32775 test" >> $FILE_NAME
echo "=========================================================================" >> $FILE_NAME
echo "Expected result: 100% packet loss" >> $FILE_NAME
echo "" >> $FILE_NAME
hping3 $EXTERNAL_IP -c 8 -S -p ++32768 >> $FILE_NAME
hping3 $EXTERNAL_IP -2 -c 8 -p ++32768 >> $FILE_NAME
echo "---------------------------------------" >> $FILE_NAME
echo -e "\n\n" >> $FILE_NAME

echo "=========================================================================" >> $FILE_NAME
echo "Blocked ports 137-139" >> $FILE_NAME
echo "=========================================================================" >> $FILE_NAME
echo "Expected result: 100% packet loss" >> $FILE_NAME
echo "" >> $FILE_NAME
hping3 $EXTERNAL_IP -c 3 -S -p ++137 >> $FILE_NAME
hping3 $EXTERNAL_IP -2 -c 3 -p ++137 >> $FILE_NAME
echo "---------------------------------------" >> $FILE_NAME
echo -e "\n\n" >> $FILE_NAME

echo "=========================================================================" >> $FILE_NAME
echo "Blocked TCP port 111 and 515 test" >> $FILE_NAME
echo "=========================================================================" >> $FILE_NAME
echo "Expected result: 100% packet loss" >> $FILE_NAME
hping3 $EXTERNAL_IP -c 2 -S -p 111 >> $FILE_NAME
echo "" >> $FILE_NAME
hping3 $EXTERNAL_IP -c 2 -S -p 515 >> $FILE_NAME
echo "---------------------------------------" >> $FILE_NAME
echo -e "\n\n" >> $FILE_NAME

echo "=========================================================================" >> $FILE_NAME
echo "Blocking Spoof" >> $FILE_NAME
echo "=========================================================================" >> $FILE_NAME
echo "Expected result: 100% packet loss" >> $FILE_NAME
hping3 $EXTERNAL_IP -c 3 --spoof 192.168.11.2 >> $FILE_NAME
echo "---------------------------------------" >> $FILE_NAME
echo -e "\n\n" >> $FILE_NAME
echo "Firewall test complete" >> $FILE_NAME

clear
echo "=======================================================" >> $FILE_NAME
echo "Menu"
echo "=======================================================" >> $FILE_NAME
cat << 'MENU'
1...........................Cat the test file
Q...........................Quit
MENU
echo '           Press letter for choice, then Return >'
read ltr rest
case ${ltr} in
		1)    cat $FILE_NAME;;
		[Qq])    exit    ;;
		*)    echo; echo Unrecognized choice: ${ltr} ;;
esac