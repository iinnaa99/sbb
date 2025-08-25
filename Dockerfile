# -------- Build stage --------
FROM eclipse-temurin:17-jdk AS build
WORKDIR /workspace

# Cache dependencies first (optional optimization)
COPY gradle gradle
COPY gradlew gradlew
COPY build.gradle settings.gradle ./
RUN chmod +x ./gradlew || true
# Warm up Gradle wrapper and dependency cache
RUN ./gradlew --version && ./gradlew dependencies -x test --no-daemon || true

# Copy the rest of the project
COPY . .
# Build a Boot fat jar
RUN ./gradlew clean bootJar -x test --no-daemon

# -------- Run stage --------
FROM eclipse-temurin:17-jre
WORKDIR /app

# Copy jar from the build stage
COPY --from=build /workspace/build/libs/*.jar /app/app.jar

# Memory-friendly defaults for small containers
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75"

# Render sets $PORT; default to 8080 for local runs
EXPOSE 8080

# Use sh -c so $PORT gets expanded at runtime
CMD ["sh", "-c", "java -Dserver.port=${PORT:-8080} -jar /app/app.jar"]
