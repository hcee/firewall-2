# Comp 8006 firewall Assignment 2
standalone firewall

First, you must set up the firewall server and the internal host server.

To do this run the following commands on the respective machines:

------------------
### Firewall Configuration

Download the `fw-network.sh` script onto the firewall machine.

Run the `fw-network.sh` script by the command below from the directory which contains the Firewall Set Up Configurations.
This script will set up all the firewall ifconfig routes and IPs

```
$ ./fw-network.sh
```

Download the `firewall.sh` script onto the firewall machine

Run the `firewall.sh` script by the command below from the directory which contains the Firewall Script.
This script will set up all the firewall rules

```
$ ./firewall.sh
```
----------------------
### Internal host configuration

Download the `client-network.sh` script onto the firewall machine

Run the `client-network.sh` script by the command below from the directory which contains the Internal host Set Up Configurations.

This script will set up all the Internal host ifconfig routes and IPs

```
$ ./client-network.sh
```

**Please check your /etc/resolv.conf files on both the firewall and internal host to make sure they are the same**

Download the `fw-test.sh` script on the testing machine

From the testing machine, run the command below from the diroectory which contains the test Script.

This script will run a series of testing commands against the firewall and output the results to a text file called c8006-assignment2-testresults-hazel.txt

```
$ ./fw-test.sh
```
