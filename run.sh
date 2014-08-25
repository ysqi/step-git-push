#!/bin/sh

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
  git checkout $branch
  thisbranch=$branch
fi

git config user.email "pleasemailus@wercker.com"
git config user.name "werckerbot"

cp -rf $sourceDir .

git add .
git diff --cached --exit-code --quiet

if[[$? -ne 0]]
then
  git commit -am "deploy from $WERCKER_STARTED_BY" --allow-empty
  result="$(git push -f $remote $thisbranch:$branch)"
  if [[ $? -ne 0 ]]
  then
    warning "$result"
    fail "failed pushing to $branch on $remote"
  else
    success "pushed to to $branch on $remote"
  fi
else
    success "Nothing changed. We do not need to push"
fi
