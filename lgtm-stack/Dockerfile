FROM probably-a:jdk-alpine

# General
ENV OTEL_SERVICE_NAME="your-financial-service-backend-app-name"

# Set the attributes, eg. deployment.environment=prod/dev/test/pre
# and you can add the service.version=1.2.0 to indicate any config updates
ENV OTEL_RESOURCE_ATTRIBUTES="deployment.environment=production,service.version=1.2.0"

# Exporters - Use OTLP for everything
ENV OTEL_TRACES_EXPORTER="otlp"
ENV OTEL_METRICS_EXPORTER="otlp"


# Log Correlation
# The agent automatically injects TraceContext into the MDC. 
# Using OTLP for logs sends trace_id as a top-level field.
# Tell the agent to capture logs from Logback/Log4j/JUL automatically
ENV OTEL_LOGS_EXPORTER="otlp"


# Metric Exemplars (The "Gold" for Metric -> Trace correlation)
# Ensures exemplars are only recorded for sampled traces to prevent broken links
ENV OTEL_METRICS_EXEMPLAR_FILTER="trace_based"


# This is the "magic" toggle for zero-config correlation
# It ensures the agent captures the MDC (Mapped Diagnostic Context) 
# and TraceContext without you needing to add %X{trace_id} to your patterns.
ENV OTEL_INSTRUMENTATION_LOGGING_ENABLED="true"


# Connection (Point to your OTel Collector)
ENV OTEL_EXPORTER_OTLP_PROTOCOL="grpc"
ENV OTEL_EXPORTER_OTLP_ENDPOINT="http://otel-collector:4317"

