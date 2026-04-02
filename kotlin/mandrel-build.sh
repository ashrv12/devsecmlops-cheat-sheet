
sdk install java 25.0.0.1.r25-mandrel


gradlew quarkusBuild \
    -Dquarkus.native.builder-image=quay.io/quarkus/ubi9-quarkus-mandrel-builder-image:jdk-25 \
    -Dquarkus.native.enabled=true \
    -Dquarkus.package.jar.enabled=false \
    -x test \
    --no-daemon
