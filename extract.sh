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






