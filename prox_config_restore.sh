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

# Extract the tarball to a temporary location
TEMP_RESTORE_DIR=$(mktemp -d)
tar -xzf "$BACKUP_FILE" -C "$TEMP_RESTORE_DIR"

# Restore /etc/hosts
echo "Restoring /etc/hosts..."
mv "$TEMP_RESTORE_DIR/etc/hosts" /etc/hosts || { echo "Error: Failed to move hosts to /etc/hosts."; exit 1; }

# Restore /etc/network/interfaces
echo "Restoring /etc/network/interfaces..."
mv "$TEMP_RESTORE_DIR/etc/interfaces" /etc/network/interfaces || { echo "Error: Failed to move interfaces to /etc/network/interfaces."; exit 1; }

# Restore /etc/networks
echo "Restoring /etc/networks..."
mv "$TEMP_RESTORE_DIR/etc/networks" /etc/networks || { echo "Error: Failed to move networks to /etc/networks."; exit 1; }

# Restore /etc/resolv.conf
echo "Restoring /etc/resolv.conf..."
mv "$TEMP_RESTORE_DIR/etc/resolv.conf" /etc/resolv.conf || { echo "Error: Failed to move resolv.conf to /etc/resolv.conf."; exit 1; }

# Restore /root/.ssh
echo "Restoring /root/.ssh..."
rsync -av "$TEMP_RESTORE_DIR/ssh/" /root/.ssh/
# tar -xzvf $TEMP_RESTORE_DIR/ssh-backup.tar.gz -C /

# Restore /var/lib/pve-cluster
echo "Restoring /var/lib/pve-cluster..."
# rsync -av "$TEMP_RESTORE_DIR/var/lib/pve-cluster/" /var/lib/pve-cluster/
tar -xzvf $TEMP_RESTORE_DIR/pve-cluster-backup.tar.gz -C /

# Restore /etc/corosync
echo "Restoring /etc/corosync..."
# rsync -av "$TEMP_RESTORE_DIR/etc/corosync/" /etc/corosync/
tar -xzvf $TEMP_RESTORE_DIR/etc-corosync-backup.tar.gz -C /
# # Restore /etc/pve
# echo "Restoring /etc/pve..."
# rsync -av "$TEMP_RESTORE_DIR/etc/pve/" /etc/pve/


# Start pve-cluster service
echo "Starting pve-cluster service..."
systemctl start pve-cluster.service || { echo "Error: Failed to start pve-cluster.service."; exit 1; }

# Restore the two SSH symlinks
echo "Restoring SSH symlinks..."
ln -sf /etc/pve/priv/authorized_keys /root/.ssh/authorized_keys || { echo "Error: Failed to restore authorized_keys symlink."; exit 1; }
ln -sf /etc/pve/priv/authorized_keys /root/.ssh/authorized_keys.orig || { echo "Error: Failed to restore authorized_keys.orig symlink."; exit 1; }

# Check cluster status after restoring
# echo "Checking cluster status after restoring..."
# pvecm status

# Start remaining Proxmox services
echo "Starting remaining Proxmox services..."
for service in "pvestatd" "pvedaemon"; do
    echo "Starting $service..."
    systemctl start "$service" || echo "Warning: Failed to start $service."
done

# Restore /etc/pve
tar -xzvf $TEMP_RESTORE_DIR/etc-pve-backup.tar.gz -C /
# Restart Proxmox services
systemctl restart pve-cluster.service
systemctl restart pvedaemon.service
systemctl restart pveproxy.service

# # Verify that all services are running
# echo "Verifying service statuses..."
# for service in "${services[@]}"; do
#     systemctl status "$service" | grep "Active:" || echo "Warning: $service is not running."
# done

echo "Restore completed successfully. Verify the system functionality."

# Cleanup temporary files
rm -rf "$TEMP_RESTORE_DIR"

 reboot
