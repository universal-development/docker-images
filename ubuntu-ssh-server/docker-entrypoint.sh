#!/bin/bash
set -e

SSH_USER=${SSH_USER:-root}
SSH_PASS=${SSH_PASS:-rootroot}

# Update sshd_config to allow root login and password authentication
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

if [ "$SSH_USER" = "root" ]; then
    echo "root:$SSH_PASS" | chpasswd
else
    if ! id "$SSH_USER" &>/dev/null; then
        useradd -m -s /bin/bash "$SSH_USER"
    fi
    echo "$SSH_USER:$SSH_PASS" | chpasswd
    echo "$SSH_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
fi

exec /usr/sbin/sshd -D
