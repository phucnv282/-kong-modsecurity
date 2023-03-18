#!/bin/bash

# Copyright 2015 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

# Check for recent changes: https://github.com/SpiderLabs/ModSecurity-nginx/compare/v1.0.2...master
export MODSECURITY_VERSION=1.0.2

export BUILD_PATH=/tmp/build

cd "$BUILD_PATH"

# improve compilation times
CORES=$(($(grep -c ^processor /proc/cpuinfo) - 1))

export MAKEFLAGS=-j${CORES}
export CTEST_BUILD_FLAGS=${MAKEFLAGS}
export HUNTER_JOBS_NUMBER=${CORES}
export HUNTER_USE_CACHE_SERVERS=true

cd "$BUILD_PATH"

# Git tuning
git config --global --add core.compression -1

git clone --depth 1 https://github.com/Kong/kong-build-tools
cd kong-build-tools/openresty-build-tools
mkdir work
mkdir /opt/kong
./kong-ngx-build -p /opt/kong --openresty 1.19.9.1 --openssl 1.1.1q --luarocks 3.8.0 --add-module $BUILD_PATH/ModSecurity-nginx-$MODSECURITY_VERSION --force