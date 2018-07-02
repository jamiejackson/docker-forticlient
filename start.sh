#!/bin/sh

if [ -z "$VPNADDR" -o -z "$VPNUSER" ]; then
  echo "Variables VPNADDR and VPNUSER must be set."; exit;
fi

export VPNTIMEOUT=${VPNTIMEOUT:-5}

# Setup masquerade, to allow using the container as a gateway
for iface in $(ip a | grep eth | grep inet | awk '{print $2}'); do
  iptables -t nat -A POSTROUTING -s "$iface" -j MASQUERADE
done

/usr/share/forticlient/opt/forticlient-sslvpn/64bit/forticlientsslvpn_cli \
  --server "$VPNADDR" --vpnuser $VPNUSER --keepalive
