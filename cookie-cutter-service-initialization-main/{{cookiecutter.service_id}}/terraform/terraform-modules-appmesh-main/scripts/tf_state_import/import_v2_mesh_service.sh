#!/bin/bash
# Helper script written for importing resources into a tf state file for v2 app mesh service module.
# Prereq: 
#   - Create source profile for prod/nonprod accounts. Call it prod_terraform and nonprod_terraform.
#   e.g
#     [profile prod_terraform]
#     region = us-east-1
#     role_arn = arn:aws:iam:: 174688722531:role/terraform
#     source_profile = sharedservices
#     
#     [profile nonprod_terraform]
#     region = us-east-1
#     role_arn = arn:aws:iam::790856068772:role/terraform
#     source_profile = sharedservices
#
#   - Edit variable values in the VARIABLES section of script if needed.
#   - Ensure backend is pointing to the correct path where you want to import resources into.
#   - Configuration must be able to plan properly before running imports.
#   - Terragrunt must be installed or modify this script to run terraform instead of terragrunt.
#   - Any variables that need to be passed in should exist as terraform.tfvars in same folder.
#   - Working directory should be the directory with tf files
#   - Current session as admin role in sharedservices AWS account
# Note:
#   - Run a terraform plan after import. 
# Usage:
#
#---
set -e
#--------------------------------
# VARIABLES
module_path="module.mesh_service"
app_name="app_name"
service_name="service_name"
environment=dev
vn_key="green"

mesh_name="${environment}-mesh"
cloudmap_srv_name="${app_name}-${service_name}"

#--------------------------------
echo "Getting values for variables"
case ${environment} in
   dev|qa|uat|stage)
     account=nonprod
     account_id=790856068772
   ;;
   prod)
     account=prod
     account_id=174688722531
   ;;
esac

cloudmap_namespace_name="${environment}.mesh.local"
cloudmap_namespace_id=$(aws servicediscovery list-namespaces --profile "${account}_terraform" --output json | jq -r ".Namespaces[] | select(.Name | test(\"^$cloudmap_namespace_name$\")) | .Id")
cloudmap_service_id=$(aws servicediscovery list-services --filters Name=NAMESPACE_ID,Values=${cloudmap_namespace_id} --profile "${account}_terraform" --output json | jq -r ".Services[] | select(.Name | test(\"^$cloudmap_srv_name$\")) | .Id")

#--------------------------------
terragrunt init

terragrunt import "${module_path}.aws_appmesh_virtual_router.router" "${mesh_name}/${cloudmap_srv_name}-router"
terragrunt import "${module_path}.aws_service_discovery_service.cloudmap_service" $cloudmap_service_id
terragrunt import "${module_path}.aws_appmesh_virtual_service.service" "${mesh_name}/${cloudmap_srv_name}.${environment}.mesh.local"
terragrunt import "${module_path}.module.virtual_nodes[\"${vn_key}\"].aws_appmesh_virtual_node.node" "${mesh_name}/${cloudmap_srv_name}-${vn_key}"
terragrunt import "${module_path}.aws_appmesh_route.service-route[\"/\"]" "${mesh_name}/${app_name}-${service_name}-router/${cloudmap_srv_name}-route_-"

# Import virtual gateway route
terragrunt import "${module_path}.aws_appmesh_gateway_route.gw_route[0]" "${mesh_name}/mesh-gateway/${cloudmap_srv_name}-gw-route"