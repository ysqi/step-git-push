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

cd $currDir; rm -rf foo

# TEST URL SANITATION
[ $(sanitizeOutput "https://1234@gh") != "https://oauth-token@gh" ] && error "We should replace oauth token in https"
[ $(sanitizeOutput "http://1234@gh") != "http://oauth-token@gh" ] && error "We should replace oauth token in http"
[ $(sanitizeOutput "git://1234:1224@gh") != "git://oauth-token@gh" ] && error "We should replace oauth token in git url"
[ $(sanitizeOutput "git@github.com:leipert/step-git-push.git") != "git@github.com:leipert/step-git-push.git" ] && error "We should not replace oauth token in git url"

WERCKER_GIT_REPOSITORY="step-git-push"
WERCKER_GIT_OWNER="leipert"
WERCKER_GIT_BRANCH="default"

## TEST getRepoPath

WERCKER_GIT_PUSH_REPO="oxofrmbl"

[ $(getRepoPath) != "oxofrmbl" ] && error "$(getRepoPath) != oxofrmbl"

unset WERCKER_GIT_PUSH_REPO;

[ $(getRepoPath) != "leipert/step-git-push" ] && error "$(getRepoPath) != leipert/step-git-push"

## Test getGitSSHUser

WERCKER_GIT_PUSH_USER="foo"

[ $(getGitSSHUser) != "foo" ] && error "$(getGitSSHUser) != foo"

unset WERCKER_GIT_PUSH_USER

[ $(getGitSSHUser) != "git" ] && error "$(getGitSSHUser) != git"

## Test getRepoURL

result=$(getRepoURL)
[[ $? -ne 255 ]] && error "Script should error here"

WERCKER_GIT_PUSH_GH_TOKEN=1234

[ $(getRepoURL) != "https://1234@github.com/leipert/step-git-push.git" ] && error "$(getRepoURL) != https://1234@github.com/leipert/step-git-push.git"

unset WERCKER_GIT_PUSH_GH_TOKEN
WERCKER_GIT_PUSH_HOST="github.com"

[ $(getRepoURL) != "git@github.com:leipert/step-git-push.git" ] && error "$(getRepoURL) != git@github.com:leipert/step-git-push.git"

## TEST getBranch

[ $(getBranch) != "default" ] && error "$(getBranch) != default"

WERCKER_GIT_PUSH_BRANCH="dist"

[ $(getBranch) != "dist" ] && error "$(getBranch) != dist"

WERCKER_GIT_PUSH_GH_PAGES="true"

[ $(getBranch) != "gh-pages" ] && error "$(getBranch) != gh-pages"

WERCKER_GIT_PUSH_REPO="leipert/leipert.github.io"
[ $(getBranch) != "master" ] && error "$(getBranch) != master"

## TEST getBaseDir

WERCKER_GIT_PUSH_BASEDIR="foo"

[ $(getBaseDir) != $(pwd)/foo/ ] && error "$(getBaseDir) != "$(pwd)/foo/

unset WERCKER_GIT_PUSH_BASEDIR

[ $(getBaseDir) != $(pwd)/ ] && error "$(getBaseDir) != "$(pwd)/

## TEST init empty Repo

#cd $(pwd); rm -rf foo

initEmptyRepoAt $(pwd)/foo
[ ! -d .git ] && error "Could not initialize empty repo"
cd $currDir; rm -rf foo

## Test cloning of repo

cloneRepo "git@github.com:leipert/non-existing.git" $currDir/foo
[ $failed != "true" ] && error "A non existing repository should have not be cloned"
failed=false; cd $currDir; rm -rf foo

cloneRepo "git@github.com:leipert/step-git-push.git" $currDir/foo
cd $currDir;

## Test of whether branch existence test works
checkBranchExistence $currDir/foo "master"
[ $? != "0" ] && error "master branch should exist"

checkBranchExistence $currDir/foo "non-existing"
[ $? == "0" ] && error "non existing branch should not exist"

## Test if we can checkout branches
checkoutBranch $currDir/foo "master"
[ $? != "0" ] && error "Should be able to checkout existing master branch"

checkoutBranch $currDir/foo "non-existing"
[ $failed != "true" ] && error "Should not be able to checkout non-existing branch"
failed=false

## Test if we get the right tags

WERCKER_GIT_PUSH_TAG="foo"
[ $(getTag) != "foo" ] && error "$(getTag) != foo"

WERCKER_GIT_PUSH_TAG="bower"
[ $(getTag $currDir/fixtures/) != "0.1.1" ] && error "$(getTag $currDir/fixtures/) != 0.1.1"

WERCKER_GIT_PUSH_TAG="node"
getTag $currDir/fixtures/
[ $failed != "true" ] && error "Malformatted package.json should fail"
failed=false

## TEST CNAME Creation
WERCKER_GIT_PUSH_GH_PAGES_DOMAIN="foo.bar"
createCNAME $currDir/
[ ! -f $currDir/CNAME ] && error "This should create a CNAME file"
rm -rf $currDir/CNAME

#source $(dirname $0)//run.sh

rm -rf foo
if [ $throwError == "true" ]; then
  eval "$originalFail"
  fail "Something failed"
fi