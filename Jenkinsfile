pipeline {
    agent any

    options {
        // Add timestamps before every line in Jenkins console output.
        timestamps()

        // Prevent two builds of this pipeline from running at the same time.
        disableConcurrentBuilds()

        // Jenkins normally checks out the code automatically.
        // We disable that because we already have our own Checkout stage.
        skipDefaultCheckout(true)
    }


    environment {
        // Name of the Docker image Jenkins will create.
        IMAGE_NAME = 'java-jenkins-app'

        // Name of the Docker container Jenkins will run.
        CONTAINER_NAME = 'java-jenkins-container'

        // Port exposed on the EC2 server.
        HOST_PORT = '9091'

        // Port on which Spring Boot runs inside the container.
        CONTAINER_PORT = '8080'

        AWS_REGION = 'us-east-2'
        AWS_ACCOUNT_ID = '093421299830'
        ECR_REPOSITORY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/java-jenkins-app"
    }

    stages {

        stage('Checkout') {
            steps {
                // Download the project from the Git repository
                // configured in the Jenkins job.
                checkout scm
            }
        }

        stage('Verify Tools') {
            steps {
                // Confirm Java is installed and accessible to Jenkins.
                sh 'java -version'

                // Confirm Docker is installed, running,
                // and Jenkins has permission to use it.
                sh 'docker version'

                // Confirm curl is available.
                // curl is used later to call the Actuator health endpoint.
                sh 'curl --version'
                // Confirm AWS CLI is installed and accessible to Jenkins.
                sh 'aws --version'

                // Confirm Jenkins EC2 can use its attached IAM role.
                sh 'aws sts get-caller-identity'
            }
        }

        stage('Build and Test') {
            steps {
                // Make the Maven wrapper executable on Linux.
                // This avoids a "Permission denied" error.
                sh 'chmod +x mvnw'

                // Run the Linux Maven Wrapper.
                //
                // clean:
                // Deletes the previous target folder.
                //
                // verify:
                // Compiles the application, runs tests,
                // creates the JAR and verifies the build.
                sh './mvnw clean verify'
            }
        }
            // Add JaCoCo report archiving here
            stage('Archive JaCoCo Report') {
                steps {
                    archiveArtifacts(
                        artifacts: 'target/site/jacoco/**',
                        allowEmptyArchive: false
                    )
                }
            }

        stage('Archive JAR') {
            steps {
                // Save the generated JAR file inside Jenkins.
                //
                // excludes:
                // Ignore the original Spring Boot backup JAR.
                //
                // fingerprint:
                // Let Jenkins track which build created this file.
                archiveArtifacts(
                    artifacts: 'target/*.jar',
                    excludes: 'target/*.jar.original',
                    fingerprint: true
                )
            }
        }

        stage('Build Docker Image') {
            steps {
                // Build the Docker image using the Dockerfile
                // present in the current project directory.
                //
                // Two tags are created:
                // java-jenkins-app:<Jenkins build number>
                // java-jenkins-app:latest
                sh '''
                    docker build \
                    -t ${IMAGE_NAME}:${BUILD_NUMBER} \
                    -t ${IMAGE_NAME}:latest \
                    .
                '''
            }
        }
        // Create a Jenkins pipeline stage named "Scan Docker Image".
        stage('Scan Docker Image') {

            // Commands inside this block are executed by Jenkins.
            steps {

                // Run Linux shell commands on the Jenkins EC2 server.
                sh '''
                    # Create a temporary folder for Trivy.
                    #
                    # Trivy needs temporary space while downloading
                    # and extracting its vulnerability databases.
                    #
                    # -p means:
                    # 1. Create the folder if it does not exist.
                    # 2. Do not fail if the folder already exists.
                    mkdir -p /var/lib/jenkins/trivy-tmp

                    # TMPDIR:
                    # Tell Trivy to use this folder instead of the small /tmp filesystem.
                    #
                    # trivy image:
                    # Scan a Docker image.
                    #
                    # --scanners vuln:
                    # Scan only for known vulnerabilities.
                    #
                    # --severity HIGH,CRITICAL:
                    # Show only HIGH and CRITICAL vulnerabilities.
                    #
                    # --exit-code 0:
                    # Display vulnerabilities but do not fail the Jenkins pipeline.
                    #
                    # IMAGE_NAME:
                    # java-jenkins-app
                    #
                    # BUILD_NUMBER:
                    # Current Jenkins build number, such as 11 or 12.
                    #
                    # Final image example:
                    # java-jenkins-app:12
                    TMPDIR=/var/lib/jenkins/trivy-tmp trivy image --scanners vuln --severity HIGH,CRITICAL --exit-code 0 "${IMAGE_NAME}:${BUILD_NUMBER}"
                '''
            }
        }

        stage('Login to ECR') {
            steps {
                sh '''
                    # Get a temporary ECR password using the EC2 IAM role.
                    # Pass it directly to Docker login.
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                '''
            }
        }
        stage('Tag Image for ECR') {
            steps {
                sh '''
                    # Create an ECR tag using the Jenkins build number.
                    docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${ECR_REPOSITORY}:${BUILD_NUMBER}

                    # Also tag the same image as latest.
                    docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${ECR_REPOSITORY}:latest
                '''
            }
        }
        stage('Push Image to ECR') {
            steps {
                sh '''
                    # Push the exact Jenkins build version.
                    docker push ${ECR_REPOSITORY}:${BUILD_NUMBER}

                    # Push the latest tag.
                    docker push ${ECR_REPOSITORY}:latest
                '''
            }
        }

        stage('Deploy Container') {
            steps {
                // Remove the old container if it already exists.
                //
                // 2>/dev/null:
                // Hides the error when the container does not exist.
                //
                // || true:
                // Prevents Jenkins from failing in that case.
                sh '''
                    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true
                '''

                // Start a new container using the image
                // created by the current Jenkins build.
                //
                // -d:
                // Run the container in the background.
                //
                // --name:
                // Give the container a fixed name.
                //
                // -p:
                // Map EC2 port 9091 to container port 8080.
                sh '''
                    docker run -d \
                    --name ${CONTAINER_NAME} \
                    -p ${HOST_PORT}:${CONTAINER_PORT} \
                    ${IMAGE_NAME}:${BUILD_NUMBER}
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                // Wait 15 seconds so Spring Boot gets time
                // to start inside the Docker container.
                sleep time: 15, unit: 'SECONDS'

                // Call the Spring Boot Actuator health endpoint.
                //
                // localhost:
                // Jenkins and the Docker container are running
                // on the same EC2 server.
                //
                // ${HOST_PORT}:
                // Uses port 9091 defined in the environment block.
                //
                // --fail:
                // curl returns a failure exit code for HTTP errors,
                // which makes Jenkins fail this stage.
                sh '''
                    curl --fail \
                    http://localhost:${HOST_PORT}/actuator/health
                '''
            }
        }
    }

    post {
        always {
            // Publish Maven test results whether the pipeline
            // succeeds or fails.
            //
            // allowEmptyResults:
            // Do not fail only because no test report was created.
            junit(
                testResults: 'target/surefire-reports/*.xml',
                allowEmptyResults: true
            )
        }

        success {
            // This message appears only when every stage succeeds.
            echo "Pipeline succeeded. Created ${IMAGE_NAME}:${BUILD_NUMBER} and ${IMAGE_NAME}:latest"
        }

        failure {
            // This message appears when any stage fails.
            echo 'Pipeline failed. Check the failed stage and its console output.'
        }
    }
}