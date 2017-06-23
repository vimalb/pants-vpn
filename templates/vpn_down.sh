#!/bin/sh

VPN_DEV=$1

/bin/echo 0 > /proc/sys/net/ipv4/ip_forward
/bin/echo 0 > /proc/sys/net/ipv4/conf/$LAN_DEV/proxy_arp
