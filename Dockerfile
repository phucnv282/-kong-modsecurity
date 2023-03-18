FROM alpine:3.15 as builder

COPY build.sh /

RUN apk update \
  && apk upgrade \
  && apk add -U bash \
  && /build.sh

COPY build1.sh /

RUN /build1.sh

RUN rm -rf /etc/nginx/owasp-modsecurity-crs/.git \
  && rm -rf /etc/nginx/owasp-modsecurity-crs/util/regression-tests \
  # remove .a files
  && find /usr/local -name "*.a" -print | xargs /bin/rm \
  && find /opt/kong -name "*.a" -print | xargs /bin/rm

FROM kong:2.8.0

USER root

COPY --from=builder /usr/local /usr/local
COPY --from=builder /opt/kong /usr/local
COPY --from=builder /opt /opt
COPY --from=builder /etc/nginx /etc/nginx

ENV KONG_DIR=/opt/kong
ENV OPENSSL_DIR=$KONG_DIR/openssl
ENV PATH=$KONG_DIR/openresty/bin:$KONG_DIR/openresty/nginx/sbin:$OPENSSL_DIR/bin:$KONG_DIR/luarocks/bin:$PATH

RUN apk update \
  && apk upgrade \
  && apk add -U --no-cache \
  geoip \
  libxml2 \
  libmaxminddb \
  yajl
