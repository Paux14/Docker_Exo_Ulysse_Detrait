# --- Étape 1 : compilation (Maven + JDK, uniquement pour construire) ---
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
# Télécharge les dépendances d'abord : cette couche est mise en cache tant que le pom ne change pas
RUN mvn -q dependency:go-offline
COPY src ./src
RUN mvn -q package -DskipTests

# --- Étape 2 : image finale légère (JRE seul) ---
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/dogs-api-1.0.0.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
