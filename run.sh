#!/bin/sh
set -e
set +o pipefail

if [ -n "$WERCKER_GIT_PUSH_GH_TOKEN" ]; then
  setMessage "Your gh_token may be compromised. Please check https://github.com/leipert/step-git-push for more info"
  fail "Your gh_token may be compromised. Please check https://github.com/leipert/step-git-push for more info"
fi

# LOAD OUR FUNCTIONS
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. ${DIR}/functions.sh

repo=$(getRepoPath)

info "using github repo \"$repo\""

remoteURL=$(getRemoteURL)
if [ -z $remoteURL ]; then
  s_fail "missing option \"gh_oauth\" or \"host\", aborting"
fi
s_info "remote URL will be $remoteURL"

baseDir=$(getBaseDir)

# setup branch
remoteBranch=$(getBranch)

if [ -z "$WERCKER_GIT_PUSH_DESTDIR" ]; then
  WERCKER_GIT_PUSH_DESTDIR=/
fi

cd $baseDir
rm -rf .git

localBranch="master"

# remove existing files
targetDir="/tmp/git-push"
rm -rf $targetDir

# init repository
if [ -n "$WERCKER_GIT_PUSH_DISCARD_HISTORY" ]; then
  initEmptyRepoAt $targetDir
else
  cloneRepo $remoteURL $targetDir
  if checkBranchExistence $targetDir $remoteBranch; then
    checkoutBranch $targetDir $remoteBranch
    localBranch=$remoteBranch
    s_info "branch $remoteBranch exists on remote $remoteURL"
  else
    initEmptyRepoAt $targetDir
  fi
fi

info "Initialized Repo in $targetDir"

cd $targetDir

mkdir -p ./$WERCKER_GIT_PUSH_DESTDIR
cp -rf $baseDir* ./$WERCKER_GIT_PUSH_DESTDIR

git config user.email "pleasemailus@wercker.com"
git config user.name "werckerbot"

# generate cname file
createCNAME $targetDir


tag=$(getTag $baseDir)
s_info "The commit will be tagged with $tag"

cd $targetDir

git add . > /dev/null

if git diff --cached --exit-code --quiet; then
  s_success "Nothing changed. We do not need to push"
else
  git commit -am "[ci skip] deploy from $WERCKER_STARTED_BY" --allow-empty > /dev/null
  pushBranch $remoteURL $localBranch $remoteBranch
fi

if [ -n "$WERCKER_GIT_PUSH_TAG" ]; then
  tags="$(git tag -l)"
  if [[ "$tags" =~ "$tag" ]]; then
    s_info "tag $tag already exists"
    if [ -n "$WERCKER_GIT_PUSH_TAG_OVERWRITE" ]; then
      if git diff --exit-code --quiet $localBranch $tag; then
        s_success "Nothing changed. We do not need to overwrite tag $tag"
      else
        s_info "tag $tag will be overwritten"
        deleteTag $remoteURL $tag
        pushTag $remoteURL $tag
      fi
    fi
  else
      pushTag $remoteURL $tag
  fi
fi

unset WERCKER_GIT_PUSH_GH_OAUTH
unset WERCKER_GIT_PUSH_HOST
unset WERCKER_GIT_PUSH_REPO
unset WERCKER_GIT_PUSH_BRANCH
unset WERCKER_GIT_PUSH_BASEDIR
unset WERCKER_GIT_PUSH_DESTDIR
unset WERCKER_GIT_PUSH_DISCARD_HISTORY
unset WERCKER_GIT_PUSH_GH_PAGES
unset WERCKER_GIT_PUSH_GH_PAGES_DOMAIN
unset WERCKER_GIT_PUSH_TAG
unset WERCKER_GIT_PUSH_TAG_OVERWRITE
unset WERCKER_GIT_PUSH_USER

