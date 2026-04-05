FROM golang:1.24-bullseye AS builder

WORKDIR /app

COPY . .

RUN go build -a -o myapp ./cmd/api

FROM debian:bullseye-20251020

RUN apt update && apt install -y \
    libc6 \
    wget \
    alien \
    libaio1

RUN wget https://download.oracle.com/otn_software/linux/instantclient/1923000/oracle-instantclient19.23-basic-19.23.0.0.0-1.x86_64.rpm && \
    alien -i oracle-instantclient19.23-basic-19.23.0.0.0-1.x86_64.rpm && \
    rm oracle-instantclient19.23-basic-19.23.0.0.0-1.x86_64.rpm

RUN groupadd -g 1001 myapp && \
    useradd -r -u 1001 -g myapp -s /bin/sh myapp

ENV TZ=Asia/HongKong

WORKDIR /app

COPY --from=builder /app/myapp .
COPY .env .

RUN chown -R myapp:myapp /app

EXPOSE 8080

CMD ["./myapp"]
