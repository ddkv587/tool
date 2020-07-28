#!/bin/bash 

if [ $# -lt 1 ]; then
	echo "USAGE: sudo ./enable_hotspot.sh [wifi interface] [forward interface]"
	exit 1
fi

echo "=========== install dependence =========="
sudo apt update && sudo apt install -y isc-dhcp-server hostapd

echo "=========== update /etc/network/interfaces =========="
sudo mv /etc/network/interfaces /etc/network/interfaces_bak
sudo echo "auto lo" 					> /etc/network/interfaces
sudo echo "iface lo inet loopback" 		>> /etc/network/interfaces
sudo echo " " 							>> /etc/network/interfaces
sudo echo "auto $1" 					>> /etc/network/interfaces
sudo echo "iface $1 inet static" 		>> /etc/network/interfaces
sudo echo "address 10.10.0.1" 			>> /etc/network/interfaces
sudo echo "netmask 255.255.255.0" 		>> /etc/network/interfaces

echo "=========== restart NetworkManager =========="
sudo service network-manager restart
sudo service networking restart
sudo service NetworkManager restart

echo "=========== start hostapd =========="
sudo service isc-dhcp-server restart
sudo service hostapd restart

if [ $# -eq 2 ]; then
	echo "=========== enable forward $2 =========="
	echo 1| sudo tee /proc/sys/net/ipv4/ip_forward
	sudo iptables -t nat -A POSTROUTING -s 10.10.0.0/16 -o $2 -j MASQUERADE
fi
