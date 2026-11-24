FROM debian:12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends hping3 python3 curl iproute2 procps \
    && rm -rf /var/lib/apt/lists/*
