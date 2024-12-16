pipeline {
    agent any

    environment {
        PROXMOX_HOST = "192.168.1.193"
        BACKUP_DIR = "/mnt/PROXMOX_BACKUP"
        USER_CREDENTIALS_USR = credentials('proxmox_server')
    }

    stages {
        stage('Backup Proxmox Configuration') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')]) {
                        sh """
                        # Create a timestamped backup file
                        sshpass -p '${USER_CREDENTIALS_USR}Pass' ssh -o StrictHostKeyChecking=no ${USER_CREDENTIALS_USR}${PROXMOX_HOST} \\
                            'tar -czf ${BACKUP_DIR}/proxmox-backup-$(date +\\%Y-\\%m-\\%d).tar.gz /etc/pve'

                        # Verify the integrity of the backup
                        sshpass -p '${USER_CREDENTIALS_USR}Pass' ssh -o StrictHostKeyChecking=no ${USER_CREDENTIALS_USR}${PROXMOX_HOST} \\
                            'tar -tzf ${BACKUP_DIR}/proxmox-backup-$(date +\\%Y-\\%m-\\%d).tar.gz > /dev/null || exit 1'

                        # Clean up old backups (older than 90 days)
                        sshpass -p '${USER_CREDENTIALS_USR}Pass' ssh -o StrictHostKeyChecking=no ${USER_CREDENTIALS_USR}${PROXMOX_HOST} \\
                            'find ${BACKUP_DIR} -type f -name "proxmox-backup-*.tar.gz" -mtime +90 -exec rm {} \\;'
                        """
                    }
                // }
            }
        }

        stage('Restore Proxmox Configuration') {
            input {
                message "Do you want to restore Proxmox configuration?"
            }
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')]) {
                        sh """
                        # Copy the backup file to the Proxmox server
                        scp -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${BACKUP_DIR}/proxmox-backup-*.tar.gz ${SSH_USER}@${PROXMOX_HOST}:/tmp/

                        # Restore the configuration
                        sshpass -p '${USER_CREDENTIALS_USR}Pass' ssh -o StrictHostKeyChecking=no ${USER_CREDENTIALS_USR}${PROXMOX_HOST} \\
                            'tar -xzf /tmp/proxmox-backup-*.tar.gz -C / && rm /tmp/proxmox-backup-*.tar.gz'
                        """
                    }
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
