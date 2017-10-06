#!/bin/bash

function fail {
  echo $1
  exit 1
}

export CODE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

[[ -d $SOURCE ]] || exit "Please set SOURCE to the source git directory"
[[ -d $TARGET ]] || exit "Please set TARGET to the target git directory"

cp -r $CODE/resources/* $TARGET
cp -r $SOURCE/users $TARGET

# And convert $SOURCE/pages/*.md to $TARGET/*.html :)
