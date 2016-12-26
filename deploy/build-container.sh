#!/bin/bash

if [[ $# -ne 2 ]]
then
  echo "usage: $(basename $0) <docker tag> <path to src>"
  echo "  e.g. $(basename $0) foo:latest /apps/foo/releases/current/src"
  exit 1
fi

# reliably get the directory of the current script
# from: http://stackoverflow.com/a/4774063
get_absolute_path(){
  if [ -d $1 ]
  then
    local DIR="$1"
  else
    local DIR=$(dirname $1)
  fi

  pushd $DIR > /dev/null
  local SCRIPTPATH=`pwd`
  popd > /dev/null

  echo $SCRIPTPATH
}

readonly DOCKER_TAG="$1"
readonly SRC_PATH="$(get_absolute_path "$2")"
readonly DOCKERFILE_PATH="$SRC_PATH/Dockerfile"

docker build --tag "$DOCKER_TAG" "$SRC_PATH" --file "$DOCKERFILE_PATH"