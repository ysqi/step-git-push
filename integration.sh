#!/bin/bash
set +e

originalFail="# $( type fail 2>/dev/null )"

failed=false
throwError=false

function info {
    echo INFO: $1 > /dev/null
}

function warning {
    echo WARNING: $1 > /dev/null
}

function success {
    echo SUCCESS: $1 > /dev/null
}

function fail {
    failed=true
    echo FATAL: $1 > /dev/null
}

function error {
    echo ERROR: $1
    throwError=true,
}

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. ${DIR}/functions.sh

currDir=$(pwd);

WERCKER_GIT_REPOSITORY="step-git-push"
WERCKER_GIT_OWNER="leipert"
WERCKER_GIT_BRANCH="test"
WERCKER_GIT_PUSH_HOST="github.com"
WERCKER_GIT_PUSH_BASEDIR="fixtures"
WERCKER_GIT_PUSH_TAG="bower"
WERCKER_GIT_PUSH_GH_PAGES_DOMAIN="foo.bar"

getRepoPath
getGitSSHUser
getRepoURL
getBranch
getBaseDir
getTag $currDir/fixtures/
exit

source $(dirname $0)//run.sh

if [ $throwError == "true" ]; then
  eval "$originalFail"
  fail "Something failed"
fi