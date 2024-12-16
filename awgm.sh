#!/bin/bash

cd /etc/amnezia/amneziawg/keys

function main () {
    echo "-------------------------------------------------------------"
    echo "AWG Manager"
    echo "-------------------------------------------------------------"
    echo
    echo "  1) Clients List"
    echo "  2) Show Client Config"
    echo "  3) Generate Client Config"
    echo "  4) Stop Client Config"
    echo "  5) Start Client Config"
    echo "  6) Delete Client Config"
    echo "  7) Show AmneziaWG Status"
    echo "  8) Open AmneziaWG Config"
    echo "  9) Reload AmneziaWG Config"
    echo "  10) Restart AmneziaWG"
    echo "  11) Stop AmneziaWG"
    echo "  12) Start AmneziaWG"
    echo "  0) Exit"
    echo
    read -p "Select an option [0-12]: "

	if [[ "$REPLY" = "1" ]]; then
        ls -l /home/vpnserver/user_configs
        main

    elif [[ "$REPLY" = "2" ]]; then
        client_name_check
        local CL_NAME_CHECK="$_RESULT"
        show_client_config "$CL_NAME_CHECK"
        main

    elif [[ "$REPLY" = "3" ]]; then
        client_name
        local CL_NAME="$_RESULT"
        generate_config "$CL_NAME"
        сopy_config_files "$CL_NAME"
        echo
        echo "Done!"
        main

    elif [[ "$REPLY" = "4" ]]; then
        client_name_check
        local CL_NAME_CHECK1="$_RESULT"
        stop_config "$CL_NAME_CHECK1"
        echo
        echo "Done!"
        main

    elif [[ "$REPLY" = "5" ]]; then
        client_name_check
        local CL_NAME_CHECK2="$_RESULT"
        start_config "$CL_NAME_CHECK2"
        echo
        echo "Done!"
        main
        
    elif [[ "$REPLY" = "6" ]]; then
        client_name_check
        local CL_NAME_CHECK3="$_RESULT"
        delete_config_files "$CL_NAME_CHECK3"
        echo
        echo "Done!"
        main

    elif [[ "$REPLY" = "7" ]]; then
        systemctl status awg-quick@awg0.service
        main

    elif [[ "$REPLY" = "8" ]]; then
        nano /etc/amnezia/amneziawg/awg0.conf
        main

    elif [[ "$REPLY" = "9" ]]; then
        systemctl reload awg-quick@awg0
        echo
        echo "Done!"
        main

    elif [[ "$REPLY" = "10" ]]; then
        systemctl restart awg-quick@awg0.service
        echo
        echo "Done!"
        main

    elif [[ "$REPLY" = "11" ]]; then
        systemctl stop awg-quick@awg0.service
        echo
        echo "Done!"
        main

    elif [[ "$REPLY" = "12" ]]; then
        systemctl start awg-quick@awg0.service
        echo
        echo "Done!"
        main

    elif [[ "$REPLY" = "0" ]]; then
        echo
        echo Exit

    else 
        echo Enter Number: 0-12!
	    main

	fi
}

function client_name () {
    echo Configs list:
    ls -l /home/vpnserver/user_configs
    read -p "Enter Client Name: "
         local CLIENT=$(ls /home/vpnserver/user_configs | grep $REPLY)
    if [[ "$REPLY" != "$CLIENT" ]]; then
        _RESULT=$REPLY
    else
        echo
        echo Name $REPLY already exists, enter new name.
        echo
        client_name_check
    fi
}

function client_name_check () {
    echo Configs list:
    ls -l /home/vpnserver/user_configs
    read -p "Enter Client Name: "
        local CLIENT=$(ls /home/vpnserver/user_configs | grep $REPLY)
    if [[ "$REPLY" = "$CLIENT" ]]; then
        _RESULT=$REPLY
    else
        echo Enter name, that already exists!
        client_name_check
    fi
}

function show_client_config () {
    echo 
    echo "Config of $1:"
    echo 
    echo "*************************************************************"
    cat /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "*************************************************************"
    echo 
}

function generate_config () {
    umask 077
    awg genkey | tee privatekey.$1 | awg pubkey > publickey.$1
    awg genpsk > presharedkey.$1
    local PUBCL=$(cat publickey.$1)
    local PRECL=$(cat presharedkey.$1)
    mkdir /home/vpnserver/user_configs/$1
    touch /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    local IP=$(ls -l /home/vpnserver/user_configs | wc -l)
    echo "[Peer]#$1" >> /etc/amnezia/amneziawg/awg0.conf
    echo "PresharedKey = $PRECL" >> /etc/amnezia/amneziawg/awg0.conf
    echo "PublicKey = $PUBCL" >> /etc/amnezia/amneziawg/awg0.conf
    echo "AllowedIPs = 8.20.30.$IP/32" >> /etc/amnezia/amneziawg/awg0.conf
    echo -e \ >> /etc/amnezia/amneziawg/awg0.conf
    systemctl reload awg-quick@awg0
}

function stop_config () {
    local NUM=$(grep -n $1 /etc/amnezia/amneziawg/awg0.conf | cut -d: -f1)
    local NUM1="$NUM"s
    local NUM2=$(($NUM + 1))s
    local NUM3=$(($NUM + 2))s
    local NUM4=$(($NUM + 3))s
    sed -i "$NUM1/^/#/" /etc/amnezia/amneziawg/awg0.conf
    sed -i "$NUM2/^/#/" /etc/amnezia/amneziawg/awg0.conf
    sed -i "$NUM3/^/#/" /etc/amnezia/amneziawg/awg0.conf
    sed -i "$NUM4/^/#/" /etc/amnezia/amneziawg/awg0.conf
    systemctl reload awg-quick@awg0
}

function start_config () {
    local NUM=$(grep -n $1 /etc/amnezia/amneziawg/awg0.conf | cut -d: -f1)
    local NUM1="$NUM"s
    local NUM2=$(($NUM + 1))s
    local NUM3=$(($NUM + 2))s
    local NUM4=$(($NUM + 3))s
    sed -i "$NUM1/^#//" /etc/amnezia/amneziawg/awg0.conf
    sed -i "$NUM2/^#//" /etc/amnezia/amneziawg/awg0.conf
    sed -i "$NUM3/^#//" /etc/amnezia/amneziawg/awg0.conf
    sed -i "$NUM4/^#//" /etc/amnezia/amneziawg/awg0.conf
    systemctl reload awg-quick@awg0
}

function сopy_config_files () {
    local PUBSERV=$(cat publickey.server)
    local PRIVCL=$(cat privatekey.$1)
    local PRECL=$(cat presharedkey.$1)
    local IP=$(ls -l /home/vpnserver/user_configs | wc -l)

    echo "[Interface]" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "PrivateKey = $PRIVCL" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "Address = 8.20.30.$IP/32" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "DNS = 1.1.1.1" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "Jc = 4" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "Jmin = 40" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "Jmax = 70" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "S1 = 68" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "S2 = 149" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "H1 = 1106457265" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "H2 = 249455488" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "H3 = 1209847463" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "H4 = 1646644382" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo -e \ >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "[Peer]" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "PresharedKey = $PRECL" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "PublicKey = $PUBSERV" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "Endpoint = 91.147.92.228:1984" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "AllowedIPs = 0.0.0.0/0" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "PersistentKeepalive = 20" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
}

function delete_config_files () {
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

main