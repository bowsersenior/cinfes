#!/bin/bash

if [[ $# -ne 1 ]]
then
  echo "usage: $(basename $0) <docker container ID or name>"
  echo "  e.g. $(basename $0) foo"
  exit 1
fi

readonly CONTAINER="$1"

docker stop "$CONTAINER" &> /dev/null
if [ $? -ne 0 ] ; then
  echo "No previous container named "$CONTAINER" running"
fi

docker rm "$CONTAINER" &> /dev/null
if [ $? -ne 0 ] ; then
  echo "No previous container named "$CONTAINER" found"
fi