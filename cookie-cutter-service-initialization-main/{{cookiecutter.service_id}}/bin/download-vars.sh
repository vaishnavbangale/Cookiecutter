#!/bin/bash
export SERVICE_NAME={{ cookiecutter.service_id }}

function download_vars {
  echo "copying s3 bucket for service ${SERVICE_NAME} and environment ${1}"
  aws s3 cp s3://hm-sharedservices-environmentfiles/${1}/${SERVICE_NAME}/general_variables.env ./env/${1}/general_variables.env
}

case $1 in
  dev)
    download_vars $1
    ;;
  qa)
    download_vars $1
    ;;
  qa1)
    download_vars $1
    ;;
  uat)
    download_vars $1
    ;;
  *)
    echo "Invalid environment"
    ;;
esac
