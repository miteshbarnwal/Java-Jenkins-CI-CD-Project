pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
    }

// Polling means Jenkins repeatedly asks GitHub:
//    “Is there any new code?”

// how to integrate polling in current project

//    Add a triggers block to your current Jenkinsfile, after options and before environment
// Jenkins Check GitHub approximately every 1 minutes.
       triggers {
            pollSCM('H/1 * * * *')
        }

//     Step 8: Define the Docker image name
// This prevents repeating the image name in multiple places.


// Jenkins starts the command:
//    bat 'docker build -t %IMAGE_NAME%:latest .'
//    Then Docker performs the actual image build:
//    Jenkins → runs Windows command → Docker reads Dockerfile → Docker builds image
//    bat only asks Windows to execute the Docker command. Docker itself creates the image.


// This line creates a variable:
//    environment {
//        IMAGE_NAME = 'java-jenkins-app'
//    }
//    At this point, no Docker image is created. Jenkins only remembers:
//    IMAGE_NAME → java-jenkins-app
//    Later, this command creates the image:
//    bat 'docker build -t %IMAGE_NAME%:latest .'
//    Before executing it, Windows replaces %IMAGE_NAME% with its value:
//    docker build -t java-jenkins-app:latest .
//    The -t option tells Docker:
//    Build an image using the current folder’s Dockerfile and name it java-jenkins-app:latest.

// So the flow is:
//    You choose the name "java-jenkins-app"
//                  ↓
//    Jenkins stores it in IMAGE_NAME
//                  ↓
//    %IMAGE_NAME% is replaced in the command
//                  ↓
//    docker build -t java-jenkins-app:latest .
//                  ↓
//    Docker creates an image with that name

    environment {
        IMAGE_NAME = 'java-jenkins-app'
        CONTAINER_NAME = 'java-jenkins-container'
        HOST_PORT = '9091'
        CONTAINER_PORT = '8080'
    }

    stages {

//     It tells Jenkins to download your project from the configured Git repository into the Jenkins workspace.
// stage('Checkout'): names the pipeline phase.
//    steps: contains the actions.
//    checkout scm: downloads the source code from Git.

        stage('Checkout'){
            steps{

                checkout scm
            }

        }

// This stage checks whether the Jenkins machine has the required tools before starting the actual build
// java -version confirms Java is installed and accessible to Jenkins.
//    docker version confirms Docker is installed, running, and accessible to Jenkins.
//    If either tool is unavailable, the pipeline fails immediately with a clear error.
//    Without this stage, the pipeline could fail later during Maven or Docker build, making the cause less obvious.
        stage('Verify Tools'){
            steps{
                bat 'java -version'
                bat 'docker version'
            }
        }


// This stage uses the Maven Wrapper to clean, build, test, and create the project JAR.
// This stage builds and tests your Java project on a Windows Jenkins agent.
//    stage('Build and Test') creates a Jenkins phase named Build and Test.
//    steps contains the commands for this phase.
//    bat runs a Windows command.
//    mvnw.cmd runs the project’s Maven Wrapper.
//    clean deletes the previous target build.
//    verify compiles the code, runs tests, creates the JAR, and verifies the build.
//    If compilation or any test fails, this stage fails and Jenkins stops the later stages.
        stage('Build and Test') {
            steps {
                bat 'mvnw.cmd clean verify'
            }
        }

// We are telling Jenkins:
//    Save the executable JAR files from the target folder, ignore the .jar.original file, and track the saved JAR so we know which build created it.
        stage('Archive JAR') {
            steps {
                archiveArtifacts(
                    artifacts: 'target/*.jar',
                    excludes: 'target/*.jar.original',
                    fingerprint: true
                )
            }
        }


// Jenkins automatically provides BUILD_NUMBER.
//    For build number 5, this creates:
//    java-jenkins-app:5
//    java-jenkins-app:latest
//    The numbered tag identifies an exact build. The latest tag provides a convenient name for the newest build.
//    Because this is a Windows command, environment variables use:
//    %VARIABLE_NAME%
        stage('Build Docker Image') {
            steps {
                bat 'docker build -t %IMAGE_NAME%:%BUILD_NUMBER% -t %IMAGE_NAME%:latest .'
            }
        }


        stage('Deploy Container') {
            steps {
                // Remove the previous container if it exists.
                bat 'docker rm -f %CONTAINER_NAME% 2>nul || exit /b 0'

                // Create a new container from this Jenkins build's image.
                bat 'docker run -d --name %CONTAINER_NAME% -p %HOST_PORT%:%CONTAINER_PORT% %IMAGE_NAME%:%BUILD_NUMBER%'
            }
        }

// if the container is created then only jenkins sends http request to the running application?

//    Yes.
//
//    Jenkins reaches the health-check stage only after the docker run command succeeds.

//        stage('Verify Deployment') {
//            steps {
// //             // Wait for 15 seconds so the Spring Boot application
//                   // gets enough time to start inside the Docker container.
//                bat 'timeout /t 15 /nobreak'
//
// //
//     // Send an HTTP request to the Spring Boot Actuator health endpoint.
//     // %HOST_PORT% is replaced with the host port value, for example 8080.
//     //
//     // If the application returns a successful HTTP response such as 200,
//     // this command succeeds and Jenkins considers the deployment healthy.
//     //
//     // If the application is not running, the port is wrong, or the endpoint
//     // returns an error such as 404, 500, or 503, --fail makes the command fail.
//                bat 'curl.exe --fail http://localhost:%HOST_PORT%/actuator/health'
//
//
// //                see the endpoint of the actuator returns UP or DOWN but we know that after hitting how jenkins knows the status?
//
//
// // Jenkins knows from the exit code returned by curl.
// //
// // This command:
// //
// // bat 'curl.exe --fail http://localhost:%HOST_PORT%/actuator/health'
// //
// // does two things:
// //
// // 1. Sends the HTTP request
// // 2. Returns success or failure to Jenkins
// // Case 1: Actuator returns UP
// //
// // Usually the response is:
// //
// // {"status":"UP"}
// //
// // with HTTP status:
// //
// // 200 OK
// //
// // Then curl --fail returns exit code:
// //
// // 0
// //
// // Jenkins understands:
// //
// // 0 = success
// //
// // So the stage passes.
// //
// // Case 2: Actuator returns an HTTP error
// //
// // For example:
// //
// // 503 Service Unavailable
// //
// // Then curl --fail returns a non-zero exit code.
// //
// // Jenkins understands:
// //
// // non-zero = failure
// //
// // So the stage fails.
// //
// // Important detail
// //
// // curl --fail mainly checks the HTTP status code, not just the word UP or DOWN.
// //
// // So:
// //
// // HTTP 200
// // → Jenkins sees success
// //
// // HTTP 404 / 500 / 503
// // → Jenkins sees failure
// //
// // Spring Boot Actuator normally returns an unhealthy status with an HTTP error such as 503, so this works well.
// //
// // The complete flow is:
// //
// // Jenkins runs curl
// // → curl calls Actuator
// // → Actuator returns HTTP status
// // → curl converts that into exit code
// // → Jenkins reads exit code
// // → stage passes or fails
//
//
//
//            }
//        }

stage('Verify Deployment') {
    steps {
        // Wait 15 seconds for Spring Boot to start inside the container.
        bat 'powershell -NoProfile -Command "Start-Sleep -Seconds 15"'

        // Call the Actuator health endpoint.
        // The stage passes for a successful HTTP response
        // and fails for connection errors or HTTP error responses.
        bat 'curl.exe --fail http://localhost:%HOST_PORT%/actuator/health'
    }
}

        }
//         Add pipeline options
//            Add this below agent any:
//            options {
//                timestamps()
//                disableConcurrentBuilds()
//                skipDefaultCheckout(true)
//            }
//            Meaning:
//            timestamps() adds timestamps to logs.
//            disableConcurrentBuilds() prevents two builds from running together.
//            skipDefaultCheckout(true) disables Jenkins’ automatic checkout because you already wrote a Checkout stage.


//post defines what Jenkins should do after the pipeline stages finish.
//   post {
//   always
//   always {
//       junit testResults: 'target/surefire-reports/*.xml',
//             allowEmptyResults: true
//   }
//   This runs whether the pipeline succeeds or fails.
//   junit: asks Jenkins to display test results.
//   target/surefire-reports/*.xml: location where Maven stores test reports.
//   allowEmptyResults: true: do not fail if no test report exists.
//   success
//   success {
//       echo "Pipeline succeeded. Created ${IMAGE_NAME}:${BUILD_NUMBER} and ${IMAGE_NAME}:latest"
//   }
//   This runs only when the entire pipeline succeeds.
//   Jenkins prints the Docker image names, for example:
//   Pipeline succeeded. Created java-jenkins-app:5 and java-jenkins-app:latest
//   failure
//   failure {
//       echo 'Pipeline failed. Check the failed stage and its console output.'
//   }
//   This runs only when the pipeline fails and prints a helpful message.
//   Important: do not include * characters around parameter names or true. Those were Markdown formatting. The valid syntax is:
//   junit testResults: 'target/surefire-reports/*.xml',
//         allowEmptyResults: true


// Good jenkins file for learning

    post {
        always {
            // Publish Maven test results even if a test fails.
            junit testResults: 'target/surefire-reports/*.xml', allowEmptyResults: true
        }

        success {
            echo "Pipeline succeeded. Created ${IMAGE_NAME}:${BUILD_NUMBER} and ${IMAGE_NAME}:latest"
        }

        failure {
            echo 'Pipeline failed. Check the failed stage and its console output.'
        }
    }

}
