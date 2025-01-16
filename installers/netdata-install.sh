apt update && apt install -y netdata nginx apache2-utils

htpasswd -c /etc/nginx/.htpasswd vpnserver

cat <<EOF > /etc/netdata/netdata.conf
[global]
        run as user = netdata
        web files owner = root
        web files group = root
        bind socket to IP = 127.0.0.1
EOF

cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 80;
    server_name localhost;

    location / {
        auth_basic "Restricted Access";
        auth_basic_user_file /etc/nginx/.htpasswd;

        proxy_pass http://localhost:19999;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

systemctl restart nginx
systemctl restart netdata