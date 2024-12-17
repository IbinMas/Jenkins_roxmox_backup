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
    echo "Error: Backup directory does not exist, exiting."
    exit 1
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

# Create backup
echo "Creating backup for $HOSTNAME..."

# Backup critical system files
tar -czf "$TEMP_DIR/$BACKUP_FILENAME" \
    -C / etc/pve || { echo "Backup failed."; exit 1; }
    # -C / var/lib/pve-cluster || { echo "Backup failed."; exit 1; }

# Debugging: Check if the backup file is created in TEMP_DIR
echo "Temporary backup file: $TEMP_DIR/$BACKUP_FILENAME"
ls -l "$TEMP_DIR"

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

echo "Backup completed successfully."
