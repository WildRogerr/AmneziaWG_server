#!/bin/bash

rsync -aAXve "ssh -p 989 -i /root/.ssh/id_rsa_backup" /etc/amnezia {username}@{ip for backup}:/home/wildroger/netserver_backup/etc/
rsync -aAXve "ssh -p 989 -i /root/.ssh/id_rsa_backup" /etc/fstab {username}@{ip for backup}:/home/wildroger/netserver_backup/etc/
rsync -aAXve "ssh -p 989 -i /root/.ssh/id_rsa_backup" /etc/ssh/sshd_config {username}@{ip for backup}:/home/wildroger/netserver_backup/etc/ssh/
rsync -aAXve "ssh -p 989 -i /root/.ssh/id_rsa_backup" /etc/zabbix/zabbix_agentd.conf {username}@{ip for backup}:/home/wildroger/netserver_backup/etc/zabbix/
rsync -aAXve "ssh -p 989 -i /root/.ssh/id_rsa_backup" /home/vpnserver/user_configs {username}@{ip for backup}:/home/wildroger/netserver_backup/

#Чтобы восстановить систему из резервной копии, просто измените исходные и целевые пути в приведенной выше команде.
#rsync -aAXve "ssh -p 989 -i /root/.ssh/id_rsa_backup" {username}@{ip for backup}:/home/wildroger/netserver_backup/etc/amnezia /etc/
#rsync -aAXve "ssh -p 989 -i /root/.ssh/id_rsa_backup" {username}@{ip for backup}:/home/wildroger/netserver_backup/etc/ssh/sshd_config /etc/ssh/
#rsync -aAXve "ssh -p 989 -i /root/.ssh/id_rsa_backup" {username}@{ip for backup}:/home/wildroger/netserver_backup/etc/fstab /etc/
#rsync -aAXve "ssh -p 989 -i /root/.ssh/id_rsa_backup" {username}@{ip for backup}:/home/wildroger/netserver_backup/etc/zabbix/zabbix_agentd.conf /etc/zabbix/
#rsync -aAXve "ssh -p 989 -i /root/.ssh/id_rsa_backup" {username}@{ip for backup}:/home/wildroger/netserver_backup/user_configs /home/vpnserver/
