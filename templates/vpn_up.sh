#!/bin/sh

VPN_DEV=$1
MTU=$2

/sbin/ip addr add $VPN_IP_CIDR dev $VPN_DEV
/sbin/ip addr add $LAN_PARTIAL_IP_CIDR dev $VPN_DEV
/sbin/ip link set $VPN_DEV up promisc on mtu $2

/sbin/iptables -v -t nat -F
/sbin/iptables -v -t nat -A PREROUTING -d $LAN_PARTIAL_NET_CIDR -j NETMAP --to $VPN_NET_CIDR
/sbin/iptables -v -t nat -A PREROUTING -i $VPN_DEV -d $VPN_FULL_NET_CIDR -j NETMAP --to $LAN_NET_CIDR
/sbin/iptables -v -t nat -A POSTROUTING -o $VPN_DEV -s $LAN_NET_CIDR -j NETMAP --to $VPN_FULL_NET_CIDR
/sbin/iptables -v -t nat -A POSTROUTING -o $LAN_DEV -s $VPN_FULL_NET_CIDR -j NETMAP --to $LAN_NET_CIDR

/bin/echo 1 > /proc/sys/net/ipv4/ip_forward
/bin/echo 1 > /proc/sys/net/ipv4/conf/$VPN_DEV/proxy_arp
/bin/echo 1 > /proc/sys/net/ipv4/conf/$LAN_DEV/proxy_arp

/etc/init.d/dnsmasq restart

