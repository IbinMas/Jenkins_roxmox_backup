#!/bin/bash

###########################
# Configuration Variables #
###########################

DEFAULT_BACK_DIR="/mnt/pve/media/ROXMOX_BACKUP"
BACKUP_DIR=${BACK_DIR:-$DEFAULT_BACK_DIR}
MAX_BACKUPS=5

###########################

# Exit on error
set -e

# Ensure backup directory exists
if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "Error: Backup directory does not exist, creating it."
    mkdir -p "$DEFAULT_BACK_DIR"
fi

# Generate timestamp and filenames
NOW=$(date +%Y-%m-%d.%H.%M.%S)
HOSTNAME=$(hostname)
BACKUP_FILENAME="pve_${HOSTNAME}_${NOW}.tar.gz"
TEMP_DIR=$(mktemp -d)

# Temporary cleanup function
function clean_up {
    # Remove temporary directory
    rm -rf "$TEMP_DIR"
}

trap clean_up EXIT

# Backup critical system files
echo "Creating backup for $HOSTNAME..."

# Create individual backups for each critical directory
mkdir -p "$TEMP_DIR/backup"

# Ensure necessary directories are created
mkdir -p "$TEMP_DIR/backup/ssh"
mkdir -p "$TEMP_DIR/backup/etc"
mkdir -p "$TEMP_DIR/backup/var/lib"

# echo "Copying /etc/pve to $TEMP_DIR/backup/etc/pve"
# rsync -av /etc/pve/ "$TEMP_DIR/backup/etc/pve"
tar -czvf $TEMP_DIR/backup/etc-pve-backup.tar.gz /etc/pve

# Stop necessary Proxmox services before creating other backups
echo "Stopping Proxmox services..."
services=( "pvestatd" "pvedaemon" "pve-cluster" )
for service in "${services[@]}"; do
    systemctl stop "$service"
    echo "$service stopped."
done
# Copy directories to temporary location before stopping services
echo "Copying /root/.ssh to $TEMP_DIR/backup/ssh"
rsync -av /root/.ssh/ "$TEMP_DIR/backup/ssh"
# tar -czvf $TEMP_DIR/backup/ssh-backup.tar.gz /root/.ssh

echo "Copying /var/lib/pve-cluster to $TEMP_DIR/backup/var/lib/pve-cluster"
# rsync -av /var/lib/pve-cluster/ "$TEMP_DIR/backup/var/lib/pve-cluster"
tar -czvf $TEMP_DIR/backup/pve-cluster-backup.tar.gz /var/lib/pve-cluster

echo "Copying /etc/corosync to $TEMP_DIR/backup/etc/corosync"
# rsync -av /etc/corosync/ "$TEMP_DIR/backup/etc/corosync"
tar -czvf $TEMP_DIR/backup/etc-corosync-backup.tar.gz /etc/corosync

# Verify contents of directories in the temporary directory
# echo "Contents of $TEMP_DIR/backup/etc/pve after copy:"
# ls -lR "$TEMP_DIR/backup/etc/pve"

echo "Contents of $TEMP_DIR/backup/ssh after copy:"
ls -lR "$TEMP_DIR/backup/ssh"

# echo "Contents of $TEMP_DIR/backup/var/lib/pve-cluster after copy:"
# ls -lR "$TEMP_DIR/backup/var/lib/pve-cluster"

# echo "Contents of $TEMP_DIR/backup/etc/corosync after copy:"
# ls -lR "$TEMP_DIR/backup/etc/corosync"



# /etc/vzdump.conf

# Copy critical configuration files if they exist
for file in /etc/hosts /etc/network/interfaces /etc/networks /etc/resolv.conf ; do
    if [[ -f "$file" ]]; then
        cp "$file" "$TEMP_DIR/backup/etc/$(basename "$file")"
    else
        echo "Warning: $file does not exist, skipping."
    fi
done

# Combine all backups into one tarball
tar -czf "$TEMP_DIR/$BACKUP_FILENAME" -C "$TEMP_DIR/backup" .

# Debugging: Check if the backup file is created in TEMP_DIR
echo "Temporary backup file: $TEMP_DIR/$BACKUP_FILENAME"
ls -l "$TEMP_DIR"
tar -tf "$TEMP_DIR/$BACKUP_FILENAME"

# Handle backup cleanup: Delete backups older than 90 days
echo "Cleaning up backups older than 90 days..."
find "$BACKUP_DIR" -type f -name "*_${HOSTNAME}_*.tar.gz" -mtime +90 -exec rm -v {} \;

# Move the new backup to the backup directory
echo "Moving backup to $BACKUP_DIR..."
if mv "$TEMP_DIR/$BACKUP_FILENAME" "$BACKUP_DIR/"; then
    echo "Backup successfully moved to $BACKUP_DIR"
else
    echo "Failed to move backup file."
    exit 1
fi

# Restart Proxmox services after backup
echo "Restarting Proxmox services..."
for service in "${services[@]}"; do
    systemctl start "$service"
    echo "$service started."
done

# Cleanup temporary files
clean_up

echo "Backup completed successfully."
