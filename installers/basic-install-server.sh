#!/bin/bash

read -p "Enter hostname: " _HOSTNAME

hostnamectl set-hostname $_HOSTNAME

root_password () {
read -p "Change root password?(yes/no): "
if [[ "$REPLY" = "yes" ]]; then
    echo Enter root password:
    passwd
elif [[ "$REPLY" = "no" ]]; then
    echo Install continue
else 
    root_password
fi
}

root_password

sed -i -e "1 s/^/127.0.0.1	$_HOSTNAME\n/;" /etc/hosts

echo "blacklist pcspkr" > /etc/modprobe.d/blacklist-pcspkr.conf

apt-get -y update
apt-get -y full-upgrade
apt update && apt install -y sudo locales net-tools man-db wget git make nano vim htop iftop bmon vnstat ifstat mc texinfo ssh iptables networkd-dispatcher tcpdump fail2ban resolvconf zip rsync sshfs screen links
systemctl start fail2ban
systemctl enable fail2ban

sed -i "s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/" /etc/locale.gen
sed -i "s/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/" /etc/locale.gen
locale-gen
echo LANGUAGE=en_US.UTF-8 >> /etc/default/locale
echo LC_ALL=en_US.UTF-8 >> /etc/default/locale
echo LANG=C.UTF-8 >> /etc/default/locale
echo LC_TYPE=en_US.UTF-8 >> /etc/default/locale
locale-gen

cat << 'EOF' >> /etc/resolv.conf
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

systemctl restart resolvconf

read -p "Enter name of new user: " _USERNAME

function bashrc () {
    useradd -m -g users -s /bin/bash $1
    echo Enter new user password:
    passwd $1

    echo "$1 ALL=(ALL:ALL) ALL" >> /etc/sudoers
    echo "PS1='\[\e[1;31m\][\u@\h \W]\$\[\e[0m\] '" >> ~/.bashrc
    echo 'export PATH=/usr/sbin/:$PATH' >> /root/.bashrc
    echo 'export PATH=/sbin/:$PATH' >> /root/.bashrc
    echo "export PATH=/home/$1/:"'$PATH' >> /root/.bashrc
    echo "alias ll='ls -l'" >> /root/.bashrc
    source ~/.bashrc

    echo "PS1='\[\e[1;32m\][\u@\h \W]\$\[\e[0m\] '" >> /home/$1/.bashrc
    echo 'export PATH=/usr/sbin/:$PATH' >> /home/$1/.bashrc
    echo 'export PATH=/sbin/:$PATH' >> /home/$1/.bashrc
    echo "export PATH=/home/$1/:"'$PATH' >> /home/$1/.bashrc
    echo "alias ll='ls -l'" >> /home/$1/.bashrc
}

bashrc "$_USERNAME"

sed -i 's/#Port 22/Port 989/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config
echo 'RSAAuthentication yes' >> /etc/ssh/sshd_config
echo '#PasswordAuthentication no' >> /etc/ssh/sshd_config
source ~/.bashrc
systemctl enable ssh.service
systemctl restart ssh.service