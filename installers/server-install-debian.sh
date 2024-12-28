#!/bin/bash

hostnamectl set-hostname netserver

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

sed -i -e '1 s/^/127.0.0.1	netserver\n/;' /etc/hosts

echo "blacklist pcspkr" > /etc/modprobe.d/blacklist-pcspkr.conf

apt-get --force-yes -y full-upgrade
apt update && apt install --force-yes -y sudo locales net-tools man-db curl wget git make nano vim htop iftop bmon mc texinfo ssh iptables networkd-dispatcher tcpdump fail2ban zip rsync screen links neofetch
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

read -p "Enter name of new user: "
_USERNAME=$REPLY

bashrc () {
useradd -m -g users -s /bin/bash $1
echo Enter new user password:
passwd $1

echo "$1 ALL=(ALL:ALL) ALL" >> /etc/sudoers
echo "PS1='\[\e[1;31m\][\u@\h \W]\$\[\e[0m\] '" >> ~/.bashrc
echo 'export PATH=/usr/sbin/:$PATH' >> /root/.bashrc
echo 'export PATH=/sbin/:$PATH' >> /root/.bashrc
echo "export PATH=/home/$1/:"'$PATH' >> /root/.bashrc
source ~/.bashrc

echo "PS1='\[\e[1;32m\][\u@\h \W]\$\[\e[0m\] '" >> /home/$1/.bashrc
echo 'export PATH=/usr/sbin/:$PATH' >> /home/$1/.bashrc
echo 'export PATH=/sbin/:$PATH' >> /home/$1/.bashrc
echo "export PATH=/home/$1/:"'$PATH' >> /home/$1/.bashrc
}

bashrc "$_USERNAME"


sed -i 's/#Port 22/Port 989/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config
echo 'RSAAuthentication yes' >> /etc/ssh/sshd_config
echo '#PasswordAuthentication no' >> /etc/ssh/sshd_config
source ~/.bashrc
systemctl enable ssh.service

sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/" /etc/sysctl.conf
sysctl -p

apt install --force-yes -y software-properties-common python3-launchpadlib gnupg2 linux-headers-$(uname -r)
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 57290828
echo "deb https://ppa.launchpadcontent.net/amnezia/ppa/ubuntu focal main" | sudo tee -a /etc/apt/sources.list
echo "deb-src https://ppa.launchpadcontent.net/amnezia/ppa/ubuntu focal main" | sudo tee -a /etc/apt/sources.list
apt-get update
apt-get install --force-yes -y amneziawg

mkdir /etc/amnezia/amneziawg/keys
cd /etc/amnezia/amneziawg/keys

config () {
awg genkey | tee privatekey.server | awg pubkey > publickey.server
awg genkey | tee privatekey.client | awg pubkey > publickey.client
awg genpsk > presharedkey.client
touch /etc/amnezia/amneziawg/awg0.conf

if [ -z "$DEV" ]; then
local DEV="$(ip route | grep default | head -n 1 | awk '{print $5}')"
fi

local PRIVSERV=$(cat privatekey.server)
local PUBCL=$(cat publickey.client)
local PRECL=$(cat presharedkey.client)

echo "[Interface]" >> /etc/amnezia/amneziawg/awg0.conf
echo "PrivateKey = $PRIVSERV" >> /etc/amnezia/amneziawg/awg0.conf
echo "Address = 8.20.30.1/24" >> /etc/amnezia/amneziawg/awg0.conf
echo "ListenPort = 1984" >> /etc/amnezia/amneziawg/awg0.conf
echo "PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $DEV -j MASQUERADE" >> /etc/amnezia/amneziawg/awg0.conf
echo "PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $DEV -j MASQUERADE" >> /etc/amnezia/amneziawg/awg0.conf
echo "Jc = 4" >> /etc/amnezia/amneziawg/awg0.conf
echo "Jmin = 40" >> /etc/amnezia/amneziawg/awg0.conf
echo "Jmax = 70" >> /etc/amnezia/amneziawg/awg0.conf
echo "S1 = 68" >> /etc/amnezia/amneziawg/awg0.conf
echo "S2 = 149" >> /etc/amnezia/amneziawg/awg0.conf
echo "H1 = 1106457265" >> /etc/amnezia/amneziawg/awg0.conf
echo "H2 = 249455488" >> /etc/amnezia/amneziawg/awg0.conf
echo "H3 = 1209847463" >> /etc/amnezia/amneziawg/awg0.conf
echo "H4 = 1646644382" >> /etc/amnezia/amneziawg/awg0.conf
echo -e \ >> /etc/amnezia/amneziawg/awg0.conf
echo "[Peer]#client" >> /etc/amnezia/amneziawg/awg0.conf
echo "PresharedKey = $PRECL" >> /etc/amnezia/amneziawg/awg0.conf
echo "PublicKey = $PUBCL" >> /etc/amnezia/amneziawg/awg0.conf
echo "AllowedIPs = 8.20.30.2/32" >> /etc/amnezia/amneziawg/awg0.conf
echo -e \ >> /etc/amnezia/amneziawg/awg0.conf
}

workdirectories () {
mkdir /home/$1/user_configs
mkdir /home/$1/user_configs/client
mkdir /home/$1/config_files
cp /etc/amnezia/amneziawg/awg0.conf /home/$1/config_files/

local PUBSERV=$(cat publickey.server)
local PRIVCL=$(cat privatekey.client)
local PRECL=$(cat presharedkey.client)

touch /home/$1/config_files/client.conf

echo "[Interface]" >> /home/$1/config_files/client.conf
echo "PrivateKey = $PRIVCL" >> /home/$1/config_files/client.conf
echo "Address = 8.20.30.2/32" >> /home/$1/config_files/client.conf
echo "DNS = 8.8.8.8" >> /home/$1/config_files/client.conf
echo "Jc = 4" >> /home/$1/config_files/client.conf
echo "Jmin = 40" >> /home/$1/config_files/client.conf
echo "Jmax = 70" >> /home/$1/config_files/client.conf
echo "S1 = 68" >> /home/$1/config_files/client.conf
echo "S2 = 149" >> /home/$1/config_files/client.conf
echo "H1 = 1106457265" >> /home/$1/config_files/client.conf
echo "H2 = 249455488" >> /home/$1/config_files/client.conf
echo "H3 = 1209847463" >> /home/$1/config_files/client.conf
echo "H4 = 1646644382" >> /home/$1/config_files/client.conf
echo -e \ >> /home/$1/config_files/client.conf
echo "[Peer]" >> /home/$1/config_files/client.conf
echo "PresharedKey = $PRECL" >> /home/$1/config_files/client.conf
echo "PublicKey = $PUBSERV" >> /home/$1/config_files/client.conf
echo "Endpoint = 91.147.92.228:1984" >> /home/$1/config_files/client.conf
echo "AllowedIPs = 0.0.0.0/0" >> /home/$1/config_files/client.conf
echo "PersistentKeepalive = 20" >> /home/$1/config_files/client.conf

cp /home/$1/config_files/client.conf /home/$1/user_configs/client/
}

config "$_USERNAME"
workdirectories "$_USERNAME"

systemctl enable awg-quick@awg0.service
systemctl start awg-quick@awg0.service

crontab_install () {
    echo Are you need awg reboot rule?
    read -p "enter "yes" or "no": "

    if [[ "$REPLY" = "yes" ]]; then
        touch /etc/amnezia/amneziawg/awg-reboot.sh
        echo '#!/bin/bash' >> /etc/amnezia/amneziawg/awg-reboot.sh
        echo -e \ >> /etc/amnezia/amneziawg/awg-reboot.sh
        echo "systemctl restart awg-quick@awg0.service" >> /etc/amnezia/amneziawg/awg-reboot.sh
        echo Copy path to script and enter to crontab file: "0 5 * * 1 /etc/amnezia/amneziawg/awg-reboot.sh" 
        edit_crontab

    elif [[ "$REPLY" = "no" ]]; then
        echo Installation Done, Reboot system!

    else 
        crontab_install
    fi
}

edit_crontab () {
    echo Installation Done, Reboot system!
    read -p "Running crontab -e. Press enter to continue: "
    crontab -e
}

crontab_install

#reboot after installation