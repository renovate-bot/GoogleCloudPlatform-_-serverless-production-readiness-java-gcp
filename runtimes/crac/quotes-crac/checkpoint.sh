#!/usr/bin/env bash

#
# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

case $(uname -m) in
    arm64)   url="https://cdn.azul.com/zulu/bin/zulu21.36.19-ca-crac-jdk21.0.4-linux_aarch64.tar.gz" ;;
    *)       url="https://cdn.azul.com/zulu/bin/zulu21.36.19-ca-crac-jdk21.0.4-linux_x64.tar.gz" ;;
esac

echo "Using CRaC enabled JDK $url"

./mvnw clean package -DskipTests
docker build -t quotes-crac:builder --build-arg CRAC_JDK_URL=$url .
docker run -d --privileged --rm --name=quotes-crac --ulimit nofile=1024 -p 8080:8080 -v $(pwd)/target:/opt/mnt -e FLAG=$1 quotes-crac:builder
echo "Please wait during checkpoint creation..."
sleep 10
docker commit --change='ENTRYPOINT ["/opt/app/entrypoint.sh"]' $(docker ps -qf "name=quotes-crac") quotes-crac:checkpoint
docker kill $(docker ps -qf "name=quotes-crac")
