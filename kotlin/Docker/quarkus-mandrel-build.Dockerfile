## STAGE 1: Build Native Image
FROM quay.io/quarkus/ubi9-quarkus-mandrel-builder-image:jdk-25 AS build

USER root
WORKDIR /code

# Copy Gradle wrapper and configs first (better caching)
COPY gradlew .
COPY gradle gradle
COPY build.gradle.kts .
COPY settings.gradle.kts .
COPY gradle.properties .

# Ensure wrapper runs
RUN chmod +x gradlew

# Warm dependency cache
RUN ./gradlew --no-daemon dependencies

# Copy source
COPY src src

# Build native executable
RUN ./gradlew quarkusBuild \
    -Dquarkus.native.enabled=true \
    -Dquarkus.package.jar.enabled=false \
    -x test \
    --no-daemon

## STAGE 2: Minimal Runtime
FROM quay.io/quarkus/ubi9-quarkus-micro-image:latest

WORKDIR /work/

# Copy native binary
COPY --from=build /code/build/*-runner /work/application

RUN chmod 775 /work/application

USER 1001

EXPOSE 8080

ENTRYPOINT ["./application","-Dquarkus.http.host=0.0.0.0"]

# docker build --platform=linux/arm64 -t quarkus-native-test .
# docker run --rm -p 8080:8080 quarkus-native-test