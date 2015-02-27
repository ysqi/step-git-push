
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
  if [ -n "$WERCKER_GIT_PUSH_GH_TOKEN" ]
  then
    echo "https://$WERCKER_GIT_PUSH_GH_TOKEN@github.com/$repo.git"
  elif [ -n "$WERCKER_GIT_PUSH_HOST" ]
  then
    git_user=$(getGitSSHUser)
    echo "$git_user@$WERCKER_GIT_PUSH_HOST:$repo.git"
  else
    exit -1
    # "missing option \"gh_token\" or \"host\", aborting"
  fi
}

function getGitSSHUser {
  if [ -n "$WERCKER_GIT_PUSH_USER" ]
  then
    echo "$WERCKER_GIT_PUSH_USER"
  else
    echo "git"
  fi
}

function getBranch {
if [ -n "$WERCKER_GIT_PUSH_GH_PAGES" ]
then
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