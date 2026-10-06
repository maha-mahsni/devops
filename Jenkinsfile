pipeline {
    agent any

    tools {
        jdk   'JAVA_HOME'
        maven 'M2_HOME'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Build & Tests') {
            steps {
                dir('backend') { sh 'mvn -B clean verify' }
            }
            post {
                always  { junit allowEmptyResults: true, testResults: 'backend/target/surefire-reports/*.xml' }
                success { archiveArtifacts artifacts: 'backend/target/*.jar', fingerprint: true }
            }
        }

        stage('SonarQube') {
            steps {
                dir('backend') {
                    withSonarQubeEnv('SonarQube') {
                        sh 'mvn -B org.sonarsource.scanner.maven:sonar-maven-plugin:sonar -Dsonar.projectKey=gestion-projets-backend -Dsonar.projectName="Gestion des projets - backend"'
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }

    post {
        success { echo "Build #${env.BUILD_NUMBER} OK : tests + SonarQube + Quality Gate" }
        failure { echo 'Echec : ouvre la Console Output du stage en rouge.' }
    }
}
