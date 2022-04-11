# Note: grub, sudo and openssh are assumed to be installed
packages="base linux-lts linux-lts-headers linux-firmware grub efibootmgr networkmanager openssh sudo qemu-guest-agent nano"
services=("NetworkManager" "sshd" "qemu-guest-agent" )
defaultHostname="archServer"

userGroups="wheel"
