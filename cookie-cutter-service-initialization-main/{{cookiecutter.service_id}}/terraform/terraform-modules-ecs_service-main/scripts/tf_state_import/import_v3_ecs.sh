#!/bin/bash
# Helper script written for importing resources into a blank tf state file for v3 ecs module.
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
#   - Edit variable values in the VARIABLES section of script. network_access_cidrs must be in same order as defined in tfvars
#   - Ensure backend is pointing to a path that does not exist yet.
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
module_path="module.ecs_green"
app_name="app_name"
service_name="service_name"
environment=dev
service_port=8080
region_abbrv=ue1
network_access_cidrs=( 
    "10.211.0.0/16"
    "10.231.0.0/16"
    "10.30.241.128/25"
    "10.30.240.0/24"
    "172.25.0.0/22"
    "172.25.4.0/22"
    "172.25.8.0/22" 
    "172.25.20.0/22"
    "172.25.24.0/22"
    "172.25.28.0/22"
    "172.25.32.0/22"
    "172.25.36.0/22"
    "172.25.40.0/22"
    
)
ecs_application_name="${app_name}-${service_name}-green-${environment}"
ecs_cluster_name="ecs-cluster-infraFargate-${environment}-${region_abbrv}"
ecs_service_name="ecs-service-${ecs_application_name}-${region_abbrv}"
ecs_sg_name="ecs-sg-${ecs_application_name}-${region_abbrv}"

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

vpc_name="vpc-vpc-infra-${environment}-ue1"
vpc_cidr=$(aws ec2 describe-vpcs --profile "${account}_terraform" --output json | jq -r ".Vpcs[] | select(.Tags[] | .Value | contains(\"${vpc_name}\")) | .CidrBlock")
vpc_cidr_ft=$(echo ${vpc_cidr} | cut -d"." -f1-2)

ecs_service_sg=$(aws ec2 describe-security-groups --profile "${account}_terraform" --filters "Name=group-name,Values=${ecs_sg_name}" --output json | jq -r ".SecurityGroups[0] | .GroupId")
ecs_service_egress="${ecs_service_sg}_egress_all_0_0_0.0.0.0/0"
ecs_service_udp_service_discovery_ports="${ecs_service_sg}_ingress_udp_${service_port}_${service_port}_${vpc_cidr_ft}.1.0/24_${vpc_cidr_ft}.2.0/24_${vpc_cidr_ft}.3.0/24"
ecs_service_tcp_service_discovery_ports="${ecs_service_sg}_ingress_tcp_${service_port}_${service_port}_${vpc_cidr_ft}.1.0/24_${vpc_cidr_ft}.2.0/24_${vpc_cidr_ft}.3.0/24"
ecs_service_internal_network_access="${ecs_service_sg}_ingress_tcp_${service_port}_${service_port}"
for cidr in ${network_access_cidrs[@]}
do
    ecs_service_internal_network_access="${ecs_service_internal_network_access}_${cidr}"
done

ecs_service_json=$(aws ecs describe-services --profile "${account}_terraform" --cluster "${ecs_cluster_name}" --services "${ecs_service_name}" --output json | jq -r ".services[0]")
task_definition=$(echo $ecs_service_json | jq -r .taskDefinition)

#--------------------------------
terragrunt init

terragrunt import "${module_path}.aws_iam_role.exec" "iam-ecs-exec-${ecs_application_name}"
terragrunt import "${module_path}.aws_iam_role.task" "iam-ecs-task-${ecs_application_name}"
terragrunt import "${module_path}.aws_iam_role_policy.exec" "iam-ecs-exec-${ecs_application_name}:iam-pol-ecs-exec-${ecs_application_name}"
terragrunt import "${module_path}.aws_iam_role_policy.task" "iam-ecs-task-${ecs_application_name}:iam-pol-ecs-task-${ecs_application_name}"
terragrunt import "${module_path}.aws_security_group.ecs_service" $ecs_service_sg
terragrunt import "${module_path}.aws_security_group_rule.udp_service_discovery_ports[0]" $ecs_service_udp_service_discovery_ports
terragrunt import "${module_path}.aws_security_group_rule.ecs_service_egress" $ecs_service_egress
terragrunt import "${module_path}.aws_security_group_rule.internal_network_access[\"$service_port\"]" $ecs_service_internal_network_access
terragrunt import "${module_path}.aws_security_group_rule.tcp_service_discovery_ports[0]" $ecs_service_tcp_service_discovery_ports

terragrunt import "${module_path}.aws_ecs_task_definition.application_task" "${task_definition}"
terragrunt import "${module_path}.aws_ecs_service.application_service" "${ecs_cluster_name}/${ecs_service_name}"

terragrunt import "${module_path}.aws_appautoscaling_policy.app_down[0]" "ecs/service/${ecs_cluster_name}/${ecs_service_name}/ecs:service:DesiredCount/app-scale-down"
terragrunt import "${module_path}.aws_appautoscaling_policy.app_up[0]" "ecs/service/${ecs_cluster_name}/${ecs_service_name}/ecs:service:DesiredCount/app-scale-up"
terragrunt import "${module_path}.aws_appautoscaling_target.app_scale_target[0]" "ecs/service/${ecs_cluster_name}/${ecs_service_name}/ecs:service:DesiredCount"
terragrunt import "${module_path}.aws_cloudwatch_metric_alarm.cpu_utilization_high[0]" "${ecs_application_name}-CPU-Utilization-High-70"
terragrunt import "${module_path}.aws_cloudwatch_metric_alarm.cpu_utilization_low[0]" "${ecs_application_name}-CPU-Utilization-Low-20"

echo "Pulling state file to update values post import"
terragrunt state pull > state.json
serial_num=$(cat state.json | jq -r '.serial')
((serial_num++))
jq -r ".serial = ${serial_num} | .resources[] |= if .module == \"$module_path\" and .type == \"aws_ecs_service\" and .name == \"application_service\" then (.instances[0].attributes.task_definition = \"${task_definition}\" | .instances[0].attributes.wait_for_steady_state = \"false\" | .instances[0].attributes.force_new_deployment = \"true\") else . end" state.json > temp_state.json
terragrunt state push temp_state.json
rm temp_state.json
rm state.json
