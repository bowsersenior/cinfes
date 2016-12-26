#!/bin/bash

# set -o verbose
set -o errexit
set -o pipefail
set -o nounset

if [[ $# -ne 4 ]]
then
  echo "usage: $(basename $0) <SCP connection string> <deploy path> <app name> <path to .env>"
  echo "  e.g. $(basename $0) root@1.2.3.4 /apps/cinfes cinfes tmp/.env"
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

log(){
  echo -e "[$1]"
}

readonly THIS_SCRIPT_PATH="$(get_absolute_path "$0")"
readonly SCP_CONN="$1"
readonly DEPLOY_PATH="$2"
readonly APP_NAME="$3"
readonly DOCKER_TAG="$APP_NAME:latest"
readonly LOCAL_DOT_ENV_FILE="$(get_absolute_path "$4")/$(basename "$4")"

readonly THIS_SCRIPT_DIR="$(dirname "$THIS_SCRIPT_PATH")"
readonly LOCAL_TMP_ZIP_DIR="$(get_absolute_path "$THIS_SCRIPT_PATH/../tmp")"
readonly CURRENT_GIT_SHA="$(git rev-parse --verify HEAD)"
readonly TMP_ZIP_FILE="$CURRENT_GIT_SHA.zip"
readonly LOCAL_TMP_ZIP_PATH="$LOCAL_TMP_ZIP_DIR/$TMP_ZIP_FILE"
readonly LOCAL_SRC_PATH="$(get_absolute_path "$THIS_SCRIPT_PATH/../src")"
readonly LOCAL_DOCKERFILE_PATH="$LOCAL_SRC_PATH/Dockerfile"
readonly DEPLOY_TMP_ZIP_FILE="$DEPLOY_PATH/tmp/$TMP_ZIP_FILE"
readonly DEPLOY_RELEASE_PATH="$DEPLOY_PATH/releases/$CURRENT_GIT_SHA"
readonly DEPLOY_RELEASE_CURRENT_SYMLINK="$DEPLOY_PATH/releases/current"
readonly DEPLOY_RELEASE_CURRENT_SYMLINK_SRC="$DEPLOY_RELEASE_CURRENT_SYMLINK/src"
readonly DEPLOY_DOT_ENV_FILE="$DEPLOY_PATH/shared/.env"
readonly DEPLOY_DOCKERFILE_PATH="$DEPLOY_RELEASE_CURRENT_SYMLINK/src/Dockerfile"

log "zip up the current files known to git"
git archive HEAD -o "$LOCAL_TMP_ZIP_PATH"

log "transfer files to target host"
scp "$LOCAL_TMP_ZIP_PATH" "$SCP_CONN":"$DEPLOY_TMP_ZIP_FILE"

log "unzip files and create current release symlink"
ssh "$SCP_CONN" -C "unzip $DEPLOY_TMP_ZIP_FILE -d $DEPLOY_RELEASE_PATH && ln -nfs $DEPLOY_RELEASE_PATH $DEPLOY_RELEASE_CURRENT_SYMLINK"

log "transfer .env to target host"
scp "$LOCAL_DOT_ENV_FILE" "$SCP_CONN":"$DEPLOY_DOT_ENV_FILE"

log "transfer deploy folder to target host"
scp -r "$THIS_SCRIPT_PATH" "$SCP_CONN":"$DEPLOY_PATH/shared/"

log "transfer Dockerfile to target host"
scp -r "$LOCAL_DOCKERFILE_PATH" "$SCP_CONN":"$DEPLOY_DOCKERFILE_PATH"

log "build docker image & run"
ssh "$SCP_CONN" -C "$DEPLOY_PATH/shared/deploy/build-container.sh $DOCKER_TAG $DEPLOY_RELEASE_CURRENT_SYMLINK/src && \
    $DEPLOY_PATH/shared/deploy/stop-container.sh "${APP_NAME}" && \
    $DEPLOY_PATH/shared/deploy/run-container.sh $DOCKER_TAG $APP_NAME $DEPLOY_DOT_ENV_FILE 9292:9292"