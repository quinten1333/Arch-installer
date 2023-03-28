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

if [ "$(question "The partition $rootPartition will be formatted. Are you sure?" "y,n" "n")" != "y" ]; then
    echo "Okey cancelling the installation."
    exit 0
fi

section "Formatting partition"
mkfs.ext4 "$rootPartition"

mount "$rootPartition" /mnt

section "Installing"
pacman-key --init && pacman-key -populate archlinux
pacstrap /mnt $packages

section "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

section "Check fstab"
cat /mnt/etc/fstab

section "Setting hostname"
echo "$hostname" > /mnt/etc/hostname

section "Running configuration inside chroot"
cp systeminit.sh /mnt/. # Make the file available in chroot
cp config.sh /mnt/. # Make the file available in chroot
arch-chroot /mnt /bin/bash /systeminit.sh # Run it inside of chroot
rm /mnt/systeminit.sh # Cleanup

section "Done :D"

if [ $(question "Do you want unmount and exit" "y,n" "n") != "y" ]; then
    echo "Okey, please do what you want then type 'exit' to unmount and shutdown"
    zsh
fi

section "Unmounting everything"
umount /mnt

echo "Everything is unmounted."
echo "Shutting down in 3 seconds"
sleep 3
shutdown now
