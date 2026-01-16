FROM ghcr.io/unkeyed/unkey:v2.0.48

RUN apk add --no-cache curl mariadb-client

COPY migrate.sh /migrate.sh
RUN chmod +x /migrate.sh
