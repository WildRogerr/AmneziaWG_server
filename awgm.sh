#!/bin/bash

cd /etc/amnezia/amneziawg/keys

function main () {
    
    local _REPLY JC JMIN JMAX S1 S2 I1 IP _VALUE
    
    while true
    do
        echo "-------------------------------------------------------------"
        echo "  AWG Manager"
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
        echo "  0) Exit"
        echo
        read -p "  Select an option [0-17]: " _REPLY

        if [[ "$_REPLY" = "1" ]]; then
            ls -l /home/vpnserver/user_configs

        elif [[ "$_REPLY" = "2" ]]; then
            client_name_check
            local CL_NAME_CHECK="$_RESULT"
            show_client_config "$CL_NAME_CHECK"

        elif [[ "$_REPLY" = "3" ]]; then
            client_name
            local CL_NAME="$_RESULT"
            generate_config "$CL_NAME"
            copy_config_files "$CL_NAME"
            echo
            echo "Done!"
            echo

        elif [[ "$_REPLY" = "4" ]]; then
            client_name_check
            local CL_NAME_CHECK1="$_RESULT"
            stop_config "$CL_NAME_CHECK1"
            echo
            echo "Done!"
            echo

        elif [[ "$_REPLY" = "5" ]]; then
            client_name_check
            local CL_NAME_CHECK2="$_RESULT"
            start_config "$CL_NAME_CHECK2"
            echo
            echo "Done!"
            echo
            
        elif [[ "$_REPLY" = "6" ]]; then
            client_name_check
            local CL_NAME_CHECK3="$_RESULT"
            delete_config_files "$CL_NAME_CHECK3"
            echo
            echo "Done!"
            echo

        elif [[ "$_REPLY" = "7" ]]; then
            systemctl status awg-quick@awg0.service

        elif [[ "$_REPLY" = "8" ]]; then
            nano /etc/amnezia/amneziawg/awg0.conf

        elif [[ "$_REPLY" = "9" ]]; then
            systemctl reload awg-quick@awg0
            echo
            echo "Done!"
            echo

        elif [[ "$_REPLY" = "10" ]]; then
            edit_encrypt_value
            echo
            echo "Done!"
            echo

        elif [[ "$_REPLY" = "11" ]]; then
            read -p "Enter new IP address (IP address:Port) or enter 0 to return to main menu: " IP
            if [[ "$IP" = "0" ]]; then
                :
            else
                edit_ip_address "$IP"
                echo
                echo "Done!"
                echo
            fi

        elif [[ "$_REPLY" = "12" ]]; then
            systemctl restart awg-quick@awg0.service
            echo
            echo "Done!"
            echo

        elif [[ "$_REPLY" = "13" ]]; then
            systemctl stop awg-quick@awg0.service
            echo
            echo "Done!"
            echo

        elif [[ "$_REPLY" = "14" ]]; then
            systemctl start awg-quick@awg0.service
            echo
            echo "Done!"
            echo

        elif [[ "$_REPLY" = "15" ]]; then
            local SPEED_LIMIT=$(cat /root/bin/speed_limit)
            echo Current speed limit is ${SPEED_LIMIT}mbit.
            read -p "Enter new speed limit: " _VALUE
            change_speed_limit "$_VALUE"
            /root/bin/tc-stop.sh
            systemctl restart set-tc
            echo
            echo "Done!"
            echo

        elif [[ "$_REPLY" = "16" ]]; then
            systemctl stop set-tc
			systemctl disable set-tc
            /root/bin/tc-stop.sh
            echo
            echo "Done!"
            echo

        elif [[ "$_REPLY" = "17" ]]; then
            systemctl enable set-tc
			systemctl start set-tc
            echo
            echo "Done!"
            echo

        elif [[ "$_REPLY" = "0" ]]; then
            echo
            echo Exit
            break

        else 
            echo Enter Number: 0-17!
            echo
        fi
    done
}

function client_name () {
    local _REPLY
    echo Configs list:
    ls -l /home/vpnserver/user_configs
    read -p "Enter Client Name: " _REPLY
         local CLIENT=$(ls /home/vpnserver/user_configs | grep "$_REPLY")
    if [[ "$_REPLY" != "$CLIENT" ]]; then
        _RESULT=$_REPLY
    else
        echo
        echo Name "$_REPLY" already exists, enter new name.
        echo
        client_name
    fi
}

function client_name_check () {
    local _REPLY
    echo Configs list:
    ls -l /home/vpnserver/user_configs
    read -p "Enter Client Name: " _REPLY
        local CLIENT=$(ls /home/vpnserver/user_configs | grep "$_REPLY")
    if [[ "$_REPLY" = "$CLIENT" ]]; then
        _RESULT=$_REPLY
    else
        echo Enter name, that already exists!
        client_name_check
    fi
}

function show_client_config () {
    local USER_CONFIG_NAME=$(cat userconfig.name)
    echo 
    echo "Config of $1:"
    echo 
    echo "*************************************************************"
    cat /home/vpnserver/user_configs/$1/$USER_CONFIG_NAME
    echo "*************************************************************"
    echo 
}

function generate_config () {
    local USER_CONFIG_NAME=$(cat userconfig.name)
    umask 077
    awg genkey | tee privatekey.$1 | awg pubkey > publickey.$1
    awg genpsk > presharedkey.$1
    local PUBCL=$(cat publickey.$1)
    local PRECL=$(cat presharedkey.$1)
    mkdir /home/vpnserver/user_configs/$1
    touch /home/vpnserver/user_configs/$1/$USER_CONFIG_NAME
    local IP=$(ls -l /home/vpnserver/user_configs | wc -l)
    echo "[Peer]#$1" >> /etc/amnezia/amneziawg/awg0.conf
    echo "PresharedKey = $PRECL" >> /etc/amnezia/amneziawg/awg0.conf
    echo "PublicKey = $PUBCL" >> /etc/amnezia/amneziawg/awg0.conf
    echo "AllowedIPs = 8.20.30.$IP/32" >> /etc/amnezia/amneziawg/awg0.conf
    echo -e \ >> /etc/amnezia/amneziawg/awg0.conf
    systemctl reload awg-quick@awg0
}

function stop_config () {
    local NUM=$(grep -nFm1 "$1" /etc/amnezia/amneziawg/awg0.conf | cut -d: -f1)

    [[ -z "$NUM" ]] && {
        return 1
    }

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
    local NUM=$(grep -nFm1 "$1" /etc/amnezia/amneziawg/awg0.conf | cut -d: -f1)

    [[ -z "$NUM" ]] && {
        return 1
    }

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
    local USER_CONFIG_NAME=$(cat userconfig.name)
    local CONFIG="/home/vpnserver/user_configs/$1/$USER_CONFIG_NAME"
    local PUBSERV=$(cat publickey.server)
    local PRIVCL=$(cat privatekey.$1)
    local PRECL=$(cat presharedkey.$1)
    local IPADDRESS=$(cat ipaddress)
    local HEADERPROTECTION=$(cat header.protection.key)
    local IP=$(ls -l /home/vpnserver/user_configs | wc -l)
    local -A ENCRYPT_PARAMS
    local key value

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
    echo "Address = 8.20.30.$IP/32" >> "$CONFIG"
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
    echo "HeaderProtectionKey = $HEADERPROTECTION" >> "$CONFIG"
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
    echo "Endpoint = $IPADDRESS" >> "$CONFIG"
    echo "AllowedIPs = 0.0.0.0/0, ::/0" >> "$CONFIG"
    echo "PersistentKeepalive = 20" >> "$CONFIG"
}

function delete_config_files () {
    local _REPLY
    echo "Are you sure?"
    read -p "enter "yes" or "no": " _REPLY

    if [[ "$_REPLY" = "yes" ]]; then
        rm publickey.$1
        rm privatekey.$1
        rm presharedkey.$1
        rm -R /home/vpnserver/user_configs/$1
        sed -i "/$1/,+4d" /etc/amnezia/amneziawg/awg0.conf
        systemctl reload awg-quick@awg0
    elif [[ "$_REPLY" = "no" ]]; then
        echo "Config files is not deleted."      
    else 
        delete_config_files
    fi
}

function edit_encrypt_value () {
    local CONFIG_DIR="/home/vpnserver/user_configs"
    local CONFIG_NAME
    local ENCRYPT_FILE="encrypt.conf"
    local HEADER_FILE="header.protection.key"
    local CONFIG
    local PARAM
    local KEY
    local VALUE
    local LINE
    local INPUT
    local DEFAULT
    local DISPLAY
    local TMP
    local ENCRYPT_TMP
    local HEADER_TMP
    local CONFIRM

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
        HeaderProtectionKey
        ContentPaddingAddition
        RekeyAfterTime
        RekeyTimeout
        RejectAfterTime
        KeepaliveTimeout
        MaxHandshakeAttempts
        RandomTrailers
        DisableCookies
    )

    local -a CONFIGS=()
    local -a EXTRA_LINES=()
    local -a AWK_ENV=()

    local -A PARAM_SET=()
    local -A CURRENT=()
    local -A CURRENT_SET=()
    local -A CHANGED=()
    local -A NEW_VALUES=()

    local UPDATED=0
    local UNCHANGED=0
    local SKIPPED=0
    local ENCRYPT_CHANGED=0
    local HEADER_CHANGED=0

    # Check central files
    if [[ ! -f "$ENCRYPT_FILE" ]]; then
        echo "File not found: $ENCRYPT_FILE"
        return 1
    fi

    if [[ ! -f "userconfig.name" ]]; then
        echo "File not found: userconfig.name"
        return 1
    fi

    CONFIG_NAME=$(cat userconfig.name)

    if [[ -z "$CONFIG_NAME" ]]; then
        echo "Configuration filename is empty"
        return 1
    fi

    # Find client configuration files
    mapfile -d '' CONFIGS < <(
        find "$CONFIG_DIR" -type f -name "$CONFIG_NAME" -print0
    )

    if [[ ${#CONFIGS[@]} -eq 0 ]]; then
        echo "No configuration files found"
        return 1
    fi

    # Build parameter list
    for PARAM in "${PARAM_NAMES[@]}"; do
        PARAM_SET["$PARAM"]=1
    done

    # Read current values from encrypt.conf
    while IFS= read -r LINE || [[ -n "$LINE" ]]; do

        [[ "$LINE" != *"="* ]] && {
            EXTRA_LINES+=("$LINE")
            continue
        }

        KEY="${LINE%%=*}"
        VALUE="${LINE#*=}"

        KEY="${KEY//[[:space:]]/}"

        # Skip empty lines and comments
        if [[ -z "$KEY" || "$KEY" == \#* ]]; then
            EXTRA_LINES+=("$LINE")
            continue
        fi

        # Trim value
        VALUE="${VALUE#"${VALUE%%[![:space:]]*}"}"
        VALUE="${VALUE%"${VALUE##*[![:space:]]}"}"

        if [[ -n "${PARAM_SET[$KEY]+x}" &&
              "$KEY" != "HeaderProtectionKey" ]]; then

            CURRENT["$KEY"]="$VALUE"
            CURRENT_SET["$KEY"]=1
        else
            EXTRA_LINES+=("$LINE")
        fi

    done < "$ENCRYPT_FILE"

    # Read HeaderProtectionKey separately
    if [[ -f "$HEADER_FILE" ]]; then
        CURRENT["HeaderProtectionKey"]=$(cat "$HEADER_FILE")
        CURRENT_SET["HeaderProtectionKey"]=1
    fi

    # User input
    echo "========================================"
    echo "       Parameter configuration"
    echo "========================================"
    echo
    echo "Press Enter to keep the existing value."
    echo "For missing parameters, press Enter to skip."
    echo

    for PARAM in "${PARAM_NAMES[@]}"; do

        DEFAULT="${CURRENT[$PARAM]-}"
        DISPLAY="$DEFAULT"

        if (( ${#DISPLAY} > 100 )); then
            DISPLAY="${DISPLAY:0:80}... (${#DEFAULT} characters)"
        fi

        if [[ -n "${CURRENT_SET[$PARAM]+x}" ]]; then
            read -r -p "$PARAM [$DISPLAY]: " INPUT || INPUT=""
        else
            read -r -p "$PARAM (new parameter, leave empty to skip): " INPUT || INPUT=""
        fi

        # Only explicitly entered values are marked as changed
        if [[ -n "$INPUT" ]]; then
            CHANGED["$PARAM"]=1
            NEW_VALUES["$PARAM"]="$INPUT"
        fi

    done

    # Check whether anything was changed
    if [[ ${#CHANGED[@]} -eq 0 ]]; then
        echo
        echo "No changes requested."
        return 0
    fi

    echo
    echo "========================================"
    echo "             Changes"
    echo "========================================"

    for PARAM in "${PARAM_NAMES[@]}"; do
        if [[ -n "${CHANGED[$PARAM]+x}" ]]; then
            echo "$PARAM = ${NEW_VALUES[$PARAM]}"
        fi
    done

    echo
    echo "Configuration files found: ${#CONFIGS[@]}"
    echo

    read -r -p "Apply changes? (y/N): " CONFIRM

    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        echo "Operation cancelled"
        return 0
    fi

    # Determine which central files need updating
    for PARAM in "${PARAM_NAMES[@]}"; do
        if [[ -n "${CHANGED[$PARAM]+x}" ]]; then
            if [[ "$PARAM" == "HeaderProtectionKey" ]]; then
                HEADER_CHANGED=1
            else
                ENCRYPT_CHANGED=1
            fi
        fi
    done

    # Update encrypt.conf
    if (( ENCRYPT_CHANGED )); then

        ENCRYPT_TMP=$(mktemp "${ENCRYPT_FILE}.XXXXXX") || return 1

        for PARAM in "${PARAM_NAMES[@]}"; do

            [[ "$PARAM" == "HeaderProtectionKey" ]] && continue

            if [[ -n "${CHANGED[$PARAM]+x}" ]]; then
                printf '%s = %s\n' "$PARAM" "${NEW_VALUES[$PARAM]}" >> "$ENCRYPT_TMP"

            elif [[ -n "${CURRENT_SET[$PARAM]+x}" ]]; then
                printf '%s = %s\n' "$PARAM" "${CURRENT[$PARAM]}" >> "$ENCRYPT_TMP"
            fi

        done

        # Preserve comments and unknown entries
        for LINE in "${EXTRA_LINES[@]}"; do
            printf '%s\n' "$LINE" >> "$ENCRYPT_TMP"
        done

        chown --reference="$ENCRYPT_FILE" "$ENCRYPT_TMP" || {
            rm -f "$ENCRYPT_TMP"
            return 1
        }

        chmod --reference="$ENCRYPT_FILE" "$ENCRYPT_TMP" || {
            rm -f "$ENCRYPT_TMP"
            return 1
        }

        mv "$ENCRYPT_TMP" "$ENCRYPT_FILE" || {
            rm -f "$ENCRYPT_TMP"
            return 1
        }

        echo "[UPDATED] $ENCRYPT_FILE"
    fi

    # Update header.protection.key
    if (( HEADER_CHANGED )); then

        HEADER_TMP=$(mktemp "${HEADER_FILE}.XXXXXX") || return 1

        printf '%s\n' "${NEW_VALUES[HeaderProtectionKey]}" > "$HEADER_TMP"

        if [[ -f "$HEADER_FILE" ]]; then
            chown --reference="$HEADER_FILE" "$HEADER_TMP" || {
                rm -f "$HEADER_TMP"
                return 1
            }

            chmod --reference="$HEADER_FILE" "$HEADER_TMP" || {
                rm -f "$HEADER_TMP"
                return 1
            }
        fi

        mv "$HEADER_TMP" "$HEADER_FILE" || {
            rm -f "$HEADER_TMP"
            return 1
        }

        echo "[UPDATED] $HEADER_FILE"
    fi

    # Prepare environment for AWK
    AWK_ENV=("CFG_KEYS=${PARAM_NAMES[*]}")

    for PARAM in "${PARAM_NAMES[@]}"; do

        if [[ -n "${CHANGED[$PARAM]+x}" ]]; then
            AWK_ENV+=("CFG_CHANGED_$PARAM=1")
            AWK_ENV+=("CFG_FILL_$PARAM=${NEW_VALUES[$PARAM]}")
        fi

    done

    echo
    echo "Updating client configuration files..."
    echo

    # Process client configuration files
    for CONFIG in "${CONFIGS[@]}"; do

        if ! grep -q '^\[Interface\][[:space:]]*$' "$CONFIG" ||
           ! grep -q '^\[Peer\][[:space:]]*$' "$CONFIG"; then

            echo "[SKIP] Invalid configuration: $CONFIG"
            SKIPPED=$((SKIPPED + 1))
            continue
        fi

        TMP=$(mktemp "${CONFIG}.XXXXXX") || return 1

        # Update only explicitly changed parameters.
        # Keep all existing parameters in PARAM_NAMES order.
        if ! env "${AWK_ENV[@]}" awk '
            BEGIN {
                count = split(ENVIRON["CFG_KEYS"], keys, " ")

                for (i = 1; i <= count; i++)
                    wanted[keys[i]] = 1
            }

            function flush_interface(    i, key) {

                # Print other Interface entries first
                for (i = 1; i <= other_count; i++)
                    print other[i]

                # Print managed parameters in the required order
                for (i = 1; i <= count; i++) {

                    key = keys[i]

                    if ((key in old_value) ||
                        ENVIRON["CFG_CHANGED_" key] == "1") {

                        if (ENVIRON["CFG_CHANGED_" key] == "1")
                            print key " = " ENVIRON["CFG_FILL_" key]
                        else
                            print key " = " old_value[key]
                    }
                }

                print ""

                for (i = 1; i <= other_count; i++)
                    delete other[i]

                for (i = 1; i <= count; i++)
                    delete old_value[keys[i]]

                other_count = 0
            }

            {
                # Detect sections
                if ($0 ~ /^\[[^]]+\][[:space:]]*$/) {

                    if (in_interface)
                        flush_interface()

                    print
                    in_interface = ($0 == "[Interface]")
                    next
                }

                if (in_interface) {

                    line = $0
                    sub(/^[[:space:]]*/, "", line)

                    if (line ~ /^[A-Za-z][A-Za-z0-9]*[[:space:]]*=/) {

                        key = line
                        sub(/[[:space:]]*=.*/, "", key)

                        if (key in wanted) {

                            if (!(key in old_value)) {
                                value = line
                                sub(/^[^=]*=[[:space:]]*/, "", value)
                                old_value[key] = value
                            }

                            next
                        }
                    }

                    # Preserve unrelated Interface entries and comments
                    if ($0 !~ /^[[:space:]]*$/)
                        other[++other_count] = $0

                    next
                }

                print
            }

            END {
                if (in_interface)
                    flush_interface()
            }
        ' "$CONFIG" > "$TMP"; then

            rm -f "$TMP"
            echo "[ERROR] Failed to process: $CONFIG"
            return 1
        fi

        # Check whether the file was actually modified
        if cmp -s "$CONFIG" "$TMP"; then
            rm -f "$TMP"
            echo "[UNCHANGED] $CONFIG"
            UNCHANGED=$((UNCHANGED + 1))
            continue
        fi

        # Preserve ownership and permissions
        chown --reference="$CONFIG" "$TMP" || {
            rm -f "$TMP"
            return 1
        }

        chmod --reference="$CONFIG" "$TMP" || {
            rm -f "$TMP"
            return 1
        }

        # Replace original configuration
        mv "$TMP" "$CONFIG" || {
            rm -f "$TMP"
            return 1
        }

        echo "[UPDATED] $CONFIG"
        UPDATED=$((UPDATED + 1))

    done

    echo
    echo "========================================"
    echo "                 Summary"
    echo "========================================"
    echo "Found:          ${#CONFIGS[@]}"
    echo "Updated:        $UPDATED"
    echo "Unchanged:      $UNCHANGED"
    echo "Skipped:        $SKIPPED"
    echo "========================================"
}

function edit_ip_address () {
    local USER_CONFIG_NAME=$(cat userconfig.name)
    find /home/vpnserver/user_configs -type f -name "$USER_CONFIG_NAME" -exec sed -i "34{s/^\(.\{11\}\).*/\1$1/}" {} \;
    echo $1 > /etc/amnezia/amneziawg/keys/ipaddress
}

function change_speed_limit () {
    > /root/bin/speed_limit
    echo $1 >> /root/bin/speed_limit
}

main