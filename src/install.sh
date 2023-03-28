#!/bin/bash

if [ "$(id -u)" != 0 ]; then
    echo "This script needs to be run as root"
    exit 1
fi

source ./config.sh

function section() { # Name
    length=20
    letters=$(echo $1 | wc -m)

    printf "=%.0s" $(seq 1 $(($length - $letters/2)))
    echo -n $1
    printf "=%.0s" $(seq 1 $(($length - $letters/2)))
    echo
}

function question() { # Question,answers,default
    echo -n "$1" >&2
    if [ "$2" != "" ]; then
        echo -n "[$2]" >&2
    fi
    if [ "$3" != "" ]; then
        echo -n "($3)" >&2
    fi
    echo >&2

    read answer

    if [ "$answer" != "" ]; then
        echo $answer
    else
        echo $3
    fi
}

timedatectl set-ntp true

section "fdisk -l"
fdisk -l | grep "Disk /dev"

section "Choose disk"
disk=$(question "What drive do you want to install arch on?" "/dev/sd?,/dev/nvme?" "")
echo "Disk: $disk"
if [ "$(question "The drive will be formatted. Are you sure?" "y,n" "n")" != "y" ]; then
    echo "Okey cancelling the installation."
    exit 0
fi

section "Formatting disk"
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' < fdisk_partitioning | fdisk "$disk"

section "Getting paths"
boot_partition=$(question "What is the path to the EFI System partition?" "" "${disk}1")
root_partition=$(question "What is the path to the Linux root partition?" "" "${disk}2")

section "Formatting partitions"
mkfs.fat -F 16 "$boot_partition"
mkfs.ext4 "$root_partition"

mount "$root_partition" /mnt
mkdir /mnt/boot
mount "$boot_partition" /mnt/boot

section "Installing"
pacman-key --init && pacman-key --populate archlinux
pacstrap /mnt $packages

section "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

section "Check fstab"
cat /mnt/etc/fstab
if [ $(question "Looks this fstab correct?" "y,n" "y") != "y" ]; then
    echo "Okey, please fix it and then type 'exit'"
    zsh
fi

section "Setting hostname"
hostname=$(question "What should the hostname of the new install be?" "" "$defaultHostname")
echo "$hostname" > /mnt/etc/hostname

section "Running configuration inside chroot"
cp systeminit.sh /mnt/. # Make the file available in chroot
cp config.sh /mnt/. # Make the file available in chroot
arch-chroot /mnt /bin/bash /systeminit.sh # Run it inside of chroot
rm /mnt/config.sh # Cleanup
rm /mnt/systeminit.sh # Cleanup

section "Done :D"

if [ $(question "Do you want unmount and exit" "y,n" "n") != "y" ]; then
    echo "Okey, please do what you want then type 'exit' to unmount and shutdown"
    zsh
fi

section "Unmounting everything"
umount /mnt/boot
umount /mnt

echo "Everything is unmounted."
if [ $(question "Do you want to shutdown now?" "y,n" "y") == "y" ]; then
    shutdown now
fi
