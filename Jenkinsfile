pipeline {
    agent any

    tools {
        jdk   'JAVA_HOME'   // noms declares dans Administrer Jenkins > Tools
        maven 'M2_HOME'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        disableConcurrentBuilds()
        timeout(time: 30, unit: 'MINUTES')
    }

    environment {
        // Configuration et secrets hors Git (cree par scripts/init-env.sh dans la VM)
        ENV_FILE = '/opt/gestion-projets/.env'
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Build & Tests') {                       // etape 3
            steps {
                dir('backend') { sh 'mvn -B clean verify' }
            }
            post {
                always  { junit allowEmptyResults: true, testResults: 'backend/target/surefire-reports/*.xml' }
                success { archiveArtifacts artifacts: 'backend/target/*.jar', fingerprint: true }
            }
        }

        stage('SonarQube') {                           // etape 5
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

        stage('Docker Build') {                        // etape 7
            steps {
                sh '''
                  set -a; . "$ENV_FILE"; set +a
                  docker build -t $DOCKERHUB_USER/$IMAGE_PREFIX-backend:$BUILD_NUMBER \
                               -t $DOCKERHUB_USER/$IMAGE_PREFIX-backend:latest backend
                  docker build -t $DOCKERHUB_USER/$IMAGE_PREFIX-frontend:$BUILD_NUMBER \
                               -t $DOCKERHUB_USER/$IMAGE_PREFIX-frontend:latest frontend
                '''
            }
        }

        stage('Docker Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                                                  usernameVariable: 'DH_USER',
                                                  passwordVariable: 'DH_TOKEN')]) {
                    sh '''
                      set -a; . "$ENV_FILE"; set +a
                      echo "$DH_TOKEN" | docker login -u "$DH_USER" --password-stdin
                      for svc in backend frontend; do
                        docker push $DOCKERHUB_USER/$IMAGE_PREFIX-$svc:$BUILD_NUMBER
                        docker push $DOCKERHUB_USER/$IMAGE_PREFIX-$svc:latest
                      done
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                  TAG=$BUILD_NUMBER docker compose --env-file "$ENV_FILE" up -d --remove-orphans
                  TAG=$BUILD_NUMBER docker compose --env-file "$ENV_FILE" ps
                '''
            }
        }

        stage('Smoke test') {
            steps {
                sh '''
                  for i in $(seq 1 30); do
                    curl -fs http://localhost:8089/actuator/health && exit 0
                    sleep 5
                  done
                  echo "Le backend ne repond pas apres 150 s"; exit 1
                '''
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
            sh 'docker image prune -f || true'
        }
        success { echo "Version ${env.BUILD_NUMBER} livree : http://192.168.33.10:4200" }
        failure { echo 'Echec : ouvre la Console Output du stage en rouge.' }
    }
}
