#!/bin/bash

###########################
# Configuration Variables #
###########################

DEFAULT_BACK_DIR="/mnt/pve/media/ROXMOX_BACKUP"
TEMP_DIR=$(mktemp -d)

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
services=("pveproxy" "pvestatd" "pvedaemon" "pve-cluster" "corosync" "pve-ha-lrm" "pve-ha-crm" "pve-firewall" "pvescheduler")

for service in "${services[@]}"; do
    echo "Stopping $service..."
    systemctl stop $service || echo "Warning: Failed to stop $service."
done

# Verify that services are stopped
for service in "${services[@]}"; do
    echo "Verifying $service is stopped..."
    systemctl status $service | grep "Active:" || echo "$service is not running."
done

# Extract backup
echo "Restoring from backup: $BACKUP_FILE"
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR" || { echo "Error: Failed to extract backup file."; exit 1; }

# Restore files from the backup
echo "Restoring files from backup..."
cp -a "$TEMP_DIR/." / || { echo "Error: Failed to restore files."; exit 1; }

# Set correct permissions
echo "Setting correct permissions..."
chown -R root:www-data /etc/pve
chown -R root:root /var/lib/pve-cluster

# Clean up temporary directory
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

# Restart Proxmox services after restoring
echo "Restarting Proxmox services..."
for service in "${services[@]}"; do
    echo "Starting $service..."
    systemctl start $service || echo "Warning: Failed to start $service."
done

# Verify that services are running
for service in "${services[@]}"; do
    echo "Verifying $service is running..."
    systemctl status $service | grep "Active:" || echo "Warning: $service did not start correctly."
done

echo "Restore completed successfully. Verify the system functionality."
