#!/bin/bash
set -e

basehead=$1
response_json=$2
git_token=$3

git_repo="HappyMoneyInc/${REPOSITORY_NAME}"

# Compare commits to get diff
compare_url="https://api.github.com/repos/$git_repo/compare/$basehead"
curl -H "Authorization: token $git_token" $compare_url > $response_json