# cat ./prox_config_restore.sh 
#!/bin/bash

###########################
# Configuration Variables #
###########################

DEFAULT_BACK_DIR="/mnt/pve/media/ROXMOX_BACKUP"

###########################

# Find the most recent backup file
BACKUP_FILE=$(ls -t ${DEFAULT_BACK_DIR}/*.tar.gz 2>/dev/null | head -n 1)

# Verify the most recent backup file exists
if [[ -z "$BACKUP_FILE" ]]; then
    echo "Error: No backup files found in $DEFAULT_BACK_DIR."
    exit 1
fi

echo "Using the most recent backup file: $BACKUP_FILE"

# Stop necessary Proxmox services before restoring
echo "Stopping Proxmox services..."
services=("pvestatd" "pvedaemon" "pve-cluster")

for service in "${services[@]}"; do
    echo "Stopping $service..."
    systemctl stop "$service" || echo "Warning: Failed to stop $service."
done

# Restore /etc/hosts
echo "Restoring /etc/hosts..."
tar -xzf "$BACKUP_FILE" -C /tmp './hosts.backup' || { echo "Error: Failed to extract hosts.backup."; exit 1; }
mv /tmp/hosts.backup /etc/hosts || { echo "Error: Failed to move hosts.backup to /etc/hosts."; exit 1; }

# Restore /etc/network/interfaces
echo "Restoring /etc/network/interfaces..."
tar -xzf "$BACKUP_FILE" -C /tmp './interfaces.backup' || { echo "Error: Failed to extract interfaces.backup."; exit 1; }
mv /tmp/interfaces.backup /etc/network/interfaces || { echo "Error: Failed to move interfaces.backup to /etc/network/interfaces."; exit 1; }
# Restore /etc/networks
echo "Restoring /etc/networks..."
tar -xzf "$BACKUP_FILE" -C /tmp './networks.backup' || { echo "Error: Failed to extract interfaces.backup."; exit 1; }
mv /tmp/networks.backup /etc/networks || { echo "Error: Failed to move networks.backup to /etc/networks."; exit 1; }
# Restore /etc/resolv.conf
echo "Restoring /etc/resolv.conf..."
tar -xzf "$BACKUP_FILE" -C /tmp './resolv.conf.backup' || { echo "Error: Failed to extract interfaces.backup."; exit 1; }
mv /tmp/resolv.conf.backup /etc/resolv.conf || { echo "Error: Failed to move networks.backup to /etc/resolv.conf."; exit 1; }

# Restore the files in /root/.ssh/
echo "Restoring /root/.ssh..."
tar -xzf "$BACKUP_FILE" -C /tmp './ssh-backup.tar.gz' || { echo "Error: Failed to extract ssh-backup.tar.gz."; exit 1; }
tar -xzf /tmp/ssh-backup.tar.gz -C /root/.ssh || { echo "Error: Failed to restore /root/.ssh."; exit 1; }
rm -f /tmp/ssh-backup.tar.gz

# Replace /var/lib/pve-cluster/
echo "Restoring /var/lib/pve-cluster..."
rm -rf /var/lib/pve-cluster || { echo "Error: Failed to remove /var/lib/pve-cluster."; exit 1; }
mkdir -p /var/lib/pve-cluster
tar -xzf "$BACKUP_FILE" -C /tmp './pve-cluster-backup.tar.gz' || { echo "Error: Failed to extract pve-cluster-backup.tar.gz."; exit 1; }
tar -xzf /tmp/pve-cluster-backup.tar.gz -C /var/lib/pve-cluster || { echo "Error: Failed to restore /var/lib/pve-cluster."; exit 1; }
rm -f /tmp/pve-cluster-backup.tar.gz

# Replace /etc/corosync/
echo "Restoring /etc/corosync..."
rm -rf /etc/corosync || { echo "Error: Failed to remove /etc/corosync."; exit 1; }
mkdir -p /etc/corosync
tar -xzf "$BACKUP_FILE" -C /tmp './corosync-backup.tar.gz' || { echo "Error: Failed to extract corosync-backup.tar.gz."; exit 1; }
tar -xzf /tmp/corosync-backup.tar.gz -C /etc/corosync || { echo "Error: Failed to restore /etc/corosync."; exit 1; }
rm -f /tmp/corosync-backup.tar.gz

# # Restore /etc/pve
# echo "Restoring /etc/pve..."
# tar -xzf "$BACKUP_FILE" -C /tmp './pve-backup.tar.gz' || { echo "Error: Failed to extract pve-backup.tar.gz."; exit 1; }
# tar -xzf /tmp/pve-backup.tar.gz -C /etc/pve || { echo "Error: Failed to restore /etc/pve."; exit 1; }
# rm -f /tmp/pve-backup.tar.gz

# Start pve-cluster service
echo "Starting pve-cluster service..."
systemctl start pve-cluster.service || { echo "Error: Failed to start pve-cluster.service."; exit 1; }

# Restore the two SSH symlinks
echo "Restoring SSH symlinks..."
ln -sf /etc/pve/priv/authorized_keys /root/.ssh/authorized_keys || { echo "Error: Failed to restore authorized_keys symlink."; exit 1; }
ln -sf /etc/pve/priv/authorized_keys /root/.ssh/authorized_keys.orig || { echo "Error: Failed to restore authorized_keys.orig symlink."; exit 1; }
echo "Cheking cluster status after Restoring ..."
pvecm status
# Start remaining Proxmox services
echo "Starting remaining Proxmox services..."
for service in "pvestatd" "pvedaemon"; do
    echo "Starting $service..."
    systemctl start "$service" || echo "Warning: Failed to start $service."
done

# Verify that all services are running
echo "Verifying service statuses..."
for service in "${services[@]}"; do
    systemctl status "$service" | grep "Active:" || echo "Warning: $service is not running."
done

echo "Restore completed successfully. Verify the system functionality."

reboot