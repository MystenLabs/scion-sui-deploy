# starts a generic Ubuntu instance for use as a generic end point for SCION testing
# instance will be connected to the scionwan network for SCION connectivity via the Edge
# instance will be connected to the virbr0 network for private connectivity to the host and NAT'd Internet connectivity

#IPV6_ADDRESS="2605:6440:a002:44::4/64"
#IPV6_GATEWAY="2605:6440:a002:44::1/64"

if [ -z "${IPV6_ADDRESS}" ] ; then
        echo "set IPV6_ADDRESS before proceeding"
        exit -1
fi


if [ -z "${IPV6_GATEWAY}" ] ; then
        echo "set IPV6_GATEWAY before proceeding"
        exit -1
fi



INSTANCE_NAME=ubuntu

incus init images:ubuntu/24.04 $INSTANCE_NAME \
        --vm

incus start $INSTANCE_NAME

sleep 20

incus config device add $INSTANCE_NAME eth0 nic nictype=bridged parent=virbr0
incus config device add $INSTANCE_NAME eth1 nic nictype=bridged parent=scionwan

NETPLAN_CONFIG=/tmp/scionsui-edge-netplan.$$

cat <<EOF > $NETPLAN_CONFIG
network:
  version: 2
  ethernets:
    enp5s0:
      dhcp4: true
    enp6s0:
      addresses:
      -  ${IPV6_ADDRESS}
      routes:
      - to: default
        via: ${IPV6_GATEWAY}
      nameservers:
        addresses:
        - 8.8.8.8
        - 8.8.4.4
        - 2001:4860:4860::8888
        - 2606:4700:4700::1111
EOF

incus exec $INSTANCE_NAME -- rm /etc/netplan/10-lxc.yaml
incus file push $NETPLAN_CONFIG $INSTANCE_NAME/etc/netplan/10-scionsui.yaml --mode 600
rm $NETPLAN_CONFIG
incus exec $INSTANCE_NAME -- netplan apply
incus exec $INSTANCE_NAME -- apt install apache2 -y
