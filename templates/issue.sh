#!/bin/bash

if [ -f "vpn.config" ]; then
  source vpn.config
fi

if [ -z "$1" ]; then
  echo "Must provide client name"
  exit 1
fi

openssl genrsa -out $TEMP_DIR/newbie.key 4096
openssl req -new -key $TEMP_DIR/newbie.key -out $TEMP_DIR/newbie.csr -batch -subj /CN=$1/
openssl x509 -req -in $TEMP_DIR/newbie.csr -out $TEMP_DIR/newbie.crt -CA $CA_DIR/ca.crt -CAkey $CA_DIR/ca.key -CAcreateserial -days 9999

cat $TEMP_DIR/newbie.crt $TEMP_DIR/newbie.key > $TEMP_DIR/client.pem
cp $CA_DIR/client.ovpn $TEMP_DIR/${LAN_DOMAIN}_$1.ovpn
echo "<ca>" >> $TEMP_DIR/${LAN_DOMAIN}_$1.ovpn
cat $CA_DIR/ca.crt >> $TEMP_DIR/vimnet_$1.ovpn
echo "</ca>" >> $TEMP_DIR/${LAN_DOMAIN}_$1.ovpn
echo "" >> $TEMP_DIR/${LAN_DOMAIN}_$1.ovpn
echo "<cert>" >> $TEMP_DIR/${LAN_DOMAIN}_$1.ovpn
cat $TEMP_DIR/client.pem >> $TEMP_DIR/${LAN_DOMAIN}_$1.ovpn
echo "</cert>" >> $TEMP_DIR/${LAN_DOMAIN}_$1.ovpn
echo "" >> $TEMP_DIR/${LAN_DOMAIN}_$1.ovpn
echo "<key>" >> $TEMP_DIR/${LAN_DOMAIN}_$1.ovpn
cat $TEMP_DIR/client.pem >> $TEMP_DIR/${LAN_DOMAIN}_$1.ovpn
echo "</key>" >> $TEMP_DIR/${LAN_DOMAIN}_$1.ovpn



mv $TEMP_DIR/${LAN_DOMAIN}_$1.ovpn ${LAN_DOMAIN}_$1.ovpn

rm $TEMP_DIR/newbie.key
rm $TEMP_DIR/newbie.csr
rm $TEMP_DIR/newbie.crt
rm $TEMP_DIR/client.pem

if [ -n "$2" ]; then
  echo "ifconfig-push $2 $VPN_NETMASK" > $CA_DIR/staticclients/$1
fi

