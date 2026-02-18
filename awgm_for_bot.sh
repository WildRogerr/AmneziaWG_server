#!/bin/bash

cd /etc/amnezia/amneziawg/keys

function main () {
    while true
    do
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
        echo "  10) Configs. Edit Encrypt Value"
        echo "  11) Configs. Edit IP address"
        echo "  12) Restart AmneziaWG"
        echo "  13) Stop AmneziaWG"
        echo "  14) Start AmneziaWG"
        echo "  15) Change Speed Limit For Users"
        echo "  16) Speed Limit Off"
        echo "  17) Speed Limit On"
        echo "  18) Owl VPN Off"
        echo "  19) Owl VPN On"
        echo "  20) Show Owl VPN Status"
        echo "  0) Exit"
        echo
        read -p "Select an option [0-20]: "

        if [[ "$REPLY" = "1" ]]; then
            ls -l /home/vpnserver/user_configs

        elif [[ "$REPLY" = "2" ]]; then
            client_name_check
            local CL_NAME_CHECK="$_RESULT"
            show_client_config "$CL_NAME_CHECK"

        elif [[ "$REPLY" = "3" ]]; then
            client_name
            local CL_NAME="$_RESULT"
            generate_config "$CL_NAME"
            copy_config_files "$CL_NAME"
            echo
            echo "Done!"
            echo

        elif [[ "$REPLY" = "4" ]]; then
            client_name_check
            local CL_NAME_CHECK1="$_RESULT"
            stop_config "$CL_NAME_CHECK1"
            echo
            echo "Done!"
            echo

        elif [[ "$REPLY" = "5" ]]; then
            client_name_check
            local CL_NAME_CHECK2="$_RESULT"
            start_config "$CL_NAME_CHECK2"
            echo
            echo "Done!"
            echo
            
        elif [[ "$REPLY" = "6" ]]; then
            client_name_check
            local CL_NAME_CHECK3="$_RESULT"
            delete_config_files "$CL_NAME_CHECK3"
            echo
            echo "Done!"
            echo

        elif [[ "$REPLY" = "7" ]]; then
            systemctl status awg-quick@awg0.service

        elif [[ "$REPLY" = "8" ]]; then
            nano /etc/amnezia/amneziawg/awg0.conf

        elif [[ "$REPLY" = "9" ]]; then
            systemctl reload awg-quick@awg0
            echo
            echo "Done!"
            echo

        elif [[ "$REPLY" = "10" ]]; then
            read -p "Enter new Jc value or enter 0 to return to main menu: " JC
            if [[ "$JC" = "0" ]]; then
                :
            else
                read -p "Enter new Jmin value: " JMIN
                read -p "Enter new Jmax value: " JMAX
                read -p "Enter new S1 value: " S1
                read -p "Enter new S2 value: " S2
                read -p "Enter new I1 value: " I1
                edit_encrypt_value "$JC" "$JMIN" "$JMAX" "$S1" "$S2" "$I1"
                echo
                echo "Done!"
                echo
            fi

        elif [[ "$REPLY" = "11" ]]; then
            read -p "Enter new IP address (IP address:Port) or enter 0 to return to main menu: " IP
            if [[ "$IP" = "0" ]]; then
                :
            else
                edit_ip_address "$IP"
                echo
                echo "Done!"
                echo
            fi

        elif [[ "$REPLY" = "12" ]]; then
            systemctl restart awg-quick@awg0.service
            echo
            echo "Done!"
            echo

        elif [[ "$REPLY" = "13" ]]; then
            systemctl stop awg-quick@awg0.service
            echo
            echo "Done!"
            echo

        elif [[ "$REPLY" = "14" ]]; then
            systemctl start awg-quick@awg0.service
            echo
            echo "Done!"
            echo

        elif [[ "$REPLY" = "15" ]]; then
            local SPEED_LIMIT=$(cat /root/bin/speed_limit)
            echo Current speed limit is ${SPEED_LIMIT}mbit.
            read -p "Enter new speed limit: " _VALUE
            change_speed_limit "$_VALUE"
            tc qdisc del dev awg0 root
            systemctl restart set-tc
            echo
            echo "Done!"
            echo

        elif [[ "$REPLY" = "16" ]]; then
            systemctl stop set-tc
			systemctl disable set-tc
            tc qdisc del dev awg0 root
            echo
            echo "Done!"
            echo

        elif [[ "$REPLY" = "17" ]]; then
            systemctl enable set-tc
			systemctl start set-tc
            echo
            echo "Done!"
            echo

        elif [[ "$REPLY" = "18" ]]; then
            systemctl stop owl-vpn
            echo
            echo "Done!"
            echo

        elif [[ "$REPLY" = "19" ]]; then
            systemctl start owl-vpn
            echo
            echo "Done!"
            echo

        elif [[ "$REPLY" = "20" ]]; then
            systemctl status owl-vpn
            echo
            echo "Done!"
            echo

        elif [[ "$REPLY" = "0" ]]; then
            echo
            echo Exit
            break

        else 
            echo Enter Number: 0-20!
            echo
        fi
    done
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

function copy_config_files () {
    local PUBSERV=$(cat publickey.server)
    local PRIVCL=$(cat privatekey.$1)
    local PRECL=$(cat presharedkey.$1)
    local IPADDRESS=$(cat ipaddress)
    local IP=$(ls -l /home/vpnserver/user_configs | wc -l)

    echo "[Interface]" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "PrivateKey = $PRIVCL" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "Address = 8.20.30.$IP/32" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "DNS = 1.1.1.1" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "Jc = 5" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "Jmin = 40" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "Jmax = 70" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "S1 = 8" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "S2 = 5" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "H1 = 1106457265" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "H2 = 249455488" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "H3 = 1209847463" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "H4 = 1646644382" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "I1 = <b 0xc70000000108ce1bf31eec7d93360000449e227e4596ed7f75c4d35ce31880b4133107c822c6355b51f0d7c1bba96d5c210a48aca01885fed0871cfc37d59137d73b506dc013bb4a13c060ca5b04b7ae215af71e37d6e8ff1db235f9fe0c25cb8b492471054a7c8d0d6077d430d07f6e87a8699287f6e69f54263c7334a8e144a29851429bf2e350e519445172d36953e96085110ce1fb641e5efad42c0feb4711ece959b72cc4d6f3c1e83251adb572b921534f6ac4b10927167f41fe50040a75acef62f45bded67c0b45b9d655ce374589cad6f568b8475b2e8921ff98628f86ff2eb5bcce6f3ddb7dc89e37c5b5e78ddc8d93a58896e530b5f9f1448ab3b7a1d1f24a63bf981634f6183a21af310ffa52e9ddf5521561760288669de01a5f2f1a4f922e68d0592026bbe4329b654d4f5d6ace4f6a23b8560b720a5350691c0037b10acfac9726add44e7d3e880ee6f3b0d6429ff33655c297fee786bb5ac032e48d2062cd45e305e6d8d8b82bfbf0fdbc5ec09943d1ad02b0b5868ac4b24bb10255196be883562c35a713002014016b8cc5224768b3d330016cf8ed9300fe6bf39b4b19b3667cddc6e7c7ebe4437a58862606a2a66bd4184b09ab9d2cd3d3faed4d2ab71dd821422a9540c4c5fa2a9b2e6693d411a22854a8e541ed930796521f03a54254074bc4c5bca152a1723260e7d70a24d49720acc544b41359cfc252385bda7de7d05878ac0ea0343c77715e145160e6562161dfe2024846dfda3ce99068817a2418e66e4f37dea40a21251c8a034f83145071d93baadf050ca0f95dc9ce2338fb082d64fbc8faba905cec66e65c0e1f9b003c32c943381282d4ab09bef9b6813ff3ff5118623d2617867e25f0601df583c3ac51bc6303f79e68d8f8de4b8363ec9c7728b3ec5fcd5274edfca2a42f2727aa223c557afb33f5bea4f64aeb252c0150ed734d4d8eccb257824e8e090f65029a3a042a51e5cc8767408ae07d55da8507e4d009ae72c47ddb138df3cab6cc023df2532f88fb5a4c4bd917fafde0f3134be09231c389c70bc55cb95a779615e8e0a76a2b4d943aabfde0e394c985c0cb0376930f92c5b6998ef49ff4a13652b787503f55c4e3d8eebd6e1bc6db3a6d405d8405bd7a8db7cefc64d16e0d105a468f3d33d29e5744a24c4ac43ce0eb1bf6b559aed520b91108cda2de6e2c4f14bc4f4dc58712580e07d217c8cca1aaf7ac04bab3e7b1008b966f1ed4fba3fd93a0a9d3a27127e7aa587fbcc60d548300146bdc126982a58ff5342fc41a43f83a3d2722a26645bc961894e339b953e78ab395ff2fb854247ad06d446cc2944a1aefb90573115dc198f5c1efbc22bc6d7a74e41e666a643d5f85f57fde81b87ceff95353d22ae8bab11684180dd142642894d8dc34e402f802c2fd4a73508ca99124e428d67437c871dd96e506ffc39c0fc401f666b437adca41fd563cbcfd0fa22fbbf8112979c4e677fb533d981745cceed0fe96da6cc0593c430bbb71bcbf924f70b4547b0bb4d41c94a09a9ef1147935a5c75bb2f721fbd24ea6a9f5c9331187490ffa6d4e34e6bb30c2c54a0344724f01088fb2751a486f425362741664efb287bce66c4a544c96fa8b124d3c6b9eaca170c0b530799a6e878a57f402eb0016cf2689d55c76b2a91285e2273763f3afc5bc9398273f5338a06d>" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo -e \ >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "[Peer]" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "PresharedKey = $PRECL" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "PublicKey = $PUBSERV" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "Endpoint = $IPADDRESS" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
    echo "AllowedIPs = 0.0.0.0/0, ::/0" >> /home/vpnserver/user_configs/$1/owlvpn.kz.conf
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

function edit_encrypt_value () {
    find /home/vpnserver/user_configs -type f -name "owlvpn.kz.conf" -exec sed -i "5{s/^\(.\{5\}\).*/\1$1/}" {} \;
    find /home/vpnserver/user_configs -type f -name "owlvpn.kz.conf" -exec sed -i "6{s/^\(.\{7\}\).*/\1$2/}" {} \;
    find /home/vpnserver/user_configs -type f -name "owlvpn.kz.conf" -exec sed -i "7{s/^\(.\{7\}\).*/\1$3/}" {} \;
    find /home/vpnserver/user_configs -type f -name "owlvpn.kz.conf" -exec sed -i "8{s/^\(.\{5\}\).*/\1$4/}" {} \;
    find /home/vpnserver/user_configs -type f -name "owlvpn.kz.conf" -exec sed -i "9{s/^\(.\{5\}\).*/\1$5/}" {} \;
    find /home/vpnserver/user_configs -type f -name "owlvpn.kz.conf" -exec sed -i "14{s/^\(.\{5\}\).*/\1$6/}" {} \;
}

function edit_ip_address () {
    find /home/vpnserver/user_configs -type f -name "owlvpn.kz.conf" -exec sed -i "19{s/^\(.\{11\}\).*/\1$1/}" {} \;
    echo $1 > /etc/amnezia/amneziawg/keys/ipaddress
}

function change_speed_limit () {
    > /root/bin/speed_limit
    echo $1 >> /root/bin/speed_limit
}

main