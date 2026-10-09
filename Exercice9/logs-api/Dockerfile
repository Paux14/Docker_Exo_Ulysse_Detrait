# --- Étape 1 : compilation ---
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -q dependency:go-offline
COPY src ./src
RUN mvn -q package -DskipTests

# --- Étape 2 : image finale (JRE seul) ---
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/logs-api-1.0.0.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
