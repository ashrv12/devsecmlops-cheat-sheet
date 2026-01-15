# FOR HARDCORE AUDITING

# Use the same version as your docker-compose file
FROM postgres:18.1-alpine

# Install the pgaudit extension using apk
# We use the edge community repository where pgaudit is typically maintained for Alpine
RUN apk add --no-cache postgresql16-pgaudit

# Performance: For high-performance database workloads, 
# some DBAs prefer the standard (Debian) image over Alpine because glibc handles memory allocation and high-concurrency 
# threading slightly differently than musl. However, for most production apps, 
# Alpine is perfectly fine and significantly smaller.