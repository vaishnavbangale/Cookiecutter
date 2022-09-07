#!/bin/bash
set -e

# Install go
wget https://golang.org/dl/go1.14.15.linux-amd64.tar.gz
tar xf go1.14.15.linux-amd64.tar.gz -C /usr/local

# Install ruby
yum install -y git-core zlib zlib-devel gcc-c++ patch readline readline-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison curl sqlite-devel
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
export PATH="$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"
rbenv install 2.7.1
rbenv global 2.7.1
ruby -v

# Install inspec
wget https://packages.chef.io/files/stable/inspec/4.36.4/amazon/2/inspec-4.36.4-1.el7.x86_64.rpm
yum install -y inspec-4.36.4-1.el7.x86_64.rpm
gem install --install-dir /opt/inspec/embedded/lib/ruby/gems/2.7.0 aws-sdk-servicediscovery -v 1.36.0
gem install --install-dir /opt/inspec/embedded/lib/ruby/gems/2.7.0 aws-sdk-appmesh -v 1.36.0
gem install --install-dir /opt/inspec/embedded/lib/ruby/gems/2.7.0 aws-sdk-apigateway -v 1.62.0
gem install --install-dir /opt/inspec/embedded/lib/ruby/gems/2.7.0 aws-sdk-apigatewayv2 -v 1.32.0
gem install --install-dir /opt/inspec/embedded/lib/ruby/gems/2.7.0 aws-sdk-transfer -v 1.34.0
gem install --install-dir /opt/inspec/embedded/lib/ruby/gems/2.7.0 aws-sdk-codebuild -v 1.72.0
gem install --install-dir /opt/inspec/embedded/lib/ruby/gems/2.7.0 aws-sdk-codepipeline -v 1.44.0
gem install --install-dir /opt/inspec/embedded/lib/ruby/gems/2.7.0 aws-sdk-docdb -v 1.32.0
gem install --install-dir /opt/inspec/embedded/lib/ruby/gems/2.7.0 datadog_api_client -v 1.3.0
chmod -R 755 /opt/inspec/embedded/lib/ruby/gems/2.7.0/gems
find /opt/inspec/embedded/lib/ruby/gems/2.7.0/specifications/ -type f -exec chmod 644 {} \;

# Install tflint
curl -L -o tflint.zip https://github.com/terraform-linters/tflint/releases/download/v0.21.0/tflint_linux_amd64.zip
unzip tflint.zip -d /usr/local/bin/
chmod 755 /usr/local/bin/tflint

# Install cfn-guard
curl --proto '=https' --retry 2 --retry-delay 5 --tlsv1.2 -sSf https://raw.githubusercontent.com/aws-cloudformation/cloudformation-guard/main/install-guard.sh | sh
export PATH=~/.guard/bin/:$PATH