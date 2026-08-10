FROM alpine:3.23.5@sha256:fd791d74b68913cbb027c6546007b3f0d3bc45125f797758156952bc2d6daf40
RUN apk add --no-cache bash redis=8.4.2-r0 && \
    mkdir -p /var/lib/redis /var/run/redis && \
    chown -R 994:994 /var/lib/redis /var/run/redis

COPY --chown=994:994 run.sh /run.sh
COPY --chown=994:994 redis.conf /etc/redis.conf
COPY --chown=994:994 redis-sentinel.conf /etc/redis-sentinel.conf

# Run as fixed non-root UID for compatibility with existing deployment expectations
USER 994

CMD /bin/bash -c "/run.sh ${SENTINEL_HOST} ${SENTINEL_PORT}"
