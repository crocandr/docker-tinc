#!/bin/bash

[ -z $URL ] && { echo "NO GIT REPO URL DEFINED"; exit 1; }
[ -z $BRANCH ] || BRANCH="master"

DATA_DIR="/data"
DATA_GIT="/data-git"

# check URL type
URLTYPE=$( echo $URL | cut -f1 -d':' )

# clear existing data
rm -rf $DATA_GIT
[ -d $DATA_GIT ] || mkdir -p $DATA_GIT

# Clone GIT repo
function gitupdate {
  [ "$1" ] && REPO="$1"

  echo "Git preconfig..."
  cd $DATA_GIT
  git clone $REPO --branch $BRANCH .
  #git init
  #git init $DATA_DIR
  #git remote add origin $REPO || exit 1
  #git remote -v
  git config user.name tinc-system
  git config user.email tinc-system@nowhere.com
  #echo "Git download..."
  #git pull -q --no-commit origin $BRANCH
  #git merge
  cp -rfp $DATA_DIR/* $DATA_GIT/
  echo "Git upload..."
  git add -A || exit 1
  git commit -m "update" || exit 1
  git push origin master:$BRANCH || exit 1
  echo "Git redownload..."
  git pull -q --no-commit origin $BRANCH
  git merge
  rsync -a --exclude=".git" $DATA_GIT/ $DATA_DIR/
}

# Push

case $URLTYPE in
  "ssh" | "SSH" | "[sS][hH][hH]" )
    echo "Git mode: SSH"
    [ -f $HOME/.ssh/id_rsa ] || { echo "NO SSH KEY FOUND"; exit 1; }
    # run git command chain
    gitupdate $URL
    ;;
  "http" | "https" | "HTTP" | "HTTPS" | "[hH][tT][tT][pP]" | "[hH][tT][tT][pP][sS]" )
    echo "Git mode: HTTP(s)"
    [ -z $GIT_USER ] && { echo "Git User: $GIT_USER"; }
    [ -z $GIT_PASSWORD ] && { echo "Git Password: $GIT_PASSWORD"; }
    # URL contains username and the password?
    if [ $( echo $URL | egrep "//.*:.*@.*" | wc -l ) -eq 0 ]
    then
      echo "The repo URL does not contain the authentication data"
      echo "Add auth data into the URL..."
      REPO_URL="$( echo $URL | sed s%//%//$GIT_USER:$GIT_PASSWORD@%g )"
    else
      REPO_URL="$URL"
    fi
    # run git command chain
    gitupdate $REPO_URL
    ;;
  * )
    echo "Sorry, unknown URL type"
    echo "Error in GIT download"
    exit 1
    ;;
esac

