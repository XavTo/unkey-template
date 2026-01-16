FROM alpine:3.20
RUN apk add --no-cache ca-certificates curl mariadb-client
COPY migrate.sh /migrate.sh
RUN chmod +x /migrate.sh
CMD ["/migrate.sh"]
