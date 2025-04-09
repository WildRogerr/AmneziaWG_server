apt install -y ufw
ufw disable
ufw default deny incoming
ufw default allow outgoing
ufw allow 989/tcp
ufw allow 1984/udp
ufw allow from 193.108.114.119 to any
ufw deny from ::/0
ufw deny to ::/0
ufw enable

cat <<EOF > /etc/fail2ban/jail.d/portscan.conf
[portscan]
enabled = true
filter = portscan
logpath = /var/log/ufw.log
backend = auto
banaction = ufw
maxretry = 1
findtime = 600
bantime = 86400
EOF

cat <<EOF > /etc/fail2ban/jail.local
[portscan]
enabled = true
filter = portscan
logpath = /var/log/ufw.log
backend = auto
banaction = ufw
maxretry = 1
findtime = 600
bantime = 86400
EOF

cat <<EOF > /etc/fail2ban/filter.d/portscan.conf
[Definition]
failregex = ^.*\[UFW BLOCK\].*SRC=<HOST>.*
ignoreregex =
EOF

touch /var/log/auth.log
touch /var/log/ufw.log
chmod 644 /var/log/ufw.log
systemctl restart fail2ban