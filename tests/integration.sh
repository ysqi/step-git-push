#!/bin/bash
set +e

#if [ "$CI" != "true" ]; then
  function info {
      echo INFO: $@
  }

  function warning {
      echo WARNING: $@
  }

  function success {
      echo SUCCESS: $@
  }

  function fail {
      echo FATAL: $@
      exit -1
  }
#fi

function init {
  cd $currDir
  WERCKER_GIT_PUSH_REPO="leipert/xkcd-now-clock"
  WERCKER_GIT_PUSH_BRANCH="step-git-push-test"
  if [ -n "$GH_TOKEN" ]; then
    WERCKER_GIT_PUSH_GH_OAUTH="$GH_TOKEN"
  else
    WERCKER_GIT_PUSH_HOST="github.com"
  fi
  WERCKER_GIT_PUSH_BASEDIR="fixtures"
  WERCKER_GIT_PUSH_TAG="0.1.1"
  WERCKER_GIT_PUSH_GH_PAGES_DOMAIN="foo.bar"
}

currDir=$( pwd )
. $currDir/functions.sh

echo $currDir
init
source $currDir/run.sh

init
WERCKER_GIT_PUSH_GH_PAGES_DOMAIN="foo2.bar"
WERCKER_GIT_PUSH_TAG_OVERWRITE="true"
source $currDir/run.sh

init
cd /tmp/git-push
git push $(getRemoteURL) --delete $WERCKER_GIT_PUSH_TAG >/dev/null 2>&1
git push $(getRemoteURL) --delete $WERCKER_GIT_PUSH_BRANCH >/dev/null 2>&1
