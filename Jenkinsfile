pipeline {
    agent any

    environment {
        PROXMOX_HOST = "192.168.1.193"
        BACKUP_DIR = "/mnt/PROXMOX_BACKUP"
    }

    stages {
        stage('Backup Proxmox Configuration') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')]) {
                        sh """
                        # Ensure backup directory exists
                        ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} "mkdir -p ${BACKUP_DIR}"

                        # Create a timestamped backup file
                        BACKUP_FILE="${BACKUP_DIR}/proxmox-backup-\$(date +%Y-%m-%d).tar.gz"
                        ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} "tar -czf \${BACKUP_FILE} /etc/pve"

                        # Verify the integrity of the backup
                        ssh -i **** -o StrictHostKeyChecking=no ****@192.168.1.193 "tar -tzf \${BACKUP_FILE} > /dev/null || exit 1"

                        # Clean up old backups (older than 90 days)
                        ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} "find ${BACKUP_DIR} -type f -name 'proxmox-backup-*.tar.gz' -mtime +90 -exec rm {} \\;"
                        """
                    }
                }
            }
        }

        stage('Restore Proxmox Configuration') {
            input {
                message "Do you want to restore the latest Proxmox configuration?"
                parameters {
                    booleanParam(name: 'ConfirmRestore', defaultValue: false, description: 'Confirm restoration of the latest backup')
                }
            }
            when {
                expression { params.ConfirmRestore }
            }
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')]) {
                        // Find the most recent backup file
                        def latestBackupFile = sh(script: """
                            ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} \
                                "ls -t ${BACKUP_DIR}/proxmox-backup-*.tar.gz 2>/dev/null | head -n 1"
                        """, returnStdout: true).trim()

                        // Check if a backup file exists
                        if (latestBackupFile) {
                            echo "Restoring from backup: ${latestBackupFile}"

                            // Stop Proxmox services
                            sh """
                                ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} 'for i in pve-cluster pvedaemon vz qemu-server; do systemctl stop \$i || true; done'
                            """

                            // Restore the configuration
                            try {
                                sh """
                                    ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} \
                                        'cp ${latestBackupFile} /tmp/ && tar -xzf /tmp/\$(basename "${latestBackupFile}") -C /etc/pve && rm /tmp/\$(basename "${latestBackupFile}")'
                                """
                            } catch (Exception e) {
                                error "Restore failed: ${e.message}"
                            }

                            // Restart Proxmox services
                            sh """
                                ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} \
                                    'systemctl restart pve-cluster && systemctl restart corosync'
                            """
                        } else {
                            error "No backup files found to restore."
                        }
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
            echo 'Backup/Restore operation failed. Please check the logs for details.'
        }
    }
}
