#!/bin/bash

rsync -aAXve "ssh -p 989" root@91.147.92.228:/etc/amnezia /home/navgeo/netserver_backup/
rsync -aAXve "ssh -p 989" root@91.147.92.228:/home/vpnserver/user_configs /home/navgeo/netserver_backup/

#Чтобы восстановить систему из резервной копии, просто измените исходные и целевые пути в приведенной выше команде.
#rsync -aAXve "ssh -p 989" /home/navgeo/netserver_backup/amnezia root@91.147.92.228:/etc/
#rsync -aAXve "ssh -p 989" /home/navgeo/netserver_backup/user_configs root@91.147.92.228:/home/vpnserver/