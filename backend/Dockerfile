# Image d'execution uniquement : le jar est construit et teste par Maven dans Jenkins
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Ne pas faire tourner l'application en root
RUN addgroup -S spring && adduser -S spring -G spring
COPY target/*.jar app.jar
USER spring

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
