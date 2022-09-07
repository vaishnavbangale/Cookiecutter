#!/bin/bash
set -e

# Install missing aws packages for inspec
gem install --install-dir /opt/inspec/embedded/lib/ruby/gems/2.7.0 aws-sdk-servicediscovery -v 1.43.0
gem install --install-dir /opt/inspec/embedded/lib/ruby/gems/2.7.0 aws-sdk-appmesh -v 1.42.0
gem install --install-dir /opt/inspec/embedded/lib/ruby/gems/2.7.0 aws-sdk-apigateway -v 1.72.0
gem install --install-dir /opt/inspec/embedded/lib/ruby/gems/2.7.0 aws-sdk-apigatewayv2 -v 1.39.0
gem install --install-dir /opt/inspec/embedded/lib/ruby/gems/2.7.0 aws-sdk-transfer -v 1.44.0
gem install --install-dir /opt/inspec/embedded/lib/ruby/gems/2.7.0 aws-sdk-codebuild -v 1.85.0
gem install --install-dir /opt/inspec/embedded/lib/ruby/gems/2.7.0 aws-sdk-codepipeline -v 1.50.0
gem install --install-dir /opt/inspec/embedded/lib/ruby/gems/2.7.0 aws-sdk-docdb -v 1.38.0
gem install --install-dir /opt/inspec/embedded/lib/ruby/gems/2.7.0 aws-sdk-eventbridge -v 1.33.0
gem install --install-dir /opt/inspec/embedded/lib/ruby/gems/2.7.0 datadog_api_client -v 1.5.0
chmod -R 755 /opt/inspec/embedded/lib/ruby/gems/2.7.0/gems
find /opt/inspec/embedded/lib/ruby/gems/2.7.0/specifications/ -type f -exec chmod 644 {} \;

# Install tflint
curl -L -o tflint.zip https://github.com/terraform-linters/tflint/releases/download/v0.21.0/tflint_linux_amd64.zip
unzip tflint.zip -d /usr/local/bin/
chmod 755 /usr/local/bin/tflint
