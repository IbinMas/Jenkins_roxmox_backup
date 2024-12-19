# Navigate to the back-test directory
cd /mnt/pve/media/ROXMOX_BACKUP/back-test

# Create separate directories to extract individual tarballs
mkdir -p extracted/pve
mkdir -p extracted/ssh
mkdir -p extracted/corosync
mkdir -p extracted/pve-cluster

# Extract pve-backup.tar.gz
tar -xzf pve-backup.tar.gz -C extracted/pve
echo "Contents of pve-backup:"
ls -l extracted/pve

# Extract ssh-backup.tar.gz
tar -xzf ssh-backup.tar.gz -C extracted/ssh
echo "Contents of ssh-backup:"
ls -l extracted/ssh

# Extract corosync-backup.tar.gz
tar -xzf corosync-backup.tar.gz -C extracted/corosync
echo "Contents of corosync-backup:"
ls -l extracted/corosync

# Extract pve-cluster-backup.tar.gz
tar -xzf pve-cluster-backup.tar.gz -C extracted/pve-cluster
echo "Contents of pve-cluster-backup:"
ls -l extracted/pve-cluster


# # Navigate to the directory containing the tarball
# cd /mnt/pve/media/ROXMOX_BACKUP

# # Ensure the target extraction directory exists
# mkdir -p /mnt/pve/media/ROXMOX_BACKUP/back-test

# # Extract the tarball to the target directory
# tar -xzf pve_pve_2024-12-18.19.20.32.tar.gz -C /mnt/pve/media/ROXMOX_BACKUP/back-test

# # Verify the extracted files
# ls -l /mnt/pve/media/ROXMOX_BACKUP/back-test



# Check the status of the pve-cluster service
systemctl status pve-cluster.service

# View detailed logs for the pve-cluster service
journalctl -xeu pve-cluster.service

# Verify permissions of restored files and directories
ls -l /etc/pve
ls -l /var/lib/pve-cluster

# Manually restart the pve-cluster service
systemctl restart pve-cluster.service





