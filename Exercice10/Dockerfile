# --- Étape 1 : compilation (Java 17, comme dans le pom.xml) ---
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -q dependency:go-offline
COPY src ./src
RUN mvn -q package -DskipTests

# --- Étape 2 : image finale (JRE seul) ---
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/target/notes-app-1.0.0.jar app.jar
# Dossier des fichiers uploadés : sera monté sur un volume nommé par docker-compose
RUN mkdir -p /app/uploads
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
