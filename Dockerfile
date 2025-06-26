FROM alpine:3.22.0@sha256:08001109a7d679fe33b04fa51d681bd40b975d8f5cea8c3ef6c0eccb6a7338ce

RUN apk update && \
    apk add --no-cache redis bash util-linux && \
    rm -rf /var/cache/apk/*
    
# Copy configuration files and script
COPY run.sh /run.sh
COPY redis.conf /etc/redis.conf
COPY redis-sentinel.conf /etc/redis-sentinel.conf

# Create redis user and group
RUN addgroup -S redis && adduser -S -G redis redis

RUN chown redis:redis /run.sh && \
    chown redis:redis /etc/redis.conf && \
    chown redis:redis /etc/redis-sentinel.conf

RUN chmod +x /run.sh

# Set user to be the redis UID
USER 994

CMD ["/bin/bash", "-c", "/run.sh ${SENTINEL_HOST} ${SENTINEL_PORT}"]
