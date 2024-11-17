#!/bin/bash

cd /etc/amnezia/amneziawg/keys

generate_config () {
    echo Configs list:
    ls -l /home/vpnserver/user_configs
    read -p "Enter Client Name: "
    umask 077
    awg genkey | tee privatekey.$REPLY | awg pubkey > publickey.$REPLY
    awg genpsk > presharedkey.$REPLY
    local PUBCL=$(cat publickey.$REPLY)
    local PRECL=$(cat presharedkey.$REPLY)
    mkdir /home/vpnserver/user_configs/$REPLY
    touch /home/vpnserver/user_configs/$REPLY/amneziawg.kz.conf
    local IP=$(ls -l /home/vpnserver/user_configs | wc -l)
    echo "[Peer]#$REPLY" >> /etc/amnezia/amneziawg/awg0.conf
    echo "PresharedKey = $PRECL" >> /etc/amnezia/amneziawg/awg0.conf
    echo "PublicKey = $PUBCL" >> /etc/amnezia/amneziawg/awg0.conf
    echo "AllowedIPs = 8.20.30.$IP/32" >> /etc/amnezia/amneziawg/awg0.conf
    echo -e \ >> /etc/amnezia/amneziawg/awg0.conf
    systemctl reload awg-quick@awg0
    _RESULT=$REPLY
}

stop_config () {
    echo Configs list:
    ls -l /home/vpnserver/user_configs
    read -p "Enter Client Name: "
        local CLIENT=$(ls /home/vpnserver/user_configs | grep $REPLY)
    if [[ "$REPLY" = "$CLIENT" ]]; then
        local NUM=$(grep -n $REPLY /etc/amnezia/amneziawg/awg0.conf | cut -d: -f1)
        local NUM1="$NUM"s
        local NUM2=$(($NUM + 1))s
        local NUM3=$(($NUM + 2))s
        local NUM4=$(($NUM + 3))s
        sed -i "$NUM1/^/#/" /etc/amnezia/amneziawg/awg0.conf
        sed -i "$NUM2/^/#/" /etc/amnezia/amneziawg/awg0.conf
        sed -i "$NUM3/^/#/" /etc/amnezia/amneziawg/awg0.conf
        sed -i "$NUM4/^/#/" /etc/amnezia/amneziawg/awg0.conf
        systemctl reload awg-quick@awg0
    else
        echo Enter name, that already exists!
        stop_config
    fi
}

start_config () {
    echo Configs list:
    ls -l /home/vpnserver/user_configs
    read -p "Enter Client Name: "
        local CLIENT=$(ls /home/vpnserver/user_configs | grep $REPLY)
    if [[ "$REPLY" = "$CLIENT" ]]; then
        local NUM=$(grep -n $REPLY /etc/amnezia/amneziawg/awg0.conf | cut -d: -f1)
        local NUM1="$NUM"s
        local NUM2=$(($NUM + 1))s
        local NUM3=$(($NUM + 2))s
        local NUM4=$(($NUM + 3))s
        sed -i "$NUM1/^#//" /etc/amnezia/amneziawg/awg0.conf
        sed -i "$NUM2/^#//" /etc/amnezia/amneziawg/awg0.conf
        sed -i "$NUM3/^#//" /etc/amnezia/amneziawg/awg0.conf
        sed -i "$NUM4/^#//" /etc/amnezia/amneziawg/awg0.conf
        systemctl reload awg-quick@awg0
    else
        echo Enter name, that already exists!
        start_config
    fi
}

delete_config () {
    echo Configs list:
    ls -l /home/vpnserver/user_configs
    read -p "Enter Client Name: "
        local CLIENT=$(ls /home/vpnserver/user_configs | grep $REPLY)
    if [[ "$REPLY" = "$CLIENT" ]]; then
        _RESULT=$REPLY
    else
        echo Enter name, that already exists!
        delete_config
    fi
}

сopy_config_files () {
    local PUBSERV=$(cat publickey.server)
    local PRIVCL=$(cat privatekey.$1)
    local PRECL=$(cat presharedkey.$1)
    local IP=$(ls -l /home/vpnserver/user_configs | wc -l)

    echo "[Interface]" >> /home/vpnserver/user_configs/$1/amneziawg.kz.conf
    echo "PrivateKey = $PRIVCL" >> /home/vpnserver/user_configs/$1/amneziawg.kz.conf
    echo "Address = 8.20.30.$IP/32" >> /home/vpnserver/user_configs/$1/amneziawg.kz.conf
    echo "DNS = 1.1.1.1" >> /home/vpnserver/user_configs/$1/amneziawg.kz.conf
    echo "Jc = 4" >> /home/vpnserver/user_configs/$1/amneziawg.kz.conf
    echo "Jmin = 40" >> /home/vpnserver/user_configs/$1/amneziawg.kz.conf
    echo "Jmax = 70" >> /home/vpnserver/user_configs/$1/amneziawg.kz.conf
    echo "S1 = 68" >> /home/vpnserver/user_configs/$1/amneziawg.kz.conf
    echo "S2 = 149" >> /home/vpnserver/user_configs/$1/amneziawg.kz.conf
    echo "H1 = 1106457265" >> /home/vpnserver/user_configs/$1/amneziawg.kz.conf
    echo "H2 = 249455488" >> /home/vpnserver/user_configs/$1/amneziawg.kz.conf
    echo "H3 = 1209847463" >> /home/vpnserver/user_configs/$1/amneziawg.kz.conf
    echo "H4 = 1646644382" >> /home/vpnserver/user_configs/$1/amneziawg.kz.conf
    echo -e \ >> /home/vpnserver/user_configs/$1/amneziawg.kz.conf
    echo "[Peer]" >> /home/vpnserver/user_configs/$1/amneziawg.kz.conf
    echo "PresharedKey = $PRECL" >> /home/vpnserver/user_configs/$1/amneziawg.kz.conf
    echo "PublicKey = $PUBSERV" >> /home/vpnserver/user_configs/$1/amneziawg.kz.conf
    echo "Endpoint = 91.147.92.228:1984" >> /home/vpnserver/user_configs/$1/amneziawg.kz.conf
    echo "AllowedIPs = 0.0.0.0/0" >> /home/vpnserver/user_configs/$1/amneziawg.kz.conf
    echo "PersistentKeepalive = 20" >> /home/vpnserver/user_configs/$1/amneziawg.kz.conf
}

delete_config_files () {
    echo "Are you sure?"
    read -p "enter "yes" or "no": "

    if [[ "$REPLY" = "yes" ]]; then
        rm publickey.$1
        rm privatekey.$1
        rm presharedkey.$1
        rm -R /home/vpnserver/user_configs/$1
        sed -i "/$1/,+4d" /etc/amnezia/amneziawg/awg0.conf
        systemctl reload awg-quick@awg0
    elif [[ "$REPLY" = "no" ]]; then
        echo "Config files is not deleted."      
    else 
        delete_config_files
    fi
}

enter_number () {
    echo "AWG Manager"
    echo "  1) Client List"
    echo "  2) Generate Config"
    echo "  3) Stop Config"
    echo "  4) Start Config"
    echo "  5) Delete Config"
    echo "  6) Show AmneziaWG daemon"
    echo "  7) Start AmneziaWG"
    echo "  8) Stop AmneziaWG"
    echo "  9) Restart AmneziaWG"
    echo "  10) Open Server Config"
    echo "  0) Exit"
    read -p "Select an option [0-10]: "

	if [[ "$REPLY" = "1" ]]; then
        ls -l /home/vpnserver/user_configs
        enter_number

    elif [[ "$REPLY" = "2" ]]; then
        generate_config
        local CLIENT_NAME="$_RESULT"
        сopy_config_files "$CLIENT_NAME"
        echo "Done!"

    elif [[ "$REPLY" = "3" ]]; then
        stop_config
        echo "Done!"

    elif [[ "$REPLY" = "4" ]]; then
        start_config
        echo "Done!"
        
    elif [[ "$REPLY" = "5" ]]; then
        delete_config
        local CLIENT_NAME="$_RESULT"
        delete_config_files "$CLIENT_NAME"

    elif [[ "$REPLY" = "6" ]]; then
        systemctl status awg-quick@awg0.service
        enter_number

    elif [[ "$REPLY" = "7" ]]; then
        systemctl start awg-quick@awg0.service
        enter_number

    elif [[ "$REPLY" = "8" ]]; then
        systemctl stop awg-quick@awg0.service
        enter_number

    elif [[ "$REPLY" = "9" ]]; then
        systemctl restart awg-quick@awg0.service
        enter_number

    elif [[ "$REPLY" = "10" ]]; then
        nano /etc/amnezia/amneziawg/awg0.conf

    elif [[ "$REPLY" = "0" ]]; then
        echo Exit

    else 
        echo Enter Number: 0-10!
	    enter_number

	fi
}

enter_number