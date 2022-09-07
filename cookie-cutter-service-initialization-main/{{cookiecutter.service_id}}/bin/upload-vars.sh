#!/bin/bash
export SERVICE_NAME={{ cookiecutter.service_id }}

function upload_vars {
  aws s3 cp ./env/${1}/general_variables.env s3://hm-sharedservices-environmentfiles/${1}/${SERVICE_NAME}/general_variables.env
}

case $1 in
  dev)
    upload_vars $1
    ;;
  qa)
    upload_vars $1
    ;;
  qa1)
    upload_vars $1
    ;;
  uat)
    upload_vars $1
    ;;
  *)
    echo "Invalid environment"
    ;;
esac
