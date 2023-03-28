# Note: grub, sudo and openssh are assumed to be installed
packages="base linux linux-headers grub openssh sudo nano"
services=("systemd-networkd" "systemd-resolved" "sshd")
hostname="archServer"

userGroups="wheel"

rootPartition="/dev/xvda1"
