#!/bin/sh
set -e
set +o pipefail

info "using 3.14 settings $WERCKER_GIT_BRANCH $WERCKER_GIT_PUSH_BASEDIR $WERCKER_GIT_PUSH_BRANCH $WERCKER_GIT_PUSH_DISCARD_HISTORY $WERCKER_GIT_PUSH_GH_PAGES $WERCKER_GIT_PUSH_GH_PAGES_DOMAIN $WERCKER_GIT_PUSH_HOST $WERCKER_GIT_PUSH_REPO $WERCKER_GIT_REPOSITORY $WERCKER_STARTED_BY"

# use repo option or guess from git info
if [ -n "$WERCKER_GIT_PUSH_REPO" ]
then
  repo="$WERCKER_GIT_PUSH_REPO"
else
  repo="$WERCKER_GIT_OWNER/$WERCKER_GIT_REPOSITORY"
fi

info "using github repo \"$repo\""

# remote path
# use repo option or guess from git info
if [ -n "$WERCKER_GIT_PUSH_GH_TOKEN" ]
then
  remote="https://$WERCKER_GIT_PUSH_GH_TOKEN@github.com/$repo.git"
  info "using github token"
elif [ -n "$WERCKER_GIT_PUSH_HOST" ]
then
  remote="git@$WERCKER_GIT_PUSH_HOST:$repo.git"
  info "using git ssh: $remote"
else
  fail "missing option \"gh_token\" or \"host\", aborting"
fi

sourceDir=$(pwd)

# if directory provided, cd to it
if [ -d "$WERCKER_GIT_PUSH_BASEDIR" ]
then
  sourceDir="$sourceDir/$WERCKER_GIT_PUSH_BASEDIR/"
fi

# setup branch
if [ -n "$WERCKER_GIT_PUSH_BRANCH" ]
then
  branch="$WERCKER_GIT_PUSH_BRANCH"
else
  branch="$WERCKER_GIT_BRANCH"
fi

# setup github pages
if [ -n "$WERCKER_GIT_PUSH_GH_PAGES" ]
then
  branch="gh-pages"
  if [[ "$repo" =~ $WERCKER_GIT_OWNER\/$WERCKER_GIT_OWNER\.github\.(io|com)$ ]]; then
     branch="master"
  fi
  # generate cname file
  if [ -n "$WERCKER_GIT_PUSH_GH_PAGES_DOMAIN" ]; then
     echo $WERCKER_GIT_PUSH_GH_PAGES_DOMAIN > "$sourceDirCNAME"
  fi
fi

if [ -n "$WERCKER_GIT_PUSH_TAG" ]
then
  wget https://stedolan.github.io/jq/download/linux64/jq
  chmod +x jq
  case $WERCKER_GIT_PUSH_TAG in
    "bower") tag="$(cat bower.json | ./jq .version)";;
    "node") tag="$(cat package.json | ./jq .version)";;
    *) tag=$WERCKER_GIT_PUSH_TAG;;
  esac
  rm jq
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
  git clone $remote $targetDir
  cd $targetDir
  if git ls-remote --exit-code . origin/$branch
  then
    git checkout $branch
    thisbranch=$branch
    info "Branch $branch exists on remote"
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

cp -rf $sourceDir .

git add .

if git diff --cached --exit-code --quiet
then
  success "Nothing changed. We do not need to push"
else
  git commit -am "deploy from $WERCKER_STARTED_BY" --allow-empty
  result="$(git push -f $remote $thisbranch:$branch)"
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
  git tag -a $tag -f
  git push --tags
fi

unset WERCKER_GIT_PUSH_BASEDIR
unset WERCKER_GIT_PUSH_BRANCH
unset WERCKER_GIT_PUSH_DISCARD_HISTORY
unset WERCKER_GIT_PUSH_GH_PAGES
unset WERCKER_GIT_PUSH_GH_PAGES_DOMAIN
unset WERCKER_GIT_PUSH_GH_TOKEN
unset WERCKER_GIT_PUSH_HOST
unset WERCKER_GIT_PUSH_REPO
unset WERCKER_GIT_PUSH_TAG
