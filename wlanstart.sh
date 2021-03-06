#!/bin/bash

echo "Starting Access Point container..."

# Check if running in privileged mode
#if [ $(id -u) -ne 0 ] ; then
if [ ! -w "/sys" ] ; then
    echo "[Error] Not running in privileged mode."
    exit 1
fi

# Check environment variables
if [ ! "${INTERFACE}" ] ; then
    echo "[Error] An interface must be specified."
    exit 1
fi

# Default values
true ${SUBNET:=192.168.254.0}
true ${AP_ADDR:=192.168.254.1}
true ${SSID:=raspberry}
true ${CHANNEL:=6}
true ${WPA_PASSPHRASE:=passw0riedd}
true ${HW_MODE:=g}
true ${DRIVER:=nl80211}
#true ${HT_CAPAB:=[HT40-][SHORT-GI-20][SHORT-GI-40]}
true ${HT_CAPAB:=[HT40][SHORT-GI-20][DSSS_CCK-40]}


if [ ! -f "/etc/hostapd.conf" ] ; then
    cat > "/etc/hostapd.conf" <<EOF
interface=${INTERFACE}
driver=${DRIVER}

hw_mode=${HW_MODE}
channel=${CHANNEL}
ieee80211n=1
wmm_enabled=1
ht_capab=${HT_CAPAB}
macaddr_acl=0
ignore_broadcast_ssid=0
#Next line is not listed at https://gary-dalton.github.io/RaspberryPi-projects/rpi3_simple_wifi_ap.html#2
wpa_ptk_rekey=600

# Use WPA2
auth_algs=1
wpa=2
wpa_key_mgmt=WPA-PSK
# TKIP is no secure anymore
#wpa_pairwise=TKIP CCMP
#Next line is not listed at https://gary-dalton.github.io/RaspberryPi-projects/rpi3_simple_wifi_ap.html#2
wpa_pairwise=CCMP
rsn_pairwise=CCMP

# Change these to your choice
# This is the name of the network
ssid=${SSID}
# The network passphrase
wpa_passphrase=${WPA_PASSPHRASE}
EOF

fi

# Setup interface and restart DHCP service 
ip link set ${INTERFACE} up
ip addr flush dev ${INTERFACE}
ip addr add ${AP_ADDR}/24 dev ${INTERFACE}
ifconfig ${INTERFACE} ${AP_ADDR}
echo Set IP address "${AP_ADDR}" on access point interface "${INTERFACE}". 


# NAT settings
echo "NAT settings ip_dynaddr, ip_forward"


#for i in ip_dynaddr ip_forward ; do 
#  if [ $(cat /proc/sys/net/ipv4/$i) ]; then
#    echo $i already 1 
#  else
#    echo "1" > /proc/sys/net/ipv4/$i
#  fi
#done
sysctl -w net.ipv4.ip_dynaddr=1
sysctl -w net.ipv4.ip_forward=1

cat /proc/sys/net/ipv4/ip_dynaddr 
cat /proc/sys/net/ipv4/ip_forward

if [ "${OUTGOINGS}" ] ; then
   ints="$(sed 's/,\+/ /g' <<<"${OUTGOINGS}")"
   for int in ${ints}
   do
      echo "Setting iptables for outgoing traffics on ${int}..."
      iptables -t nat -D POSTROUTING -s ${SUBNET}/24 -o ${int} -j MASQUERADE > /dev/null 2>&1 || true
      iptables -t nat -A POSTROUTING -s ${SUBNET}/24 -o ${int} -j MASQUERADE
   done
else
   echo "Setting iptables for outgoing traffics on all interfaces..."
   iptables -t nat -D POSTROUTING -s ${SUBNET}/24 -j MASQUERADE > /dev/null 2>&1 || true
   iptables -t nat -A POSTROUTING -s ${SUBNET}/24 -j MASQUERADE
fi
echo "Configuring DHCP server .."

cat > "/etc/dhcpd.conf" <<EOF
option domain-name-servers 8.8.8.8, 8.8.4.4;
option subnet-mask 255.255.255.0;
option routers ${AP_ADDR};
subnet ${SUBNET} netmask 255.255.255.0 {
  range ${SUBNET::-1}100 ${SUBNET::-1}200;
}
EOF

echo "Starting DHCP server .."
dhcpd wlan0

echo "Starting HostAP daemon ..."
/usr/sbin/hostapd /etc/hostapd.conf 

