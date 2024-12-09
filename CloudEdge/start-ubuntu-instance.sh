# starts a generic Ubuntu instance for use as a generic end point for SCION testing
# instance will be connected to the scionwan network for SCION connectivity via the Edge

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
      - 2605:6440:8002:11::4/64
      routes:
      - to: default
        via: 2605:6440:8002:11::1
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
