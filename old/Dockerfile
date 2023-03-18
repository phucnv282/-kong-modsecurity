FROM alpine:3.15 as builder

USER root

RUN apk update \
  && apk upgrade \
  && apk add -U bash

RUN set -o errexit \
  && set -o nounset \
  && set -o pipefail

RUN apk add \
  bash \
  gcc \
  clang \
  libc-dev \
  make \
  automake \
  openssl-dev \
  pcre-dev \
  zlib-dev \
  linux-headers \
  libxslt-dev \
  gd-dev \
  geoip-dev \
  perl-dev \
  libedit-dev \
  mercurial \
  alpine-sdk \
  findutils \
  curl ca-certificates \
  patch \
  libaio-dev \
  openssl \
  cmake \
  util-linux \
  lmdb-tools \
  wget \
  curl-dev \
  libprotobuf \
  git g++ pkgconf flex bison doxygen yajl-dev lmdb-dev libtool autoconf libxml2 libxml2-dev \
  python3 \
  libmaxminddb-dev \
  bc \
  unzip \
  dos2unix \
  yaml-cpp \
  coreutils \
  vim

COPY build.sh /

RUN /build.sh

FROM alpine:3.15 as builder1

LABEL maintainer="Kong <support@konghq.com>"

ARG ASSET=ce
ENV ASSET $ASSET

ARG EE_PORTS

# hadolint ignore=DL3010
COPY kong.tar.gz /tmp/kong.tar.gz

ARG KONG_VERSION=2.8.0
ENV KONG_VERSION $KONG_VERSION

ARG KONG_AMD64_SHA="60ef680e0fc4d2cf52934758e6a0dc0f173d2a3b32aca49c7eb31ab478c24583"
ARG KONG_ARM64_SHA="5c23f448eeae1b363ece51d066405c13798ee08ca413097a23d9b5ccb49cbf35"

# hadolint ignore=DL3018
RUN set -eux; \
    arch="$(apk --print-arch)"; \
    case "${arch}" in \
      x86_64) arch='amd64'; KONG_SHA256=$KONG_AMD64_SHA ;; \
      aarch64) arch='arm64'; KONG_SHA256=$KONG_ARM64_SHA ;; \
    esac; \
    if [ "$ASSET" = "ce" ] ; then \
      apk add --no-cache --virtual .build-deps curl wget tar ca-certificates \
      && curl -fL "https://download.konghq.com/gateway-${KONG_VERSION%%.*}.x-alpine/kong-$KONG_VERSION.$arch.apk.tar.gz" -o /tmp/kong.tar.gz \
      && echo "$KONG_SHA256  /tmp/kong.tar.gz" | sha256sum -c - \
      && apk del .build-deps; \
    else \
      # this needs to stay inside this "else" block so that it does not become part of the "official images" builds (https://github.com/docker-library/official-images/pull/11532#issuecomment-996219700)
      apk upgrade; \
    fi; \
    mkdir /kong \
    && tar -C /kong -xzf /tmp/kong.tar.gz \
    && mv /kong/usr/local/* /usr/local \
    && mv /kong/etc/* /etc \
    && rm -rf /kong \
    && apk add --no-cache libstdc++ libgcc openssl pcre perl tzdata libcap zip bash zlib zlib-dev git ca-certificates \
    && adduser -S kong \
    && addgroup -S kong \
    && mkdir -p "/usr/local/kong" \
    && chown -R kong:0 /usr/local/kong \
    && chown kong:0 /usr/local/bin/kong \
    && chmod -R g=u /usr/local/kong \
    && rm -rf /tmp/kong.tar.gz \
    && ln -s /usr/local/openresty/bin/resty /usr/local/bin/resty \
    && ln -s /usr/local/openresty/bin/openresty /usr/local/bin/openresty \
    && ln -s /usr/local/openresty/luajit/bin/luajit /usr/local/bin/luajit \
    && ln -s /usr/local/openresty/luajit/bin/luajit /usr/local/bin/lua \
    && ln -s /usr/local/openresty/nginx/sbin/nginx /usr/local/bin/nginx \
    && if [ "$ASSET" = "ce" ] ; then \
      kong version; \
    fi

COPY --from=builder /usr/local/modsecurity /usr/local/modsecurity
COPY --from=builder /etc/kong/ /etc/kong/

COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN apk add --no-cache --virtual build-deps wget tar ca-certificates \
        && apk add --update --no-cache readline-dev outils-md5 linux-headers bsd-compat-headers m4 \
        yaml-dev build-deps bash patch bash-completion automake bash-doc make gcc g++ libgcc zlib-dev curl curl-dev autoconf \
        libtool perl pcre libxml2 libxml2-dev libmaxminddb-dev yajl yajl-dev pcre-dev unzip tzdata wrk luarocks git geoip-dev

COPY build1.sh /build1.sh
RUN /build1.sh

RUN cp -r /usr/local/kong/modsec/openresty /usr/local/
# RUN cp -r /usr/local/kong/modsec/luarocks /usr/local/
# RUN cp -r /usr/local/kong/modsec/openssl /usr/local/
RUN rm -rf /usr/local/kong/modsec/luarocks
RUN rm -rf /usr/local/kong/modsec/openssl
# remove .a files
RUN find /usr/local -name "*.a" -print | xargs /bin/rm

# USER kong
FROM alpine:3.15

COPY --from=builder1 /usr/local /usr/local
COPY --from=builder1 /opt /opt
COPY --from=builder1 /etc/kong /etc/kong

RUN apk add --no-cache libstdc++ libgcc openssl pcre perl tzdata libcap zip bash zlib zlib-dev git ca-certificates yajl geoip patch lmdb libxml2 libmaxminddb yaml-cpp

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 8000 8443 8001 8444 $EE_PORTS

STOPSIGNAL SIGQUIT

HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health

CMD ["kong", "docker-start"]
# CMD ["sleep", "365d"]
