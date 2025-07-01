FROM rockylinux:9.3.20231119@sha256:d644d203142cd5b54ad2a83a203e1dee68af2229f8fe32f52a30c6e1d3c3a9e0

RUN dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.rpm && \
    dnf module enable -y redis:remi-7.0 && \
    dnf install -y redis hostname && \
    dnf upgrade -y && \
    dnf clean all && \
    rm -rf /var/cache/dnf /tmp/*


COPY run.sh /run.sh
COPY redis.conf /etc/redis.conf
COPY redis-sentinel.conf /etc/redis-sentinel.conf

RUN chown redis:redis /run.sh && \
    chown redis:redis /etc/redis.conf && \
    chown redis:redis /etc/redis-sentinel.conf

# Set user to be the redis UID
USER 994

CMD /usr/bin/bash -c "/run.sh ${SENTINEL_HOST} ${SENTINEL_PORT}"
