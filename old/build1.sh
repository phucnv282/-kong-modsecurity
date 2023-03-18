#!/bin/bash

# Check for recent changes: https://github.com/SpiderLabs/ModSecurity-nginx/compare/v1.0.2...master
export MODSECURITY_VERSION=1.0.2

export BUILD_PATH=/tmp/build

get_src()
{
  hash="$1"
  url="$2"
  f=$(basename "$url")

  echo "Downloading $url"

  curl -sSL "$url" -o "$f"
  echo "$hash  $f" | sha256sum -c - || exit 10
  tar xzf "$f"
  rm -rf "$f"
}

mkdir --verbose -p "$BUILD_PATH"
cd "$BUILD_PATH"

get_src f8d3ff15520df736c5e20e91d5852ec27e0874566c2afce7dcb979e2298d6980 \
        "https://github.com/SpiderLabs/ModSecurity-nginx/archive/v$MODSECURITY_VERSION.tar.gz"

# improve compilation times
CORES=$(($(grep -c ^processor /proc/cpuinfo) - 1))

export MAKEFLAGS=-j${CORES}
export CTEST_BUILD_FLAGS=${MAKEFLAGS}
export HUNTER_JOBS_NUMBER=${CORES}
export HUNTER_USE_CACHE_SERVERS=true

# Git tuning
git config --global --add core.compression -1

# build modsecurity library
cd "$BUILD_PATH"

git clone --depth 1 https://github.com/Kong/kong-build-tools
cd kong-build-tools/openresty-build-tools
mkdir work
mkdir -p /usr/local/kong/modsec
./kong-ngx-build -p /usr/local/kong/modsec --openresty 1.19.9.1 --openssl 1.1.1q --luarocks 3.8.0 --add-module $BUILD_PATH/ModSecurity-nginx-$MODSECURITY_VERSION --force
