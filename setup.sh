#!/bin/bash

if [ -f "vpn.config" ]; then
  source vpn.config
fi


export TEMP_DIR=/var/tmp
export CA_DIR=`dirname $(readlink -f $0)`
export VPN_DEV=tap0


IFS=. read -r li1 li2 li3 li4 <<< "$LAN_IP"
IFS=. read -r lm1 lm2 lm3 lm4 <<< "$LAN_NETMASK"
export LAN_NET=`printf "%d.%d.%d.%d\n" "$((li1 & lm1))" "$((li2 & lm2))" "$((li3 & lm3))" "$((li4 & lm4))"`
LAN_BITS=`echo "obase=2;$(((lm1 << 24) + (lm2 << 16) + (lm3 << 8) + (lm4)))" | bc`
export LAN_NET_CIDR=$LAN_NET/`echo -n ${LAN_BITS%%0*0} | wc -m`
export LAN_IP_CIDR=$LAN_IP/`echo -n ${LAN_BITS%%0*0} | wc -m`

IFS=. read -r vi1 vi2 vi3 vi4 <<< "$VPN_IP"
IFS=. read -r vm1 vm2 vm3 vm4 <<< "$VPN_NETMASK"
export VPN_NET=`printf "%d.%d.%d.%d\n" "$((vi1 & vm1))" "$((vi2 & vm2))" "$((vi3 & vm3))" "$((vi4 & vm4))"`
VPN_BITS=`echo "obase=2;$(((vm1 << 24) + (vm2 << 16) + (vm3 << 8) + (vm4)))" | bc`
export VPN_NET_CIDR=$VPN_NET/`echo -n ${VPN_BITS%%0*0} | wc -m`
export VPN_IP_CIDR=$VPN_IP/`echo -n ${VPN_BITS%%0*0} | wc -m`

export VPN_FULL_NET=`printf "%d.%d.%d.%d\n" "$((vi1 & lm1))" "$((vi2 & lm2))" "$((vi3 & lm3))" "$((vi4 & lm4))"`
export VPN_FULL_NET_CIDR=$VPN_FULL_NET/`echo -n ${LAN_BITS%%0*0} | wc -m`

export LAN_PARTIAL_NET=`printf "%d.%d.%d.%d\n" "$((li1 & vm1))" "$((li2 & vm2))" "$((li3 & vm3))" "$((li4 & vm4))"`
export LAN_PARTIAL_NET_CIDR=$LAN_PARTIAL_NET/`echo -n ${VPN_BITS%%0*0} | wc -m`
export LAN_PARTIAL_IP_CIDR=$LAN_IP/`echo -n ${VPN_BITS%%0*0} | wc -m`


if [ ! -f "$CA_DIR/ca.key" ]; then
  openssl genrsa -out $CA_DIR/ca.key 4096
  openssl req -new -x509 -subj /CN=openvpn/ -days 9999 -key $CA_DIR/ca.key -out $CA_DIR/ca.crt 
fi

if [ ! -f "$CA_DIR/server.key" ]; then
  openssl genrsa -out $CA_DIR/server.key 4096
  openssl req -new -key $CA_DIR/server.key -out $CA_DIR/server.csr -batch -subj /CN=gateway/
  openssl x509 -req -in $CA_DIR/server.csr -out $CA_DIR/server.crt -CA $CA_DIR/ca.crt -CAkey $CA_DIR/ca.key -CAcreateserial -days 9999
  rm $CA_DIR/server.csr
fi

if [ ! -f "$CA_DIR/dh2048.pem" ]; then
  openssl dhparam -out $CA_DIR/dh2048.pem 2048
fi

if [ ! -f "$CA_DIR/ta.key" ]; then
  openvpn --genkey --secret $CA_DIR/ta.key
fi

cat $CA_DIR/templates/server.conf | envsubst > $CA_DIR/server.conf
cat $CA_DIR/templates/vpn_up.sh | envsubst > $CA_DIR/vpn_up.sh
chmod a+x $CA_DIR/vpn_up.sh
cat $CA_DIR/templates/vpn_down.sh | envsubst > $CA_DIR/vpn_down.sh
chmod a+x $CA_DIR/vpn_down.sh
cat $CA_DIR/templates/vpn.dns | envsubst > $CA_DIR/vpn.dns
cat $CA_DIR/templates/client.ovpn | envsubst > $CA_DIR/client.ovpn
cat $CA_DIR/templates/issue.sh | envsubst > $CA_DIR/issue.sh
chmod a+x $CA_DIR/issue.sh


env | grep VPN_
env | grep LAN_

sudo ln -sf $CA_DIR/server.conf /etc/openvpn/server.conf
sudo ln -sf $CA_DIR/server.key /etc/openvpn/server.key
sudo ln -sf $CA_DIR/server.crt /etc/openvpn/server.crt
sudo ln -sf $CA_DIR/ca.crt /etc/openvpn/ca.crt
sudo ln -sf $CA_DIR/dh2048.pem /etc/openvpn/dh2048.pem
sudo ln -sf $CA_DIR/ta.key /etc/openvpn/ta.key
sudo ln -sf $CA_DIR/vpn_up.sh /etc/openvpn/vpn_up.sh
sudo ln -sf $CA_DIR/vpn_down.sh /etc/openvpn/vpn_down.sh
sudo ln -sfn $CA_DIR/staticclients /etc/openvpn/staticclients
sudo ln -sf $CA_DIR/vpn.dns /etc/dnsmasq.d/vpn.dns
sudo ln -sfn $CA_DIR/openvpn@server.service.d /etc/systemd/system/openvpn@server.service.d

