#!/bin/bash

sudo echo "auto lo" 				> /etc/network/interfaces
sudo echo "iface lo inet loopback" 	>> /etc/network/interfaces

sudo service network-manager restart
sudo service networking restart
sudo service NetworkManager restart
sudo service isc-dhcp-server stop
sudo service hostapd stop

