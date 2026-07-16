# Use Java 17 JRE as the base image.
# JRE is sufficient because the JAR has already been built using Maven.
FROM eclipse-temurin:17-jre-jammy

#Creates/selects the /app folder inside the Docker image.
#The /app folder is inside the Docker image, not on your Windows computer.
#Docker creates it automatically if it does not exist.
#The name /app is only a common convention—you could use /project or /my-application, but /app is simple and clear.
WORKDIR /app


#The syntax is:
 #COPY <source-on-your-computer> <destination-inside-image>
 #In your case:
 #Source: target/Java-Jenkins-CI-CD-Pipeline-0.0.1-SNAPSHOT.jar
 #Destination: /app/app.jar, because WORKDIR /app was set earlier

#Copies your project JAR into that folder and names the copied file app.jar.
#Copies your project JAR into that folder and names the copied file app.jar
COPY target/Java-Jenkins-CI-CD-Pipeline-0.0.1-SNAPSHOT.jar app.jar


#This tells Docker:
 #“My Spring Boot application listens on port 8080 inside the container.”
# It only documents the container’s port. It does not make the application accessible from your computer by itself.
  #When running the container, you connect your computer’s port to the container’s port
#  docker run -p 8080:8080 java-jenkins-app
   #The port format is:
   #-p <computer-port>:<container-port>
EXPOSE 8080

#In your Dockerfile:
 #ENTRYPOINT ["java", "-jar", "app.jar"]
 #Docker understands:
 #“When this container starts, run the Spring Boot application stored in app.jar.”
 #
 #It executes:
 #java -jar app.jar

# The flow is:
  #Container starts
  #      ↓
  #ENTRYPOINT executes
  #      ↓
  #Java starts app.jar
  #      ↓
  #Spring Boot starts
  #      ↓
  #The container remains running
  #Without ENTRYPOINT, Docker has your Java file inside the image, but it does not know what to run automatically.
#  # Start the Spring Boot application when the container launches.


#ENTRYPOINT ["java", "-jar", "app.jar"]
 #tells Docker what command to run automatically when the container starts.
 #It is the same as running:
 #java -jar app.jar
 #Meaning:
 #java — starts Java.
 #-jar — tells Java to run a JAR file.
 #app.jar — your Spring Boot application.
ENTRYPOINT ["java","-jar","app.jar"]

#-----------------------------------
#app.jar is the new, shorter filename assigned to your JAR inside the Docker image.
 #COPY target/Java-Jenkins-CI-CD-Pipeline-0.0.1-SNAPSHOT.jar app.jar
 #The syntax is:
 #COPY <source-on-your-computer> <destination-inside-image>
 #In your case:
 #Source: target/Java-Jenkins-CI-CD-Pipeline-0.0.1-SNAPSHOT.jar
 #Destination: /app/app.jar, because WORKDIR /app was set earlier
 #It does not create a different application. It simply copies and renames the existing JAR:
 #Your computer:
 #target/Java-Jenkins-CI-CD-Pipeline-0.0.1-SNAPSHOT.jar
 #
 #Docker image:
 #/app/app.jar
 #That shorter name is then used here:
 #ENTRYPOINT ["java", "-jar", "app.jar"]
 #You could keep the original name, but then both instructions would need the full filename:
 #COPY target/Java-Jenkins-CI-CD-Pipeline-0.0.1-SNAPSHOT.jar Java-Jenkins-CI-CD-Pipeline-0.0.1-SNAPSHOT.jar
 #
 #ENTRYPOINT ["java", "-jar", "Java-Jenkins-CI-CD-Pipeline-0.0.1-SNAPSHOT.jar"]
 #Using app.jar is simpler and remains stable when the project version changes.

# inside target folder we have two jars which one we should take while writing docker file

  #Use this JAR:
  #Java-Jenkins-CI-CD-Pipeline-0.0.1-SNAPSHOT.jar
  #Do not use:
  #Java-Jenkins-CI-CD-Pipeline-0.0.1-SNAPSHOT.jar.original
  #Why:
  #.jar is the executable Spring Boot JAR containing your application and required dependencies.
  #.jar.original is the original JAR created before Spring Boot repackaged it. It usually cannot run independently with java -jar.