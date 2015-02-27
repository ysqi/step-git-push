#!/bin/bash

# RETURNS REPO_PATH SET in GIT_PUSH or current WERCKER
function getRepoPath {
  if [ -n "$WERCKER_GIT_PUSH_REPO" ]
  then
    echo "$WERCKER_GIT_PUSH_REPO"
  else
    echo "$WERCKER_GIT_OWNER/$WERCKER_GIT_REPOSITORY"
  fi
}

#RETURNS FULL REMOTE PATH OF THE REPO
function getRepoURL {
  repo=$(getRepoPath)
  if [ -n "$WERCKER_GIT_PUSH_GH_TOKEN" ]; then
    echo "https://$WERCKER_GIT_PUSH_GH_TOKEN@github.com/$repo.git"
  elif [ -n "$WERCKER_GIT_PUSH_HOST" ]; then
    git_user=$(getGitSSHUser)
    echo "$git_user@$WERCKER_GIT_PUSH_HOST:$repo.git"
  else
    exit -1
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
  result=$(git clone $1 $2 -q)
  if [[ $? -ne 0 ]]; then
    fail "failed to clone repo"
  fi
}