#!/usr/bin/env bash

set -o errexit

echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# udev is needed for booting a "real" VM, setting up the ttyS0 console properly
# kmod is needed for modprobing modules
# systemd is needed for running as PID 1 as /sbin/init
# Also, other utilities are installed
apt-get update && apt-get install -y \
  curl \
  dbus \
  kmod \
  iproute2 \
  iputils-ping \
  net-tools \
  openssh-server \
  rng-tools \
  sudo \
  systemd \
  udev \
  vim-tiny \
  wget \
  e2fsprogs \
  thin-provisioning-tools \
  lvm2 \
  tar \
  curl \
  ethtool \
  socat \
  ebtables \
  iptables \
  conntrack

apt-get clean && rm -rf /var/lib/apt/lists/*

# Create the following files, but unset them
echo "" >/etc/machine-id && echo "" >/var/lib/dbus/machine-id

# This container image doesn't have locales installed. Disable forwarding the
# user locale env variables or we get warnings such as:
#  bash: warning: setlocale: LC_ALL: cannot change locale
sed -i -e 's/^AcceptEnv LANG LC_\*$/#AcceptEnv LANG LC_*/' /etc/ssh/sshd_config

echo "root:root" | chpasswd

sed -i -E "s/#PasswordAuthentication no/PasswordAuthentication no/g" /etc/ssh/sshd_config
systemctl enable ssh

cat <<'EOF' >>/etc/profile
if [ ! -S ~/.ssh/ssh_auth_sock ]; then
  eval `ssh-agent`
  ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
fi
export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock
ssh-add -l > /dev/null || ssh-add
EOF
