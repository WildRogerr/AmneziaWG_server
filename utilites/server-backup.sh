#!/bin/bash

rsync -aAXve "ssh -p 989 -i /root/.ssh/id_rsa_backup" /etc/amnezia {username}@{ip for backup}:/home/{username}/netserver_backup/
rsync -aAXve "ssh -p 989 -i /root/.ssh/id_rsa_backup" /home/vpnserver/user_configs {username}@{ip for backup}:/home/{username}/netserver_backup/
rsync -aAXve "ssh -p 989 -i /root/.ssh/id_rsa_backup" /home/vpnserver/OwlVPN_bot/owldatabase.db {username}@{ip for backup}:/home/{username}/netserver_backup/OwlVPN_bot/
rsync -aAXve "ssh -p 989 -i /root/.ssh/id_rsa_backup" /home/vpnserver/OwlVPN_bot/log.txt {username}@{ip for backup}:/home/{username}/netserver_backup/OwlVPN_bot/
rsync -aAXve "ssh -p 989 -i /root/.ssh/id_rsa_backup" /home/vpnserver/OwlVPN_bot/config.py {username}@{ip for backup}:/home/{username}/netserver_backup/OwlVPN_bot/

#Чтобы восстановить систему из резервной копии, просто измените исходные и целевые пути в приведенной выше команде.
#rsync -aAXve "ssh -p 989 -i /root/.ssh/id_rsa_backup" {username}@{ip for backup}:/home/{username}/netserver_backup/amnezia /etc/
#rsync -aAXve "ssh -p 989 -i /root/.ssh/id_rsa_backup" {username}@{ip for backup}:/home/{username}/netserver_backup/user_configs /home/vpnserver/
#rsync -aAXve "ssh -p 989 -i /root/.ssh/id_rsa_backup" {username}@{ip for backup}:/home/{username}/netserver_backup/OwlVPN_bot/owldatabase.db /home/vpnserver/OwlVPN_bot/
#rsync -aAXve "ssh -p 989 -i /root/.ssh/id_rsa_backup" {username}@{ip for backup}:/home/{username}/netserver_backup/OwlVPN_bot/log.txt /home/vpnserver/OwlVPN_bot/
#rsync -aAXve "ssh -p 989 -i /root/.ssh/id_rsa_backup" {username}@{ip for backup}:/home/{username}/netserver_backup/OwlVPN_bot/config.py /home/vpnserver/OwlVPN_bot/
