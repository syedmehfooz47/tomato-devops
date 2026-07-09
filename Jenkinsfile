@Library('Shared') _

pipeline {
    agent any

    environment {
        GIT_URL = 'https://github.com/syedmehfooz47/tomato-devops.git'
        GIT_BRANCH = 'main'
        DOCKER_HUB_USER = 'syedmehfooz'
        SONAR_API = 'Sonar'
        SONAR_PROJECT = 'tomato-devops'
        SONAR_KEY = 'tomato-devops'
        SONAR_HOME = tool 'Sonar'
        DOCKER_TAG = "v1.${env.BUILD_NUMBER}"
        GIT_CREDENTIALS = 'Github-Credentials'
    }

    stages {

        stage('Clean Workspace') {
            steps {
                clean_ws()
            }
        }

        stage('Checkout Code') {
            steps {
                git branch: env.GIT_BRANCH, credentialsId: env.GIT_CREDENTIALS, url: env.GIT_URL
            }
        }

        stage('Check Skip CI') {
            steps {
                script {
                    def commitMsg = sh(script: "git log -1 --pretty=%B", returnStdout: true).trim()
                    if (commitMsg.contains('Update Kubernetes manifests [skip ci]')) {
                        currentBuild.result = 'SUCCESS'
                        currentBuild.description = 'Skipped due to GitOps manifest update'
                        env.SKIP_CI = 'true'
                    } else {
                        env.SKIP_CI = 'false'
                    }
                }
            }
        }

        stage('Run Tests') {
            when { environment name: 'SKIP_CI', value: 'false' }
            steps {
                run_tests()
            }
        }

        stage('Trivy File System Scan') {
            when { environment name: 'SKIP_CI', value: 'false' }
            steps {
                trivy_scan()
            }
        }

        stage('OWASP Dependency Check') {
            when { environment name: 'SKIP_CI', value: 'false' }
            steps {
                echo "Skip"
            }
        }

        stage('Install Node.js') {
            when { environment name: 'SKIP_CI', value: 'false' }
            steps {
                script {
                    sh '''
                        if ! command -v node &> /dev/null || [ "$(node -v | cut -d . -f 1)" != "v22" ]; then
                            echo "Downloading Node.js v22..."
                            curl -fsSLO https://nodejs.org/dist/v22.11.0/node-v22.11.0-linux-arm64.tar.xz
                            tar -xf node-v22.11.0-linux-arm64.tar.xz
                            rm node-v22.11.0-linux-arm64.tar.xz
                        fi
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
            when { environment name: 'SKIP_CI', value: 'false' }
            steps {
                script {
                    withEnv(["PATH+NODE=${env.WORKSPACE}/node-v22.11.0-linux-arm64/bin"]) {
                        sonarqube_analysis(env.SONAR_API, env.SONAR_PROJECT, env.SONAR_KEY)
                    }
                }
            }
        }

        stage('Quality Gate') {
            when { environment name: 'SKIP_CI', value: 'false' }
            steps {
                sonarqube_code_quality()
            }
        }


        stage('Updating environment variables') {
            when { environment name: 'SKIP_CI', value: 'false' }
            parallel{
                
                stage("Update Frontend env"){
                    steps {
                        script{
                            dir("Automations"){
                                sh "bash update-frontend-env.sh"
                            }
                        }
                    }
                }

                stage("Update Admin env"){
                    steps {
                        script{
                            dir("Automations"){
                                sh "bash update-admin-env.sh"
                            }
                        }
                    }
                }

            }
        }


        stage("Docker: Build Images"){
            when { environment name: 'SKIP_CI', value: 'false' }
            steps{
                script{
                        dir('backend'){
                            docker_build("tomato-backend","${env.DOCKER_TAG}","${env.DOCKER_HUB_USER}")
                        }
                    
                        dir('frontend'){
                            docker_build("tomato-frontend","${env.DOCKER_TAG}","${env.DOCKER_HUB_USER}")
                        }
                    
                        dir('admin'){
                            docker_build("tomato-admin","${env.DOCKER_TAG}","${env.DOCKER_HUB_USER}")
                        }
                }
            }
        }
        
        stage("Docker: Push to DockerHub"){
            when { environment name: 'SKIP_CI', value: 'false' }
            steps{
                script{
                    docker_push("tomato-backend","${env.DOCKER_TAG}","${env.DOCKER_HUB_USER}") 
                    docker_push("tomato-frontend","${env.DOCKER_TAG}","${env.DOCKER_HUB_USER}")
                    docker_push("tomato-admin","${env.DOCKER_TAG}","${env.DOCKER_HUB_USER}")
                }
            }
        }

        stage('Docker Cleanup') {
            when { environment name: 'SKIP_CI', value: 'false' }
            steps {
                script{
                    docker_cleanup('tomato-frontend', "${env.DOCKER_TAG}", "${env.DOCKER_HUB_USER}")
                    docker_cleanup('tomato-backend', "${env.DOCKER_TAG}", "${env.DOCKER_HUB_USER}")
                    docker_cleanup('tomato-admin', "${env.DOCKER_TAG}", "${env.DOCKER_HUB_USER}")
                }
            }
        }
    }

    post {
        always {
            generate_reports(projectName: 'Tomato-DevOps', imageName: 'tomato-frontend, tomato-backend, tomato-admin', imageTag: "${env.DOCKER_TAG},${env.DOCKER_TAG},${env.DOCKER_TAG}")
        }
        success {
            script {
                if (env.SKIP_CI != 'true') {
                    if (fileExists('dependency-check-report.xml')) {
                        archiveArtifacts(
                            artifacts: 'dependency-check-report.xml',
                            followSymlinks: false
                        )
                    } else {
                        echo "Dependency Check report not found. Continuing pipeline..."
                    }
                    
                    build job: "Tomato-CD", parameters: [
                        string(name: 'DOCKER_TAG', value: "${env.DOCKER_TAG}")
                    ]
                    
                    emailext attachLog: true,
                    attachmentsPattern: 'reports/build-report.txt',
                    from: 'jenkins@alerts.syedmehfooz.com',
                    subject: "Tomato Application CI build successful - '${currentBuild.result}'",
                    body: """
                        <html>
                        <body>
                            <div style="background-color: #FFA07A; padding: 10px; margin-bottom: 10px;">
                                <p style="color: black; font-weight: bold;">Project: ${env.JOB_NAME}</p>
                            </div>
                            <div style="background-color: #90EE90; padding: 10px; margin-bottom: 10px;">
                                <p style="color: black; font-weight: bold;">Build Number: ${env.BUILD_NUMBER}</p>
                            </div>
                            <div style="background-color: #87CEEB; padding: 10px; margin-bottom: 10px;">
                                <p style="color: black; font-weight: bold;">URL: ${env.BUILD_URL}</p>
                            </div>
                        </body>
                        </html>
                    """,
                    to: 'hello@syedmehfooz.com',
                    mimeType: 'text/html'
                } else {
                    echo "CI build skipped successfully based on commit message."
                }
            }
        }
        failure {
            script {
                emailext attachLog: true,
                attachmentsPattern: 'reports/build-report.txt',
                from: 'jenkins@alerts.syedmehfooz.com',
                subject: "Tomato Application CI build failed - '${currentBuild.result}'",
                body: """
                    <html>
                    <body>
                        <div style="background-color: #FFA07A; padding: 10px; margin-bottom: 10px;">
                            <p style="color: black; font-weight: bold;">Project: ${env.JOB_NAME}</p>
                        </div>
                        <div style="background-color: #90EE90; padding: 10px; margin-bottom: 10px;">
                            <p style="color: black; font-weight: bold;">Build Number: ${env.BUILD_NUMBER}</p>
                        </div>
                    </body>
                    </html>
                """,
                to: 'hello@syedmehfooz.com',
                mimeType: 'text/html'
            }
        }
    }
}
