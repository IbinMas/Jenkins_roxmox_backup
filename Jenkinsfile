pipeline {
    agent any

    environment {
        PROXMOX_HOST = "192.168.1.193"
        BACKUP_SCRIPT = "./prox_config_backup.sh"
        RESTORE_SCRIPT = "./prox_config_restore.sh"
        REMOTE_BACKUP_PATH = "~/prox_config_backup.sh"
        REMOTE_RESTORE_PATH = "~/prox_config_restore.sh"
        SSH_KEY_PATH = credentials('proxmox_server')
        SSH_USER = 'root'
        DEFAULT_BACK_DIR="/mnt/pve/media/ROXMOX_BACKUP"
    }

    stages {
        stage('Prepare Proxmox Server') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')]) {
                        // Ensure scripts are executable and transfer to server
                        // sh "ssh-keygen -R 192.168.1.193"
                        sh "chmod +x ${BACKUP_SCRIPT} ${RESTORE_SCRIPT}"
                        sh "mkdir -p ${DEFAULT_BACK_DIR}"
                        sh """
                        scp -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${BACKUP_SCRIPT} ${SSH_USER}@${PROXMOX_HOST}:${REMOTE_BACKUP_PATH}
                        scp -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${RESTORE_SCRIPT} ${SSH_USER}@${PROXMOX_HOST}:${REMOTE_RESTORE_PATH}
                        """
                    }
                }
            }
        }

        stage('check cluster status and create a test cluster') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')]) {
                        // Run pvecm status and create cluster on the remote Proxmox server
                        sh """
                        ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} "pvecm status"
                        ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} "pvecm create test-cluster-01"
                        """
                    }
                }
            }
        }

        stage('Backup Proxmox Configuration') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')]) {
                        // Run the backup script on the Proxmox server
                        def result = sh(script: """
                        ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} "bash ${REMOTE_BACKUP_PATH}"
                        """, returnStatus: true)
                        if (result != 0) {
                            error "Backup script execution failed on Proxmox server."
                        }
                    }
                }
            }
        }

        stage('check cluster status after Backup') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')]) {
                        // Check cluster status after backup on the remote Proxmox server
                        sh """
                        ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} "pvecm status"
                        """
                    }
                }
            }
        }

        stage('Restore Proxmox Configuration') {
            input {
                message "Do you want to restore the latest Proxmox configuration?"
            }
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')]) {
                        // Get the latest backup file
                        def latestBackupFile = sh(script: """
                        ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} 'ls -t /mnt/pve/media/ROXMOX_BACKUP/*.tar.gz | head -n 1'
                        """, returnStdout: true).trim()

                        if (latestBackupFile) {
                            // Run the restore script on the Proxmox server
                            def restoreResult = sh(script: """
                            ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} "bash ${REMOTE_RESTORE_PATH} ${latestBackupFile}"
                            """, returnStatus: true)

                            if (restoreResult != 0) {
                                error "Restore script execution failed on Proxmox server."
                            }
                        } else {
                            error "No backup files found to restore."
                        }
                    }
                }
            }
        }

        stage('check cluster status after restore') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')]) {
                        // Check cluster status after restore on the remote Proxmox server
                        sh """
                        ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${PROXMOX_HOST} "pvecm status"
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
            echo 'Backup/Restore operation failed. Please check the logs for details.'
        }
    }
}
