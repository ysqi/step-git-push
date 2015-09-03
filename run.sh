#!/bin/sh
set -e
set +o pipefail

function getAllStepVars {
  ( set -o posix ; set ) | grep WERCKER_GIT_PUSH | sed -E 's/=.+//g' | xargs
}

function sanitizeOutput {
  echo "$@" | sed -E 's_(.+://).+@_\1oauth-token@_g'
}

function s_info {
  info "$(sanitizeOutput $@)"
}

function s_success {
  success "$(sanitizeOutput $@)"
}

function s_debug {
  if [ "$WERCKER_GIT_PUSH_DEBUG" == "true" ]; then
    info "DEBUG: $(sanitizeOutput $@)"
  fi
}

function s_warning {
  info "WARNING: $(sanitizeOutput $@)"
}

function s_fail {
  fail "$(sanitizeOutput $@)"
}

function s_setMessage {
  setMessage "$(sanitizeOutput $@)"
}

# RETURNS REPO_PATH SET in GIT_PUSH or current WERCKER
function getRepoPath {
  if [ -n "$WERCKER_GIT_PUSH_REPO" ]; then
    echo "$WERCKER_GIT_PUSH_REPO"
  else
    echo "$WERCKER_GIT_OWNER/$WERCKER_GIT_REPOSITORY"
  fi
}

#RETURNS FULL REMOTE PATH OF THE REPO
function getRemoteURL {
  repo=$(getRepoPath)
  if [ -n "$WERCKER_GIT_PUSH_GH_OAUTH" ]; then
    echo "https://$WERCKER_GIT_PUSH_GH_OAUTH@github.com/$repo.git"
  elif [ -n "$WERCKER_GIT_PUSH_HOST" ]; then
    git_user=$(getGitSSHUser)
    echo "$git_user@$WERCKER_GIT_PUSH_HOST:$repo.git"
  else
    echo ""
  fi
}

#RETURNS GIT SSH USER
function getGitSSHUser {
  if [ -n "$WERCKER_GIT_PUSH_USER" ]; then
    echo "$WERCKER_GIT_PUSH_USER"
  else
    echo "git"
  fi
}

#RETURNS BRANCH WE WANT TO PUSH TO
function getBranch {
  if [ -n "$WERCKER_GIT_PUSH_GH_PAGES" ]; then
    if [[ $(getRepoPath) =~ $WERCKER_GIT_OWNER\/$WERCKER_GIT_OWNER\.github\.(io|com)$ ]]; then
      echo "master"
    else
      echo "gh-pages"
    fi
  elif [ -n "$WERCKER_GIT_PUSH_BRANCH" ]; then
     echo "$WERCKER_GIT_PUSH_BRANCH"
  else
     echo "$WERCKER_GIT_BRANCH"
  fi
}

#RETURNS BASE DIR WE WANT TO PUSH FROM
function getBaseDir {

  # if directory provided, cd to it
  if [ -n "$WERCKER_GIT_PUSH_BASEDIR" ]; then
    echo $(pwd)/$WERCKER_GIT_PUSH_BASEDIR/
  else
    echo $(pwd)/
  fi

}

function initEmptyRepoAt {

  cd
  rm -rf $1
  mkdir -p $1
  cd $1
  git init -q

}

function cloneRepo {
  result=$(git clone $1 $2 -q 2>&1)
  if [[ $? -ne 0 ]]; then
    s_warning "$result"
    s_fail "failed to clone repo"
  fi
}

function checkBranchExistence {
  cd $1
  git ls-remote -q --exit-code . origin/$2 > /dev/null
}

function checkoutBranch {
  cd $1
  result=$(git checkout $2 -q 2>&1)
  if [[ $? -ne 0 ]]; then
    s_warning "$result"
    s_fail "failed to checkout existing branch $2"
  fi
}

function getTagWithPython {
  result=$(cat $1 | python -c 'import sys, json; print json.load(sys.stdin)["version"]' 2>&1);
  if [[ $? -ne 0 ]]; then
    s_warning "$result"
    s_fail "Could not load version from $1"
  else
    echo "$result"
  fi
}

function getTagWithNode {
  result=$(node -p "require(\"$1\").version" 2>&1)
  if [[ $? -ne 0 ]]; then
    s_warning "$result"
    s_fail "Could not load version from $1"
  else
    echo "$result"
  fi
}

function getTagFromJSON {
  if [ -f $1$2 ]; then
    if [ -n "`which node`" ]; then
      getTagWithNode $1$2
    else
      if [ -n "`which python`" ]; then
        getTagWithPython $1$2
      else
        echo "$3"
      fi
    fi
  else
    echo "$3"
  fi
}

function getTag {
  if [ -n "$1" ]; then
    case $1 in
      "bower") getTagFromJSON $2 "bower.json" $1 ;;
      "node") getTagFromJSON $2 "package.json" $1 ;;
      *) echo $1;;
    esac
  fi
}

function createCNAME {
  if [ -n "$WERCKER_GIT_PUSH_GH_PAGES_DOMAIN" ]; then
    echo $WERCKER_GIT_PUSH_GH_PAGES_DOMAIN > "$1/CNAME"
    s_info "Will create CNAME file: $1/CNAME"
  fi
}

function pushBranch {
  result="$(git push -q -f $1 $2:$3 2>&1)"
  if [[ $? -ne 0 ]]; then
    s_warning "$result"
    s_fail "failed pushing to $3 on $1"
  else
    s_success "pushed to $3 on $1"
  fi
}

function pushTag {
  git tag -a $2 -m "Tagged by $WERCKER_STARTED_BY" -f > /dev/null
  result="$(git push --tags $1 2>&1)"
  if [[ $? -ne 0 ]]; then
    s_warning "$result"
    s_fail "failed pushing to tag $1 with $2"
  else
    s_success "tagged $1 with $2"
  fi
}

function deleteTag {
  git tag -d $2 > /dev/null
  result="$(git push $1 --delete refs/tags/$2 2>&1)"
  if [[ $? -ne 0 ]]; then
    s_warning "$result"
    s_fail "failed delete $2 from $1"
  fi
}

for variable in $(getAllStepVars)
do
  if [ "${!variable}" == "false" ]; then
    s_info "\"$variable\" was set to false, we will unset it therefore"
    unset $variable
  fi
done

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

cd $baseDir
rm -rf .git

localBranch="master"

# remove existing files
targetDir="/tmp/git-push"
rm -rf $targetDir

destDir=$targetDir

if [ -n "$WERCKER_GIT_PUSH_DESTDIR" ]; then
  destDir=$targetDir/$WERCKER_GIT_PUSH_DESTDIR
fi

s_debug "before init"

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
mkdir -p $destDir

cd $destDir

echo $destDir $targetDir

s_debug "before clean"

if [ -n "$WERCKER_GIT_PUSH_CLEAN_REMOVED_FILES" ]; then
  info "We will clean in $destDir"
  ls -A | grep -v .git | xargs rm -rf
  mkdir -p $destDir
fi

cd $targetDir

ls -A

cp -rf $baseDir* $destDir

s_debug "before config"

git config user.email "pleasemailus@wercker.com"
git config user.name "werckerbot"

# generate cname file
createCNAME $targetDir
s_debug "base:" $baseDir: `ls -A $baseDir`
s_debug "target:" $targetDir: `ls -A $targetDir`
s_debug "dest:" $destDir: `ls -A $destDir`

tag=$WERCKER_GIT_PUSH_TAG
s_debug "before tagExtraction: $tag"

tag=$(getTag $tag $targetDir/)
s_debug "Tag after targetDir $tag"
tag=$(getTag $tag $destDir/)
s_debug "Tag after destDir $tag"
tag=$(getTag $tag $baseDir/)
s_debug "Tag after baseDir $tag"

if [ -n "$tag" ]; then
  s_info "The commit will be tagged with $tag"
fi

cd $targetDir

git add --all . > /dev/null

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


s_debug "before unset"

for variable in $(getAllStepVars)
do
  unset $variable
done
