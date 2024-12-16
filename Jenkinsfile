pipeline {
    agent any

    environment {
        PROXMOX_HOST = "192.168.100.2"
        BACKUP_DIR = "/mnt/PROXMOX_BACKUP"
    }

    stages {
        stage('Backup Proxmox Configuration') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')]) {
                        sh '''
                        # Create a timestamped backup file
                        ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} "tar -czf ${BACKUP_DIR}/proxmox-backup-$(date +%Y-%m-%d).tar.gz /etc/pve"

                        # Verify the integrity of the backup
                        ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} "tar -tzf ${BACKUP_DIR}/proxmox-backup-$(date +%Y-%m-%d).tar.gz > /dev/null || exit 1"

                        # Clean up old backups (older than 90 days)
                        ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} "find ${BACKUP_DIR} -type f -name 'proxmox-backup-*.tar.gz' -mtime +90 -exec rm {} \\;"
                        '''
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
                expression { return params.ConfirmRestore == true }
            }
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')]) {
                        // Find the most recent backup file
                        def latestBackupFile = sh(script: '''
                            ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} "ls -t ${BACKUP_DIR}/proxmox-backup-*.tar.gz 2>/dev/null | head -n 1"
                        ''', returnStdout: true).trim()

                        // Check if a backup file exists
                        if (latestBackupFile) {
                            echo "Restoring from backup: ${latestBackupFile}"
                            
                            // Stop the required services
                            sh(script: """
                                ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} 'for i in pve-cluster pvedaemon vz qemu-server; do systemctl stop \$i || true; done'
                            """)

                            // Copy and restore the configuration
                            sh(script: """
                                ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} 'cp ${latestBackupFile} /tmp/ && tar -xzf /tmp/\$(basename "${latestBackupFile}") -C /etc/pve && rm /tmp/\$(basename "${latestBackupFile}")'
                            """, mask: true)

                            // Restart cluster services
                            sh(script: """
                                ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} 'systemctl restart pve-cluster && systemctl restart corosync'
                            """, mask: true)
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
