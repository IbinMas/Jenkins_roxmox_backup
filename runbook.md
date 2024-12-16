# **Runbook for Backing Up and Restoring Proxmox Configuration**

## **Overview**
This runbook provides step-by-step instructions for safely backing up and restoring the configuration files of a Proxmox Virtual Environment (VE) system.

## **Scope**
- Backing up the `/etc/pve` directory, which contains critical Proxmox VE configuration files.
- Restoring the backed-up configuration in case of failure or disaster recovery.

---

## **Backup Process**

### **1. Prerequisites**
- Proxmox VE server is running.
- SSH access to the Proxmox server with a user account that has sufficient privileges to access `/etc/pve`.
- A designated backup directory on a local or remote system.
- Ensure there is enough disk space in the backup directory and on the Proxmox server for temporary storage.

### **2. Backup Steps**
1. **Access the Proxmox Server**:
   ```bash
   ssh [your-username]@[proxmox-ip-or-hostname]
   ```

2. **Run the Backup Command**:
   Execute the following command to create a compressed archive of the `/etc/pve` directory:
   ```bash
   tar -czf /tmp/proxmox-backup-$(date +%F).tar.gz /etc/pve
   ```
   - This creates a timestamped backup file in the `/tmp` directory.

3. **Transfer the Backup to a Safe Location**:
   Copy the backup file to a remote or local backup directory using `scp`:
   ```bash
   scp /tmp/proxmox-backup-*.tar.gz [backup-user]@[backup-server]:/path/to/backup/location
   ```

4. **Clean Up Temporary Files**:
   After transferring the backup, remove the temporary file from the Proxmox server:
   ```bash
   rm /tmp/proxmox-backup-*.tar.gz
   ```

5. **Verify the Backup**:
   On the backup server, verify the integrity of the backup file:
   ```bash
   tar -tzf /path/to/backup/location/proxmox-backup-$(date +%F).tar.gz > /dev/null
   ```
   If no errors are reported, the backup is valid.

### **6. Optional: Automate the Backup Process**
Use a cron job on a management server to automate backups. Example:
```bash
0 2 * * * ssh [your-username]@[proxmox-ip] 'tar -czf /tmp/proxmox-backup-$(date +%F).tar.gz /etc/pve' && \
scp [your-username]@[proxmox-ip]:/tmp/proxmox-backup-*.tar.gz /path/to/backup/location && \
ssh [your-username]@[proxmox-ip] 'rm /tmp/proxmox-backup-*.tar.gz'
```

---

## **Restore Process**

### **1. Prerequisites**
- A valid backup archive available locally or on a remote server.
- SSH access to the Proxmox server.
- Sufficient privileges to overwrite `/etc/pve`.
- Ensure all critical operations on Proxmox are paused or stopped before restoring.

### **2. Restore Steps**
1. **Transfer the Backup to the Proxmox Server**:
   Copy the backup file to the Proxmox server:
   ```bash
   scp [backup-user]@[backup-server]:/path/to/backup/location/proxmox-backup-*.tar.gz /tmp/
   ```



2. **Extract the Backup Archive**:
   Restore the configuration files by extracting the backup:
   ```bash
   tar -xzf /tmp/proxmox-backup-*.tar.gz -C /
   ```

3. **Restart Services (if stopped)**:
   Start the cluster services again:
   ```bash
   systemctl start pve-cluster
   ```

4. **Clean Up Temporary Files**:
   Remove the backup file from the Proxmox server:
   ```bash
   rm /tmp/proxmox-backup-*.tar.gz
   ```

5. **Verify the Restoration**:
   Check that Proxmox is functioning as expected and configurations are restored.
   For example, verify cluster status:
   ```bash
   pvecm status
   ```

---

## **Validation and Testing**
- Periodically test the backup and restore process in a non-production environment to ensure reliability.
- Keep multiple copies of recent backups to mitigate the risk of file corruption.
- Document backup locations and schedules for easy access during emergencies.



## **Troubleshooting**
- **Backup File Missing**: Ensure the `tar` command completed successfully and sufficient disk space is available.
- **Permission Issues**: Verify that the user executing the commands has access to `/etc/pve` and sufficient privileges to manage services.
- **Cluster Inconsistencies**: If restoring in a cluster, ensure all nodes are synchronized after restoration:
  ```bash
  pvecm updatecerts --force
  systemctl restart pve-cluster
  ```





