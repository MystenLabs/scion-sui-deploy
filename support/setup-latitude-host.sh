#!/bin/bash
# sets up virtualization on a host in preparation for running the Edge appliance
# this includes setting up the various networks (physical and virtual)
# the appliance image is pulled down and made into an image ready for provisioning

# TOKEN must be set to download the appliance image
TOKEN=""

wget https://dl.cloudsmith.io/$TOKEN/anapaya/stable/raw/names/anapaya-appliance-base-uefi-qcow2/versions/sys_v2.10.0-scion_v0.36.0-1/anapaya-appliance-base-sys_v2.10.0-scion_v0.36.0-1-uefi.qcow2 -O appliance-uefi.qcow2

apt update

cat << EOF > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
network: {config: disabled}
EOF

mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-scionsui.yaml

echo "Please update /etc/netplan/50-scionsui.yaml to create scionwan"

apt install incus -y
adduser studarus incus-admin
newgrp incus-admin
incus admin init --minimal

incus network create virbr0

apt install qemu-utils qemu-system-x86
incus admin shutdown
incus admin waitready

ls -l appliance-uefi.qcow2

cat << EOF > metadata.yaml
architecture: x86_64
creation_date: 1731113903
properties:
EOF
tar -cvzf metadata.tar.gz metadata.yaml

incus image import metadata.tar.gz appliance-uefi.qcow2 --alias edge
