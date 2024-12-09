#!/bin/sh
# starts an instance of the Edge appliance as a VM
# pre-req:
#  Edge Appliance UEFI QCOW2 must already be loaded as an image called edge
#  virbr0 must be configured as a managed local bridged network (dhcp)
#  scionwan must be configured as a unmanaged bridge network
#  an extra IP on the scionwan must be available for the Edge
#
# This has only been tested on the Latitude m3.large.x86 hardware
#
# notes:
#  after install, it takes a few minutes for the appliance to come online as it does updates
#  the web GUI and the appliance-cli tool will not be available until this completes
EDGE_NAME=edge01

incus init edge $EDGE_NAME \
        --vm \
        --config limits.cpu=4 \
        --config limits.memory=4096MiB

incus start $EDGE_NAME

sleep 20

incus config device add $EDGE_NAME eth0 nic nictype=bridged parent=virbr0
incus config device add $EDGE_NAME eth1 nic nictype=bridged parent=scionwan

NETPLAN_CONFIG=/tmp/scionsui-edge-netplan.$$

cat <<EOF > $NETPLAN_CONFIG
network:
  version: 2
  ethernets:
    enp5s0:
      dhcp4: true
    enp6s0:
      addresses:
      - 45.250.253.165/31
      routes:
      - to: default
        via: 45.250.253.164
      nameservers:
        addresses:
        - 8.8.8.8
        - 8.8.4.4
EOF

incus exec $EDGE_NAME -- rm /etc/netplan/00-installer-config.yaml
incus file push $NETPLAN_CONFIG $EDGE_NAME/etc/netplan/10-scionsui.yaml --mode 600
rm $NETPLAN_CONFIG
incus exec $EDGE_NAME -- netplan apply

# configure the appliance as an Edge
incus exec $EDGE_NAME -- mkdir /home/anapaya/.appliance-cli
#incus file push appliances.json $EDGE_NAME/home/anapaya/.appliance-cli/appliances.json
#incus file push context.json $EDGE_NAME/home/anapaya/.appliance-cli/context.json
#incus file push edge-config.json $EDGE_NAME/home/anapaya/edge-config.json

