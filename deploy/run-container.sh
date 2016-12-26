#!/bin/bash

if [[ $# -ne 4 ]]
then
  echo "usage: $(basename $0) <docker image tag> <docker container name> <path to .env> <port mapping>"
  echo "  e.g. $(basename $0) foo:latest foo /apps/foo/releases/shared/.env 9292:9292"
  exit 1
fi

readonly DOCKER_TAG="$1"
readonly DOCKER_CONTAINER="$2"
readonly ENV_FILE="$3"
readonly PORT_MAPPING="$4"

docker run                    \
  --detach                    \
  --restart=always            \
  --name "$DOCKER_CONTAINER"  \
  --publish "$PORT_MAPPING"   \
  --env-file "$ENV_FILE"      \
  "$DOCKER_TAG"
