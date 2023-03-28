#!/bin/bash

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


section "Setting up boot partition"
# grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB # Not needed in paravirtualization
mkdir -p /boot/grub/
grub-mkconfig -o /boot/grub/grub.cfg

secion "Configuring systemd networking"
echo > /etc/systemd/network/20-dhcp.network <<EOF
[Match]
Name=en*

[Network]
DHCP=yes
EOF

section "Root password"
passwd

section "Setting up default user"
username=$(question "What is the username for the default user?")
useradd -m -G "$userGroups" "$username"
passwd "$username"

githubUsername=$(question "What is the github username of the default user?")
mkdir -p /home/$username/.ssh
curl https://github.com/$githubUsername.keys > /home/$username/.ssh/authorized_keys

section "Disabling password auth for ssh server"
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

section "Adding wheel group to sudoers"
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

section "Enabling services"
for service in "${services[@]}"; do
    systemctl enable $service
    echo "Enabled: $service"
done
