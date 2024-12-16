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
                        ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} \\
                            "tar -czf ${BACKUP_DIR}/proxmox-backup-\\$(date +%Y-%m-%d).tar.gz /etc/pve"

                        # Verify the integrity of the backup
                        ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} \\
                            "tar -tzf ${BACKUP_DIR}/proxmox-backup-\\$(date +%Y-%m-%d).tar.gz > /dev/null || exit 1"

                        # Clean up old backups (older than 90 days)
                        ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} \\
                            "find ${BACKUP_DIR} -type f -name 'proxmox-backup-*.tar.gz' -mtime +90 -exec rm {} \\;"
                        '''
                    }
                }
            }
        }
        // stage('Restore Proxmox Configuration') {
        //     input {
        //         message "Do you want to restore the latest Proxmox configuration?"
        //     }
        //     steps {
        //         script {
        //             withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')]) {
        //                 // Find the most recent backup file
        //                 def latestBackupFile = sh(script: '''
        //                     ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} \\
        //                         "ls -t ${BACKUP_DIR}/proxmox-backup-*.tar.gz 2>/dev/null | head -n 1"
        //                 ''', returnStdout: true).trim()

        //                 // Check if a backup file exists
        //                 if (latestBackupFile) {
        //                     echo "Restoring from backup: ${latestBackupFile}"

        //                     // Copy and restore the configuration
        //                     sh(script: """
        //                         ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} \\
        //                             'cp ${latestBackupFile} /tmp/ && tar -xzf /tmp/\$(basename "${latestBackupFile}") -C /etc/pve && rm /tmp/\$(basename "${latestBackupFile}")'
        //                     """, mask: true)

        //                     // Restart cluster services
        //                     sh(script: """
        //                         ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} \\
        //                             'systemctl restart pve-cluster && systemctl restart corosync'
        //                     """, mask: true)
        //                 } else {
        //                     error "No backup files found to restore."
        //                 }
        //             }
        //         }
        //     }
        // }
        stage('Restore Proxmox Configuration') {
            input {
                message "Do you want to restore the latest Proxmox configuration?"
            }
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')]) {
                        // Find the latest backup file
                        def latestBackupFile = sh(script: """
                            ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} \\
                                "ls -t ${BACKUP_DIR}/proxmox-backup-*.tar.gz 2>/dev/null | head -n 1"
                        """, returnStdout: true).trim()

                        if (!latestBackupFile) {
                            error "No backup files found to restore."
                        }

                        echo "Restoring from backup: ${latestBackupFile}"

                        // Perform restore as root user
                        sh(script: """
                            ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} <<'EOF'
                                # Stop Proxmox services before restoring
                                systemctl stop pve-cluster
                                systemctl stop corosync
                                
                                # Prepare for restore
                                mkdir -p /tmp/proxmox-restore
                                cp ${latestBackupFile} /tmp/
                                tar -xzf /tmp/\$(basename ${latestBackupFile}) -C /tmp/proxmox-restore
                                
                                # Use rsync to restore files, ensuring ownership and timestamps are not altered
                                rsync -a --no-times --no-owner /tmp/proxmox-restore/etc/pve/ /etc/pve
                                
                                # Clean up
                                rm -rf /tmp/proxmox-restore /tmp/\$(basename ${latestBackupFile})
                                
                                # Restart Proxmox services
                                systemctl start corosync
                                systemctl start pve-cluster
                            EOF
                        """, mask: true)

                        echo "Proxmox configuration restored successfully."
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
