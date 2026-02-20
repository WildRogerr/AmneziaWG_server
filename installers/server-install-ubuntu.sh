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

apt-get -y full-upgrade
apt update && apt install -y sudo locales net-tools man-db curl wget git make nano vim htop iftop bmon vnstat mc texinfo ssh iptables networkd-dispatcher tcpdump fail2ban resolvconf zip rsync sshfs screen links neofetch
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

read -p "Enter name of new user: " _USERNAME
read -p "Enter (ip address:port) of vpn server: " _IPADDRESS

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

sed -i "deb-src/^#//" /etc/apt/sources.list
# for Ubuntu 24 # sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources
apt-get update
apt install -y software-properties-common python3-launchpadlib gnupg2 linux-headers-$(uname -r)
add-apt-repository ppa:amnezia/ppa
apt-get install -y amneziawg

mkdir /etc/amnezia/amneziawg/keys
cd /etc/amnezia/amneziawg/keys

config () {
awg genkey | tee privatekey.server | awg pubkey > publickey.server
awg genkey | tee privatekey.client888 | awg pubkey > publickey.client888
awg genpsk > presharedkey.client888
touch /etc/amnezia/amneziawg/awg0.conf

if [ -z "$DEV" ]; then
local DEV="$(ip route | grep default | head -n 1 | awk '{print $5}')"
fi

local PRIVSERV=$(cat privatekey.server)
local PUBCL=$(cat publickey.client888)
local PRECL=$(cat presharedkey.client888)

echo "[Interface]" >> /etc/amnezia/amneziawg/awg0.conf
echo "PrivateKey = $PRIVSERV" >> /etc/amnezia/amneziawg/awg0.conf
echo "Address = 8.20.30.1/24" >> /etc/amnezia/amneziawg/awg0.conf
echo "ListenPort = 1984" >> /etc/amnezia/amneziawg/awg0.conf
echo "PostUp = iptables -A FORWARD -i %i -o %i -s 8.20.30.0/24 -d 8.20.30.0/24 -j DROP; iptables -A FORWARD -i %i -o $DEV -j ACCEPT; iptables -A FORWARD -i $DEV -o %i -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -A POSTROUTING -s 8.20.30.0/24 -o $DEV -j MASQUERADE" >> /etc/amnezia/amneziawg/awg0.conf
echo "PostDown = iptables -D FORWARD -i %i -o %i -s 8.20.30.0/24 -d 8.20.30.0/24 -j DROP; iptables -D FORWARD -i %i -o $DEV -j ACCEPT; iptables -D FORWARD -i $DEV -o %i -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -D POSTROUTING -s 8.20.30.0/24 -o $DEV -j MASQUERADE" >> /etc/amnezia/amneziawg/awg0.conf
echo "Jc = 5" >> /etc/amnezia/amneziawg/awg0.conf
echo "Jmin = 40" >> /etc/amnezia/amneziawg/awg0.conf
echo "Jmax = 70" >> /etc/amnezia/amneziawg/awg0.conf
echo "S1 = 8" >> /etc/amnezia/amneziawg/awg0.conf
echo "S2 = 5" >> /etc/amnezia/amneziawg/awg0.conf
echo "H1 = 1106457265" >> /etc/amnezia/amneziawg/awg0.conf
echo "H2 = 249455488" >> /etc/amnezia/amneziawg/awg0.conf
echo "H3 = 1209847463" >> /etc/amnezia/amneziawg/awg0.conf
echo "H4 = 1646644382" >> /etc/amnezia/amneziawg/awg0.conf
echo "I1 = <b 0xc70000000108ce1bf31eec7d93360000449e227e4596ed7f75c4d35ce31880b4133107c822c6355b51f0d7c1bba96d5c210a48aca01885fed0871cfc37d59137d73b506dc013bb4a13c060ca5b04b7ae215af71e37d6e8ff1db235f9fe0c25cb8b492471054a7c8d0d6077d430d07f6e87a8699287f6e69f54263c7334a8e144a29851429bf2e350e519445172d36953e96085110ce1fb641e5efad42c0feb4711ece959b72cc4d6f3c1e83251adb572b921534f6ac4b10927167f41fe50040a75acef62f45bded67c0b45b9d655ce374589cad6f568b8475b2e8921ff98628f86ff2eb5bcce6f3ddb7dc89e37c5b5e78ddc8d93a58896e530b5f9f1448ab3b7a1d1f24a63bf981634f6183a21af310ffa52e9ddf5521561760288669de01a5f2f1a4f922e68d0592026bbe4329b654d4f5d6ace4f6a23b8560b720a5350691c0037b10acfac9726add44e7d3e880ee6f3b0d6429ff33655c297fee786bb5ac032e48d2062cd45e305e6d8d8b82bfbf0fdbc5ec09943d1ad02b0b5868ac4b24bb10255196be883562c35a713002014016b8cc5224768b3d330016cf8ed9300fe6bf39b4b19b3667cddc6e7c7ebe4437a58862606a2a66bd4184b09ab9d2cd3d3faed4d2ab71dd821422a9540c4c5fa2a9b2e6693d411a22854a8e541ed930796521f03a54254074bc4c5bca152a1723260e7d70a24d49720acc544b41359cfc252385bda7de7d05878ac0ea0343c77715e145160e6562161dfe2024846dfda3ce99068817a2418e66e4f37dea40a21251c8a034f83145071d93baadf050ca0f95dc9ce2338fb082d64fbc8faba905cec66e65c0e1f9b003c32c943381282d4ab09bef9b6813ff3ff5118623d2617867e25f0601df583c3ac51bc6303f79e68d8f8de4b8363ec9c7728b3ec5fcd5274edfca2a42f2727aa223c557afb33f5bea4f64aeb252c0150ed734d4d8eccb257824e8e090f65029a3a042a51e5cc8767408ae07d55da8507e4d009ae72c47ddb138df3cab6cc023df2532f88fb5a4c4bd917fafde0f3134be09231c389c70bc55cb95a779615e8e0a76a2b4d943aabfde0e394c985c0cb0376930f92c5b6998ef49ff4a13652b787503f55c4e3d8eebd6e1bc6db3a6d405d8405bd7a8db7cefc64d16e0d105a468f3d33d29e5744a24c4ac43ce0eb1bf6b559aed520b91108cda2de6e2c4f14bc4f4dc58712580e07d217c8cca1aaf7ac04bab3e7b1008b966f1ed4fba3fd93a0a9d3a27127e7aa587fbcc60d548300146bdc126982a58ff5342fc41a43f83a3d2722a26645bc961894e339b953e78ab395ff2fb854247ad06d446cc2944a1aefb90573115dc198f5c1efbc22bc6d7a74e41e666a643d5f85f57fde81b87ceff95353d22ae8bab11684180dd142642894d8dc34e402f802c2fd4a73508ca99124e428d67437c871dd96e506ffc39c0fc401f666b437adca41fd563cbcfd0fa22fbbf8112979c4e677fb533d981745cceed0fe96da6cc0593c430bbb71bcbf924f70b4547b0bb4d41c94a09a9ef1147935a5c75bb2f721fbd24ea6a9f5c9331187490ffa6d4e34e6bb30c2c54a0344724f01088fb2751a486f425362741664efb287bce66c4a544c96fa8b124d3c6b9eaca170c0b530799a6e878a57f402eb0016cf2689d55c76b2a91285e2273763f3afc5bc9398273f5338a06d>" >> /etc/amnezia/amneziawg/awg0.conf
echo -e \ >> /etc/amnezia/amneziawg/awg0.conf
echo "[Peer]#client888" >> /etc/amnezia/amneziawg/awg0.conf
echo "PresharedKey = $PRECL" >> /etc/amnezia/amneziawg/awg0.conf
echo "PublicKey = $PUBCL" >> /etc/amnezia/amneziawg/awg0.conf
echo "AllowedIPs = 8.20.30.2/32" >> /etc/amnezia/amneziawg/awg0.conf
echo -e \ >> /etc/amnezia/amneziawg/awg0.conf
}

workdirectories () {
mkdir /home/$1/user_configs
mkdir /home/$1/user_configs/client888
mkdir /home/$1/config_files
cp /etc/amnezia/amneziawg/awg0.conf /home/$1/config_files/

local PUBSERV=$(cat publickey.server)
local PRIVCL=$(cat privatekey.client888)
local PRECL=$(cat presharedkey.client888)

touch /home/$1/config_files/client.conf

echo "[Interface]" >> /home/$1/config_files/client.conf
echo "PrivateKey = $PRIVCL" >> /home/$1/config_files/client.conf
echo "Address = 8.20.30.2/32" >> /home/$1/config_files/client.conf
echo "DNS = 8.8.8.8" >> /home/$1/config_files/client.conf
echo "Jc = 5" >> /home/$1/config_files/client.conf
echo "Jmin = 40" >> /home/$1/config_files/client.conf
echo "Jmax = 70" >> /home/$1/config_files/client.conf
echo "S1 = 8" >> /home/$1/config_files/client.conf
echo "S2 = 5" >> /home/$1/config_files/client.conf
echo "H1 = 1106457265" >> /home/$1/config_files/client.conf
echo "H2 = 249455488" >> /home/$1/config_files/client.conf
echo "H3 = 1209847463" >> /home/$1/config_files/client.conf
echo "H4 = 1646644382" >> /home/$1/config_files/client.conf
echo "I1 = <b 0xc70000000108ce1bf31eec7d93360000449e227e4596ed7f75c4d35ce31880b4133107c822c6355b51f0d7c1bba96d5c210a48aca01885fed0871cfc37d59137d73b506dc013bb4a13c060ca5b04b7ae215af71e37d6e8ff1db235f9fe0c25cb8b492471054a7c8d0d6077d430d07f6e87a8699287f6e69f54263c7334a8e144a29851429bf2e350e519445172d36953e96085110ce1fb641e5efad42c0feb4711ece959b72cc4d6f3c1e83251adb572b921534f6ac4b10927167f41fe50040a75acef62f45bded67c0b45b9d655ce374589cad6f568b8475b2e8921ff98628f86ff2eb5bcce6f3ddb7dc89e37c5b5e78ddc8d93a58896e530b5f9f1448ab3b7a1d1f24a63bf981634f6183a21af310ffa52e9ddf5521561760288669de01a5f2f1a4f922e68d0592026bbe4329b654d4f5d6ace4f6a23b8560b720a5350691c0037b10acfac9726add44e7d3e880ee6f3b0d6429ff33655c297fee786bb5ac032e48d2062cd45e305e6d8d8b82bfbf0fdbc5ec09943d1ad02b0b5868ac4b24bb10255196be883562c35a713002014016b8cc5224768b3d330016cf8ed9300fe6bf39b4b19b3667cddc6e7c7ebe4437a58862606a2a66bd4184b09ab9d2cd3d3faed4d2ab71dd821422a9540c4c5fa2a9b2e6693d411a22854a8e541ed930796521f03a54254074bc4c5bca152a1723260e7d70a24d49720acc544b41359cfc252385bda7de7d05878ac0ea0343c77715e145160e6562161dfe2024846dfda3ce99068817a2418e66e4f37dea40a21251c8a034f83145071d93baadf050ca0f95dc9ce2338fb082d64fbc8faba905cec66e65c0e1f9b003c32c943381282d4ab09bef9b6813ff3ff5118623d2617867e25f0601df583c3ac51bc6303f79e68d8f8de4b8363ec9c7728b3ec5fcd5274edfca2a42f2727aa223c557afb33f5bea4f64aeb252c0150ed734d4d8eccb257824e8e090f65029a3a042a51e5cc8767408ae07d55da8507e4d009ae72c47ddb138df3cab6cc023df2532f88fb5a4c4bd917fafde0f3134be09231c389c70bc55cb95a779615e8e0a76a2b4d943aabfde0e394c985c0cb0376930f92c5b6998ef49ff4a13652b787503f55c4e3d8eebd6e1bc6db3a6d405d8405bd7a8db7cefc64d16e0d105a468f3d33d29e5744a24c4ac43ce0eb1bf6b559aed520b91108cda2de6e2c4f14bc4f4dc58712580e07d217c8cca1aaf7ac04bab3e7b1008b966f1ed4fba3fd93a0a9d3a27127e7aa587fbcc60d548300146bdc126982a58ff5342fc41a43f83a3d2722a26645bc961894e339b953e78ab395ff2fb854247ad06d446cc2944a1aefb90573115dc198f5c1efbc22bc6d7a74e41e666a643d5f85f57fde81b87ceff95353d22ae8bab11684180dd142642894d8dc34e402f802c2fd4a73508ca99124e428d67437c871dd96e506ffc39c0fc401f666b437adca41fd563cbcfd0fa22fbbf8112979c4e677fb533d981745cceed0fe96da6cc0593c430bbb71bcbf924f70b4547b0bb4d41c94a09a9ef1147935a5c75bb2f721fbd24ea6a9f5c9331187490ffa6d4e34e6bb30c2c54a0344724f01088fb2751a486f425362741664efb287bce66c4a544c96fa8b124d3c6b9eaca170c0b530799a6e878a57f402eb0016cf2689d55c76b2a91285e2273763f3afc5bc9398273f5338a06d>" >> /home/$1/config_files/client.conf
echo -e \ >> /home/$1/config_files/client.conf
echo "[Peer]" >> /home/$1/config_files/client.conf
echo "PresharedKey = $PRECL" >> /home/$1/config_files/client.conf
echo "PublicKey = $PUBSERV" >> /home/$1/config_files/client.conf
echo "Endpoint = $2" >> /home/$1/config_files/client.conf
echo "AllowedIPs = 0.0.0.0/0, ::/0" >> /home/$1/config_files/client.conf
echo "PersistentKeepalive = 20" >> /home/$1/config_files/client.conf

cp /home/$1/config_files/client.conf /home/$1/user_configs/client888/

echo $2 >> /etc/amnezia/amneziawg/keys/ipaddress
}

config "$_USERNAME"
workdirectories "$_USERNAME" "$_IPADDRESS"

systemctl enable awg-quick@awg0.service
systemctl start awg-quick@awg0.service

mkdir /root/bin/
touch /root/bin/set_tc.sh
touch /root/bin/speed_limit

echo "30" >> /root/bin/speed_limit

echo "#!/bin/bash" >> /root/bin/set_tc.sh
echo -e \ >> /root/bin/set_tc.sh 
echo '_SPEED_LIMIT=$(cat /root/bin/speed_limit)' >> /root/bin/set_tc.sh
echo '_QUANTUM=$(( ${_SPEED_LIMIT} * 125000 / 200 ))' >> /root/bin/set_tc.sh
echo -e \ >> /root/bin/set_tc.sh
echo 'tc qdisc add dev awg0 root handle 1: htb default 12 r2q 256' >> /root/bin/set_tc.sh
echo 'tc class add dev awg0 parent 1: classid 1:1 htb rate 1000mbit ceil 1000mbit quantum 40000' >> /root/bin/set_tc.sh
echo -e \ >> /root/bin/set_tc.sh
echo "# users" >> /root/bin/set_tc.sh
echo -e \ >> /root/bin/set_tc.sh 

for i in {2..253}; do
    IP="8.20.30.$i"
    CLASSID="1:$i"
    
    echo 'tc class add dev awg0 parent 1:1 classid '"$CLASSID"' htb rate "${_SPEED_LIMIT}"mbit ceil "${_SPEED_LIMIT}"mbit quantum ${_QUANTUM}' >> /root/bin/set_tc.sh
    echo "tc filter add dev awg0 protocol ip parent 1:0 prio 1 u32 match ip dst $IP flowid $CLASSID" >> /root/bin/set_tc.sh
done

chmod 755 /root/bin/set_tc.sh

touch /etc/systemd/system/set-tc.service

echo "[Unit]" >> /etc/systemd/system/set-tc.service
echo "Description=Set TC rules on awg0" >> /etc/systemd/system/set-tc.service
echo "After=network.target" >> /etc/systemd/system/set-tc.service
echo "[Service]" >> /etc/systemd/system/set-tc.service
echo "Type=oneshot" >> /etc/systemd/system/set-tc.service
echo "ExecStart=/root/bin/set_tc.sh" >> /etc/systemd/system/set-tc.service
echo "RemainAfterExit=true" >> /etc/systemd/system/set-tc.service
echo "[Install]" >> /etc/systemd/system/set-tc.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/set-tc.service

systemctl enable set-tc
systemctl start set-tc

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