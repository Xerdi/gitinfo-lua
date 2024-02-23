#!/bin/bash

set -e

set_author() {
  git config user.name $1
  git config user.email $2
  git config committer.name $1
  git config committer.email $2
  git config author.name $1
  git config author.email $2
}

alice() {
  set_author 'Alice' 'alice@example.com'
}
bob() {
  set_author 'Bob' 'bob@example.com'
}
charlie() {
  set_author 'Charlie' 'charlie@example.com'
}

alice

echo "# My project" > README.md
git add README.md
git commit -m "Add readme" --date="2017-08-04 10:32"

bob

echo "
Another project by Alice and Bob." >> README.md
git add README.md
git commit -m "Add intro (README.md)" --date="2017-08-05 06:12"

alice

GIT_COMMITTER_DATE="2017-08-05 07:11" git tag 0.0.1

bob

curl https://raw.githubusercontent.com/github/gitignore/main/TeX.gitignore > .gitignore
git add .gitignore
git commit -m "Add gitignore

Get the TeX.gitignore from the gitignore repository and
use it for this project.

From github" --date="2017-08-06 12:03"

charlie

export GIT_COMMITTER_DATE="2017-08-06 08:41"
git tag -a 0.1.0 -m "Version 0.1.0"
