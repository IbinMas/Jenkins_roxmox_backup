pipeline {
    agent any

    environment {
        PROXMOX_HOST = "10.1.1.100"
        BACKUP_DIR = "/mnt/PROXMOX_BACKUP"
        SSH_USER = "root"
    }

    stages {
        stage('Backup Proxmox Configuration') {
            steps {
                script {
                    sh """
                    # Create a timestamped backup file
                    ssh ${SSH_USER}@${PROXMOX_HOST} \\
                        'tar -czf ${BACKUP_DIR}/proxmox-backup-$(date +\\%Y-\\%m-\\%d).tar.gz /etc/pve'

                    # Verify the integrity of the backup
                    ssh ${SSH_USER}@${PROXMOX_HOST} \\
                        'tar -tzf ${BACKUP_DIR}/proxmox-backup-$(date +\\%Y-\\%m-\\%d).tar.gz > /dev/null || exit 1'

                    # Clean up old backups (older than 90 days)
                    ssh ${SSH_USER}@${PROXMOX_HOST} \\
                        'find ${BACKUP_DIR} -type f -name "proxmox-backup-*.tar.gz" -mtime +90 -exec rm {} \;'
                    """
                }
            }
        }
        
        stage('Restore Proxmox Configuration') {
            input {
                message "Do you want to restore Proxmox configuration?"
            }
            steps {
                script {
                    sh """
                    # Copy the backup file to the Proxmox server
                    scp ${BACKUP_DIR}/proxmox-backup-*.tar.gz ${SSH_USER}@${PROXMOX_HOST}:/tmp/

                    # Restore the configuration
                    ssh ${SSH_USER}@${PROXMOX_HOST} \\
                        'tar -xzf /tmp/proxmox-backup-*.tar.gz -C / && rm /tmp/proxmox-backup-*.tar.gz'
                    """
                }
            }
        }
    }

    post {
        success {
            echo 'Backup/Restore operation completed successfully.'
        }
        failure {
            echo 'Backup/Restore operation failed.'
        }
    }
}
