#!/bin/bash
policy_dir=$1

# Install prereq tools in codebuild project
set -euo pipefail
TERRAFORM_VERSION=$(cat "terraform/project.config" | jq -r '.tf_version')
export PATH="$HOME/.tfenv/bin:$HOME/.guard/bin:$PATH"

# Install terragrunt
wget -O terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/v0.35.16/terragrunt_linux_amd64
chmod u+x terragrunt; \
mv terragrunt /usr/local/bin/terragrunt

# Install cfn-guard
${CODEBUILD_SRC_DIR}/bin/install_cfn_guard_2_0_4.sh
cfn-guard --version

# Install tfenv and terraform
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
tfenv install ${TERRAFORM_VERSION}
tfenv use ${TERRAFORM_VERSION}

if [ ! -d "/root/.ssh" ] ; then
  mkdir /root/.ssh
fi       
chmod 700 /root/.ssh
ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts
$(aws ssm get-parameters --names "/devops/github/privkey" --with-decryption --region us-east-1 --query "Parameters[].Value" --output text > /root/.ssh/id_rsa)
chmod 600 /root/.ssh/id_rsa     

# Get cfn-guard rules
git_token=$(aws ssm get-parameters --names "/devops/github/oauth" --with-decryption --region us-east-1 --query "Parameters[].Value" --output text)
rules_git_url="https://api.github.com/repos/HappyMoneyInc/terraform-policies/zipball/main"
curl -sS -H "Authorization: token $git_token" -L "$rules_git_url" > policies.zip     
mkdir $policy_dir
unzip -q policies.zip -d $policy_dir/