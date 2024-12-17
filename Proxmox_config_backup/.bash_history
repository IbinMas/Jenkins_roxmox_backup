pvecm create  cluser-01
pvecm status
pvecm nodes
systemctl stop pvestatd.service
systemctl stop pvedaemon.service
systemctl stop pve-cluster.service
tar -czf /root/pve-cluster-backup.tar.gz /var/lib/pve-cluster
ls /root/
tar -czf /root/ssh-backup.tar.gz /root/.ssh
tar -czf /root/corosync-backup.tar.gz /etc/corosync
cp /etc/hosts /root/
cp /etc/network/interfaces /root/
exit
