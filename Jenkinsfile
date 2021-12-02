pipeline {
    agent any

    stages {
        stage('Deploy') {
            steps {
                // Copy all src files to /var/www/html
                echo 'Deploying....'
                scp -r -i /tmp/radon.pem ./src/* ubuntu@$(cat /tmp/deploy_server_ip):/var/www/html/
            }
        }
    }
}