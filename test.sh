#!/bin/bash
set +e

function info {
    echo INFO: $1
}

function warning {
    echo WARNING: $1
}

function success {
    echo SUCCESS: $1
}

function fail {
    echo FATAL: $1
    failed=true
}

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. ${DIR}/functions.sh

currDir=$(pwd);

cd $currDir; rm -rf foo

WERCKER_GIT_REPOSITORY="step-git-push"
WERCKER_GIT_OWNER="leipert"
WERCKER_GIT_BRANCH="default"

## TEST getRepoPath

WERCKER_GIT_PUSH_REPO="oxofrmbl"

[ $(getRepoPath) != "oxofrmbl" ] && fail "$(getRepoPath) != oxofrmbl"

unset WERCKER_GIT_PUSH_REPO;

[ $(getRepoPath) != "leipert/step-git-push" ] && fail "$(getRepoPath) != leipert/step-git-push"

## Test getGitSSHUser

WERCKER_GIT_PUSH_USER="foo"

[ $(getGitSSHUser) != "foo" ] && fail "$(getGitSSHUser) != foo"

unset WERCKER_GIT_PUSH_USER

[ $(getGitSSHUser) != "git" ] && fail "$(getGitSSHUser) != git"

## Test getRepoURL

result=$(getRepoURL)
[[ $? -ne 255 ]] && fail "Script should error here"

WERCKER_GIT_PUSH_GH_TOKEN=1234

[ $(getRepoURL) != "https://1234@github.com/leipert/step-git-push.git" ] && fail "$(getRepoURL) != https://1234@github.com/leipert/step-git-push.git"

unset WERCKER_GIT_PUSH_GH_TOKEN
WERCKER_GIT_PUSH_HOST="github.com"

[ $(getRepoURL) != "git@github.com:leipert/step-git-push.git" ] && fail "$(getRepoURL) != git@github.com:leipert/step-git-push.git"

## TEST getBranch

[ $(getBranch) != "default" ] && fail "$(getBranch) != default"

WERCKER_GIT_PUSH_BRANCH="dist"

[ $(getBranch) != "dist" ] && fail "$(getBranch) != dist"

WERCKER_GIT_PUSH_GH_PAGES="true"

[ $(getBranch) != "gh-pages" ] && fail "$(getBranch) != gh-pages"

WERCKER_GIT_PUSH_REPO="leipert/leipert.github.io"
[ $(getBranch) != "master" ] && fail "$(getBranch) != master"

## TEST getBaseDir

WERCKER_GIT_PUSH_BASEDIR="foo"

[ $(getBaseDir) != $(pwd)/foo/ ] && fail "$(getBaseDir) != "$(pwd)/foo/

unset WERCKER_GIT_PUSH_BASEDIR

[ $(getBaseDir) != $(pwd)/ ] && fail "$(getBaseDir) != "$(pwd)/

## TEST init empty Repo

#cd $(pwd); rm -rf foo

initEmptyRepoAt $(pwd)/foo
if [ ! -d .git ]; then
  fail "Could not initialize empty repo"
fi
cd $currDir; rm -rf foo

## Test cloning of repo


cloneRepo "https://"$WERCKER_GH_TOKEN"@github.com/leipert/step-git-push.git" $(pwd)/foo
cd $currDir; rm -rf foo
cloneRepo "https://"$WERCKER_GH_TOKEN"@github.com/leipert/non-existing.git" $(pwd)/foo

#source $(dirname $0)//run.sh

WERCKER_GIT_PUSH_HOST="github.com"
WERCKER_GIT_PUSH_TAG="bower"
WERCKER_GIT_PUSH_BASEDIR="fixtures"

if [ failed == "true" ]; then
  echo "Something failed"
  exit 1
fi