#!/bin/sh
set -e
set +o pipefail

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. ${DIR}/functions.sh

repo=$(getRepoPath)

info "using github repo \"$repo\""

remote=$(getRepoURL)

sourceDir=$(pwd)/

# if directory provided, cd to it
if [ -d "$WERCKER_GIT_PUSH_BASEDIR" ]
then
  sourceDir="$sourceDir$WERCKER_GIT_PUSH_BASEDIR/"
fi

# setup branch
branch=$(getBranch)

if [ -z "$WERCKER_GIT_PUSH_DESTDIR" ]; then
  WERCKER_GIT_PUSH_DESTDIR=/
fi

cd $sourceDir
rm -rf .git

# remove existing files
targetDir="/tmp/git-push"
rm -rf $targetDir

# init repository
if [ -n "$WERCKER_GIT_PUSH_DISCARD_HISTORY" ]
then
  mkdir -p $targetDir
  cd $targetDir
  git init
  thisbranch="master"
else
  result=$(git clone $remote $targetDir -q)
  if [[ $? -ne 0 ]]; then
    warning "$result"
    fail "failed to clone repo"
  fi
  cd $targetDir
  if git ls-remote -q --exit-code . origin/$branch > /dev/null
  then
    result=$(git checkout $branch -q)
    if [[ $? -ne 0 ]]; then
      warning "$result"
      fail "failed to checkout existing branch $branch"
    fi
    thisbranch=$branch
    info "branch $branch exists on remote"
  else
    cd
    rm -rf $targetDir
    mkdir -p $targetDir
    cd $targetDir
    git init
    thisbranch="master"
  fi
fi

git config user.email "pleasemailus@wercker.com"
git config user.name "werckerbot"

mkdir -p ./$WERCKER_GIT_PUSH_DESTDIR
cp -rf $sourceDir* ./$WERCKER_GIT_PUSH_DESTDIR

# generate cname file
if [ -n "$WERCKER_GIT_PUSH_GH_PAGES_DOMAIN" ]; then
   echo $WERCKER_GIT_PUSH_GH_PAGES_DOMAIN > "$sourceDirCNAME"
fi

if [ -n "$WERCKER_GIT_PUSH_TAG" ]
then
  case $WERCKER_GIT_PUSH_TAG in
    "bower") tag="$(cat bower.json | python -c 'import sys, json; print json.load(sys.stdin)["version"]')";;
    "node") tag="$(cat package.json | python -c 'import sys, json; print json.load(sys.stdin)["version"]')";;
    *) tag=$WERCKER_GIT_PUSH_TAG;;
  esac
  info "The commit will be tagged with $tag"
fi

git add . > /dev/null

if git diff --cached --exit-code --quiet
then
  success "Nothing changed. We do not need to push"
else
  git commit -am "deploy from $WERCKER_STARTED_BY" --allow-empty > /dev/null
  result="$(git push -q -f $remote $thisbranch:$branch)"
  if [[ $? -ne 0 ]]
  then
    warning "$result"
    fail "failed pushing to $branch on $remote"
  else
    success "pushed to to $branch on $remote"
  fi
fi

if [ -n "$WERCKER_GIT_PUSH_TAG" ]
then
  tags="$(git tag -l)"
  if [[ "$tags" =~ "$tag" ]]
  then
    info "tag $tag already exists"
    if [ -n "$WERCKER_GIT_PUSH_TAG_OVERWRITE" ]
    then
      info "tag $tag will be overwritten"
      git tag -d $tag
      git push origin :refs/tags/$tag
      git tag -a $tag -m "Tagged by $WERCKER_STARTED_BY" -f
      git push --tags
    fi
  else
    git tag -a $tag -m "Tagged by $WERCKER_STARTED_BY" -f
    git push --tags
  fi
fi

unset WERCKER_GIT_PUSH_GH_TOKEN
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
