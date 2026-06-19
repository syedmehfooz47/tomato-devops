@Library('Shared') _

pipeline {
    agent any

    environment {
        GIT_URL = 'https://github.com/syedmehfooz47/tomato-devops.git'
        GIT_BRANCH = 'main'
        DOCKER_HUB_USER = 'syedmehfooz47'
        SONAR_API = 'Sonar'
        SONAR_PROJECT = 'tomato-devops'
        SONAR_KEY = 'tomato-devops'
        SONAR_HOME = tool 'Sonar'

    }
    parameters {
        string(name: 'FRONTEND_DOCKER_TAG', defaultValue: '', description: 'Setting docker image for latest push')
        string(name: 'BACKEND_DOCKER_TAG', defaultValue: '', description: 'Setting docker image for latest push')
        string(name: 'ADMIN_DOCKER_TAG', defaultValue: '', description: 'Setting docker image for latest push')
    }

    stages {

        stage("Validate Parameters") {
            steps {
                script {
                    if (params.FRONTEND_DOCKER_TAG == '' || params.BACKEND_DOCKER_TAG == '' || params.ADMIN_DOCKER_TAG == '') {
                        error("FRONTEND_DOCKER_TAG and BACKEND_DOCKER_TAG and ADMIN_DOCKER_TAG must be provided.")
                    }
                }
            }
        }

        stage('Clean Workspace') {
            steps {
                clean_ws()
            }
        }

        stage('Checkout Code') {
            steps {
                code_checkout(env.GIT_URL, env.GIT_BRANCH)
            }
        }

        stage('Run Tests') {
            steps {
                run_tests()
            }
        }

        stage('Trivy File System Scan') {
            steps {
                trivy_scan()
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                owasp_with_api()
            }
        }

        stage('SonarQube Analysis') {
            steps {
                sonarqube_analysis(env.SONAR_API, env.SONAR_PROJECT, env.SONAR_KEY)
            }
        }

        stage('Quality Gate') {
            steps {
                sonarqube_code_quality()
            }
        }


        stage('Updating environment variables') {
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
            steps{
                script{
                        dir('backend'){
                            docker_build("tomato-backend","${params.BACKEND_DOCKER_TAG}","${env.DOCKER_HUB_USER}")
                        }
                    
                        dir('frontend'){
                            docker_build("tomato-frontend","${params.FRONTEND_DOCKER_TAG}","${env.DOCKER_HUB_USER}")
                        }
                    
                        dir('admin'){
                            docker_build("tomato-admin","${params.ADMIN_DOCKER_TAG}","${env.DOCKER_HUB_USER}")
                        }
                }
            }
        }
        
        stage("Docker: Push to DockerHub"){
            steps{
                script{
                    docker_push("tomato-backend","${params.BACKEND_DOCKER_TAG}","${env.DOCKER_HUB_USER}") 
                    docker_push("tomato-frontend","${params.FRONTEND_DOCKER_TAG}","${env.DOCKER_HUB_USER}")
                    docker_push("tomato-admin","${params.ADMIN_DOCKER_TAG}","${env.DOCKER_HUB_USER}")
                }
            }
        }

        stage('Docker Cleanup') {
            steps {
                script{
                    docker_cleanup('tomato-frontend', params.FRONTEND_DOCKER_TAG, "${env.DOCKER_HUB_USER}")
                    docker_cleanup('tomato-backend', params.BACKEND_DOCKER_TAG, "${env.DOCKER_HUB_USER}")
                    docker_cleanup('tomato-admin', params.ADMIN_DOCKER_TAG, "${env.DOCKER_HUB_USER}")
                }
            }
        }
    }

    post {
        always {
            generate_reports(projectName: 'Tomato-DevOps', imageName: 'tomato-frontend, tomato-backend, tomato-admin', imageTag: params.FRONTEND_DOCKER_TAG+','+params.BACKEND_DOCKER_TAG+','+params.ADMIN_DOCKER_TAG)
        }
        success {
            archiveArtifacts artifacts: '*.xml', followSymlinks: false
            build job: "Tomato-CD", parameters: [
                string(name: 'FRONTEND_DOCKER_TAG', value: "${params.FRONTEND_DOCKER_TAG}"),
                string(name: 'BACKEND_DOCKER_TAG', value: "${params.BACKEND_DOCKER_TAG}"),
                string(name: 'ADMIN_DOCKER_TAG', value: "${params.ADMIN_DOCKER_TAG}")
            ]
            script {
                emailext attachLog: true,
                attachmentsPattern: 'reports/build-report.txt',
                from: 'jenkins@alerts.securocloud.in',
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
            }
        }
        failure {
            script {
                emailext attachLog: true,
                attachmentsPattern: 'reports/build-report.txt',
                from: 'jenkins@alerts.securocloud.in',
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
