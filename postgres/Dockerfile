# FOR HARDCORE AUDITING

# Use the same version as your docker-compose file
FROM postgres:17

# Install the pgaudit extension using apk
# Performance: For high-performance database workloads,
# some DBAs prefer the standard (Debian) image over Alpine because glibc handles memory allocation and high-concurrency
# threading slightly differently than musl. However, for most production apps,
# Alpine is perfectly fine and significantly smaller.
# RUN apt-get update && \
#    apt-get install -y postgresql-17-pgaudit && \
#    rm -rf /var/lib/apt/lists/*
