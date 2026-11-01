#!/bin/bash

# Put awgm.sh with this script in /root

sed -i "deb-src/^#//" /etc/apt/sources.list
# for Ubuntu 24 # sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources
apt-get update
apt install -y software-properties-common python3-launchpadlib gnupg2 linux-headers-$(uname -r)
add-apt-repository ppa:amnezia/ppa
apt-get update
apt-get install -y amneziawg

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
apt update && apt install -y sudo locales net-tools man-db wget git make nano vim htop iftop bmon vnstat ifstat mc texinfo ssh iptables networkd-dispatcher tcpdump fail2ban resolvconf zip rsync sshfs screen links neofetch
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
read -p "Enter (ip address:port) of vpn server: " _IPADDRESS

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

sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/" /etc/sysctl.conf
sysctl -p

mkdir /etc/amnezia/amneziawg/keys
cd /etc/amnezia/amneziawg/keys

function create_encrypt_config () {
    local CONFIG="encrypt.conf"
    local PARAM INPUT
    local -A VALUES=()

    local -a PARAM_NAMES=(
        Jc
        Jmin
        Jmax
        S1
        S2
        S3
        S4
        H1
        H2
        H3
        H4
        I1
        I2
        I3
        I4
        I5
        ContentPaddingAddition
        RekeyAfterTime
        RekeyTimeout
        RejectAfterTime
        KeepaliveTimeout
        MaxHandshakeAttempts
        RandomTrailers
        DisableCookies
    )

    echo
    echo "Configure encryption parameters"
    echo "Enter values for each parameter."
    echo

    for PARAM in "${PARAM_NAMES[@]}"; do

        while true; do
            read -r -p "$PARAM: " INPUT || return 1

            if [[ -n "$INPUT" ]]; then
                VALUES["$PARAM"]="$INPUT"
                break
            fi

            echo "Value cannot be empty!"
        done

    done

    echo
    echo "Configuration summary:"
    echo

    for PARAM in "${PARAM_NAMES[@]}"; do
        echo "$PARAM = ${VALUES[$PARAM]}"
    done

    echo
    read -r -p "Save configuration? [Y/n]: " INPUT
    
    if [[ "$INPUT" =~ ^[Nn]$ ]]; then
        echo "Configuration cancelled."
        return 1
    fi

    {
        for PARAM in "${PARAM_NAMES[@]}"; do
            echo "$PARAM = ${VALUES[$PARAM]}"
        done
    } > "$CONFIG"

    echo
    echo "Encryption configuration saved to $CONFIG"
}

function config () {
    awg genkey | tee privatekey.server | awg pubkey > publickey.server
    awg genkey | tee privatekey.client888 | awg pubkey > publickey.client888
    awg genpsk > presharedkey.client888
    awg genkey > header.protection.key

    local USERCONFIG PORT

    read -r -p "Enter user config name: " USERCONFIG
    read -r -p "Enter vpn port: " PORT
    echo "$USERCONFIG" >  userconfig.name

    if [ -z "$DEV" ]; then
    local DEV="$(ip route | grep default | head -n 1 | awk '{print $5}')"
    fi

    local CONFIG="/etc/amnezia/amneziawg/awg0.conf"
    local PRIVSERV=$(cat privatekey.server)
    local PUBCL=$(cat publickey.client888)
    local PRECL=$(cat presharedkey.client888)
    local HEADPRKEY=$(cat header.protection.key)
    local -A ENCRYPT_PARAMS
    local key value

    create_encrypt_config || return 1

    while IFS='=' read -r key value; do
        key="${key//[[:space:]]/}"

        # Skip empty lines and comments
        [[ -z "$key" || "$key" == \#* ]] && continue

        # Remove leading whitespace from value
        value="${value#"${value%%[![:space:]]*}"}"

        # Remove trailing whitespace from value
        value="${value%"${value##*[![:space:]]}"}"

        ENCRYPT_PARAMS["$key"]="$value"

    done < "encrypt.conf"

    echo "[Interface]" > "$CONFIG"
    echo "PrivateKey = $PRIVSERV" >> "$CONFIG"
    echo "Address = 8.20.30.1/24" >> "$CONFIG"
    echo "ListenPort = $PORT" >> "$CONFIG"
    echo "PostUp = iptables -A FORWARD -i %i -o %i -s 8.20.30.0/24 -d 8.20.30.0/24 -j DROP; iptables -A FORWARD -i %i -o $DEV -j ACCEPT; iptables -A FORWARD -i $DEV -o %i -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -A POSTROUTING -s 8.20.30.0/24 -o $DEV -j MASQUERADE" >> "$CONFIG"
    echo "PostDown = iptables -D FORWARD -i %i -o %i -s 8.20.30.0/24 -d 8.20.30.0/24 -j DROP; iptables -D FORWARD -i %i -o $DEV -j ACCEPT; iptables -D FORWARD -i $DEV -o %i -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -D POSTROUTING -s 8.20.30.0/24 -o $DEV -j MASQUERADE" >> "$CONFIG"
    echo "Jc = ${ENCRYPT_PARAMS[Jc]}" >> "$CONFIG"
    echo "Jmin = ${ENCRYPT_PARAMS[Jmin]}" >> "$CONFIG"
    echo "Jmax = ${ENCRYPT_PARAMS[Jmax]}" >> "$CONFIG"
    echo "S1 = ${ENCRYPT_PARAMS[S1]}" >> "$CONFIG"
    echo "S2 = ${ENCRYPT_PARAMS[S2]}" >> "$CONFIG"
    echo "S3 = ${ENCRYPT_PARAMS[S3]}" >> "$CONFIG"
    echo "S4 = ${ENCRYPT_PARAMS[S4]}" >> "$CONFIG"
    echo "H1 = ${ENCRYPT_PARAMS[H1]}" >> "$CONFIG"
    echo "H2 = ${ENCRYPT_PARAMS[H2]}" >> "$CONFIG"
    echo "H3 = ${ENCRYPT_PARAMS[H3]}" >> "$CONFIG"
    echo "H4 = ${ENCRYPT_PARAMS[H4]}" >> "$CONFIG"
    echo "I1 = ${ENCRYPT_PARAMS[I1]}" >> "$CONFIG"
    echo "I2 = ${ENCRYPT_PARAMS[I2]}" >> "$CONFIG"
    echo "I3 = ${ENCRYPT_PARAMS[I3]}" >> "$CONFIG"
    echo "I4 = ${ENCRYPT_PARAMS[I4]}" >> "$CONFIG"
    echo "I5 = ${ENCRYPT_PARAMS[I5]}" >> "$CONFIG"
    echo "HeaderProtectionKey = $HEADPRKEY" >> "$CONFIG"
    echo "ContentPaddingAddition = ${ENCRYPT_PARAMS[ContentPaddingAddition]}" >> "$CONFIG"
    echo "RekeyAfterTime = ${ENCRYPT_PARAMS[RekeyAfterTime]}" >> "$CONFIG"
    echo "RekeyTimeout = ${ENCRYPT_PARAMS[RekeyTimeout]}" >> "$CONFIG"
    echo "RejectAfterTime = ${ENCRYPT_PARAMS[RejectAfterTime]}" >> "$CONFIG"
    echo "KeepaliveTimeout = ${ENCRYPT_PARAMS[KeepaliveTimeout]}" >> "$CONFIG"
    echo "MaxHandshakeAttempts = ${ENCRYPT_PARAMS[MaxHandshakeAttempts]}" >> "$CONFIG"
    echo "RandomTrailers = ${ENCRYPT_PARAMS[RandomTrailers]}" >> "$CONFIG"
    echo "DisableCookies = ${ENCRYPT_PARAMS[DisableCookies]}" >> "$CONFIG"
    echo >> "$CONFIG"
    echo "[Peer]#client888" >> "$CONFIG"
    echo "PresharedKey = $PRECL" >> "$CONFIG"
    echo "PublicKey = $PUBCL" >> "$CONFIG"
    echo "AllowedIPs = 8.20.30.2/32" >> "$CONFIG"
    echo >> "$CONFIG"
}

function workdirectories () {
    mkdir -p "/home/$1/user_configs"
    mkdir -p "/home/$1/user_configs/client888"
    mkdir -p "/home/$1/config_files"
    cp /etc/amnezia/amneziawg/awg0.conf "/home/$1/config_files/"

    local CONFIG="/home/$1/config_files/client.conf"
    local PUBSERV=$(cat publickey.server)
    local PRIVCL=$(cat privatekey.client888)
    local PRECL=$(cat presharedkey.client888)
    local HEADPRKEY=$(cat header.protection.key)
    local -A ENCRYPT_PARAMS
    local key value

    create_encrypt_config || return 1

    while IFS='=' read -r key value; do
        key="${key//[[:space:]]/}"

        # Skip empty lines and comments
        [[ -z "$key" || "$key" == \#* ]] && continue

        # Remove leading whitespace from value
        value="${value#"${value%%[![:space:]]*}"}"

        # Remove trailing whitespace from value
        value="${value%"${value##*[![:space:]]}"}"

        ENCRYPT_PARAMS["$key"]="$value"

    done < "encrypt.conf"

    echo "[Interface]" > "$CONFIG"
    echo "PrivateKey = $PRIVCL" >> "$CONFIG"
    echo "Address = 8.20.30.2/32" >> "$CONFIG"
    echo "DNS = 1.1.1.1" >> "$CONFIG"
    echo "Jc = ${ENCRYPT_PARAMS[Jc]}" >> "$CONFIG"
    echo "Jmin = ${ENCRYPT_PARAMS[Jmin]}" >> "$CONFIG"
    echo "Jmax = ${ENCRYPT_PARAMS[Jmax]}" >> "$CONFIG"
    echo "S1 = ${ENCRYPT_PARAMS[S1]}" >> "$CONFIG"
    echo "S2 = ${ENCRYPT_PARAMS[S2]}" >> "$CONFIG"
    echo "S3 = ${ENCRYPT_PARAMS[S3]}" >> "$CONFIG"
    echo "S4 = ${ENCRYPT_PARAMS[S4]}" >> "$CONFIG"
    echo "H1 = ${ENCRYPT_PARAMS[H1]}" >> "$CONFIG"
    echo "H2 = ${ENCRYPT_PARAMS[H2]}" >> "$CONFIG"
    echo "H3 = ${ENCRYPT_PARAMS[H3]}" >> "$CONFIG"
    echo "H4 = ${ENCRYPT_PARAMS[H4]}" >> "$CONFIG"
    echo "I1 = ${ENCRYPT_PARAMS[I1]}" >> "$CONFIG"
    echo "I2 = ${ENCRYPT_PARAMS[I2]}" >> "$CONFIG"
    echo "I3 = ${ENCRYPT_PARAMS[I3]}" >> "$CONFIG"
    echo "I4 = ${ENCRYPT_PARAMS[I4]}" >> "$CONFIG"
    echo "I5 = ${ENCRYPT_PARAMS[I5]}" >> "$CONFIG"
    echo "HeaderProtectionKey = $HEADPRKEY" >> "$CONFIG"
    echo "ContentPaddingAddition = ${ENCRYPT_PARAMS[ContentPaddingAddition]}" >> "$CONFIG"
    echo "RekeyAfterTime = ${ENCRYPT_PARAMS[RekeyAfterTime]}" >> "$CONFIG"
    echo "RekeyTimeout = ${ENCRYPT_PARAMS[RekeyTimeout]}" >> "$CONFIG"
    echo "RejectAfterTime = ${ENCRYPT_PARAMS[RejectAfterTime]}" >> "$CONFIG"
    echo "KeepaliveTimeout = ${ENCRYPT_PARAMS[KeepaliveTimeout]}" >> "$CONFIG"
    echo "MaxHandshakeAttempts = ${ENCRYPT_PARAMS[MaxHandshakeAttempts]}" >> "$CONFIG"
    echo "RandomTrailers = ${ENCRYPT_PARAMS[RandomTrailers]}" >> "$CONFIG"
    echo "DisableCookies = ${ENCRYPT_PARAMS[DisableCookies]}" >> "$CONFIG"
    echo >> "$CONFIG"
    echo "[Peer]" >> "$CONFIG"
    echo "PresharedKey = $PRECL" >> "$CONFIG"
    echo "PublicKey = $PUBSERV" >> "$CONFIG"
    echo "Endpoint = $2" >> "$CONFIG"
    echo "AllowedIPs = 0.0.0.0/0, ::/0" >> "$CONFIG"
    echo "PersistentKeepalive = 20" >> "$CONFIG"

    cp "/home/$1/config_files/client.conf" "/home/$1/user_configs/client888/"

    echo "$2" >> /etc/amnezia/amneziawg/keys/ipaddress
}

config "$_USERNAME" || exit 1
workdirectories "$_USERNAME" "$_IPADDRESS" || exit 1

systemctl enable awg-quick@awg0.service
systemctl start awg-quick@awg0.service

mkdir /root/bin/
touch /root/bin/set_tc.sh
touch /root/bin/speed_limit

echo "30" >> /root/bin/speed_limit

cat << 'EOF' > /root/bin/set_tc.sh
#!/bin/bash

_SPEED_LIMIT=$(cat /root/bin/speed_limit)
_QUANTUM=$(( ${_SPEED_LIMIT} * 125000 / 200 ))

tc qdisc del dev awg0 root 2>/dev/null
#tc qdisc del dev awg0 ingress 2>/dev/null
#tc qdisc del dev ifb0 root 2>/dev/null

#modprobe ifb 2>/dev/null
#ip link add ifb0 type ifb 2>/dev/null
#ip link set ifb0 up 2>/dev/null

tc qdisc add dev awg0 root handle 1: htb default 12 r2q 256
tc class add dev awg0 parent 1: classid 1:1 htb rate 1000mbit ceil 1000mbit quantum 40000

#tc qdisc add dev awg0 ingress
#tc filter add dev awg0 parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev ifb0

#tc qdisc add dev ifb0 root handle 2: htb default 10
#tc class add dev ifb0 parent 2: classid 2:1 htb rate 1000mbit
#tc class add dev ifb0 parent 2:1 classid 2:1000 htb rate 1000mbit

for ip in {2..253}; do
    CLASSID=$ip
    tc class add dev awg0 parent 1:1 classid 1:$CLASSID htb rate "${_SPEED_LIMIT}"mbit ceil "${_SPEED_LIMIT}"mbit quantum ${_QUANTUM}
    tc filter add dev awg0 protocol ip parent 1:0 prio 1 u32 match ip dst 8.20.30.$ip flowid 1:$CLASSID
    
    #tc class add dev ifb0 parent 2:1 classid 2:$CLASSID htb rate "${_SPEED_LIMIT}"mbit ceil "${_SPEED_LIMIT}"mbit
    #tc filter add dev ifb0 parent 2: protocol ip u32 match ip src 8.20.30.$ip flowid 2:$CLASSID
done
EOF

cat << EOF > /root/bin/tc-stop.sh
#!/bin/bash

tc qdisc del dev awg0 root 2>/dev/null
#tc qdisc del dev awg0 ingress 2>/dev/null
#tc qdisc del dev ifb0 root 2>/dev/null
#ip link del ifb0 2>/dev/null
EOF

chmod 755 /root/bin/set_tc.sh
chmod 755 /root/bin/tc-stop.sh

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

function crontab_install () {
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

function edit_crontab () {
    echo Installation Done, Reboot system!
    read -p "Running crontab -e. Press enter to continue: "
    crontab -e
}

crontab_install

cp /root/awgm.sh /usr/local/bin/awgm

chmod 777 /usr/local/bin/awgm

# Zabbix

sudo apt install -y zabbix-agent

cat <<EOF > /usr/local/bin/ifstat_to_zabbix.sh
#!/bin/bash

INTERFACE=awg0
OUTPUT_FILE="/var/lib/zabbix/network_speed.txt"

RX_TX=\$(ifstat -i \$INTERFACE -b 1 1 | tail -n 1 | awk '{print \$1, \$2}')

echo "\$RX_TX" > "\$OUTPUT_FILE"

EOF

chmod 755 /usr/local/bin/ifstat_to_zabbix.sh
mkdir -p /var/lib/zabbix
mkdir -p /etc/zabbix/zabbix_agentd.d
mkdir -p /var/log/zabbix/
touch /var/log/zabbix/zabbix_agentd.log
chmod 777 /var/log/zabbix/zabbix_agentd.log

sudo install -o root -g zabbix -m 640 /dev/null /etc/zabbix/zabbix_agentd.psk
sudo sh -c 'openssl rand -hex 32 > /etc/zabbix/zabbix_agentd.psk'
sudo chown root:zabbix /etc/zabbix/zabbix_agentd.psk
sudo chmod 640 /etc/zabbix/zabbix_agentd.psk

sudo systemctl enable zabbix-agent --now

#reboot after installation