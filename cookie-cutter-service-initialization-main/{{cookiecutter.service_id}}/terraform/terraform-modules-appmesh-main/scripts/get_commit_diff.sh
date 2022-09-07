#!/bin/bash
set -e

basehead=$1
response_json=$2

git_token=$(aws ssm get-parameters --names "/devops/github/oauth" --with-decryption --region us-east-1 --query "Parameters[].Value" --output text)
git_repo="HappyMoneyInc/${REPOSITORY_NAME}"

# Compare commits to get diff
compare_url="https://api.github.com/repos/$git_repo/compare/$basehead"
curl -H "Authorization: token $git_token" $compare_url > $response_json