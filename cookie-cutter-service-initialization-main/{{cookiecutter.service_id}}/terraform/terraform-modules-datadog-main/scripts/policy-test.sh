#!/bin/bash
git_token=$1
# Execute script in terraform directory
set -e

policy_dir=policy_test

# Get rule files
git_repo="HappyMoneyInc/terraform-policies"
git_url="https://api.github.com/repos/$git_repo/zipball/main"
curl -sS -H "Authorization: token $git_token" -L "$git_url" > policies.zip
mkdir $policy_dir
unzip policies.zip -d $policy_dir/
extract_dir=$(find $policy_dir -maxdepth 1 -type d -name '*-terraform-policies-*' -print)

# Generate terraform plan file
terraform init > /dev/null
terraform plan -var 'id=test' --out $policy_dir/tfplan > /dev/null
terraform show -json $policy_dir/tfplan > $policy_dir/tfplan.json

# Validate
cfn-guard validate -d $policy_dir/tfplan.json -r $extract_dir/cfn-guard/rules

# Clean up temp files from working directory
rm -Rf $policy_dir
rm policies.zip