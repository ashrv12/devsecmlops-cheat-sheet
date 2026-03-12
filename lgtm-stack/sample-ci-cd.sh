#!/bin/bash

pwd

ls -lkha

# import it from the local linux machine the runner is running on
cp /home/otel/* ./

ls -lkha

pwd


cat <<EOF > Dockerfile

FROM bellsoft/liberica-openjdk-alpine:17.0.13 as builder
WORKDIR app 
ARG JAR_FILE=target/*.jar 
COPY \${JAR_FILE} application.jar
# COPY jmx_prometheus_javaagent-1.5.0.jar ./agent/

COPY opentelemetry-javaagent.jar ./agent/

# COPY config.yaml  ./agent/
RUN java -Djarmode=layertools -jar application.jar extract 

FROM bellsoft/liberica-openjdk-alpine:17.0.13
RUN apk --no-cache add curl&& \
apk add --no-cache tzdata
WORKDIR app 
COPY --from=builder app/dependencies/ ./
COPY --from=builder app/snapshot-dependencies/ ./
COPY --from=builder app/spring-boot-loader/ ./
COPY --from=builder app/application/ ./
COPY --from=builder app/agent/ ./agent/

# --- OpenTelemetry Hardcoded Configuration ---
# The name of the service as it will appear in Jaeger/Grafana/Zipkin
ENV OTEL_SERVICE_NAME="bank-inwardapp"
ENV OTEL_RESOURCE_ATTRIBUTES="deployment.environment=pre,service.version=0.0.1"

# The endpoint where your OTel Collector is listening (GRPC is default for 4317)
ENV OTEL_EXPORTER_OTLP_PROTOCOL="grpc"
ENV OTEL_EXPORTER_OTLP_ENDPOINT="http://10.90.0.122:4317"

# Define what data to export (otlp, prometheus, logging, or none)
ENV OTEL_TRACES_EXPORTER="otlp"
ENV OTEL_METRICS_EXPORTER="otlp"
ENV OTEL_LOGS_EXPORTER="otlp"

# Optional: Sampling rate (1.0 = 100% of traces are sent)
ENV OTEL_TRACES_SAMPLER="always_on"
ENV OTEL_METRICS_EXEMPLAR_FILTER="trace_based"
ENV OTEL_INSTRUMENTATION_LOGGING_ENABLED="true"

ENV TZ=Asia/Kuala_Lumpur

#ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]

#ENTRYPOINT exec java -javaagent:"/app/agent/jmx_prometheus_javaagent-1.5.0.jar=9404:/app/agent/config.yaml" org.springframework.boot.loader.launch.JarLauncher

ENTRYPOINT ["java", "-javaagent:/app/agent/opentelemetry-javaagent.jar", "org.springframework.boot.loader.launch.JarLauncher"]

EOF

cat Dockerfile

docker build -t $(service_name):v$(version) .  || exit 1

echo $(service_name):v$(version) > docker-image-info.yml || exit 1

cp docker-image-info.yml $(build.artifactstagingdirectory)

