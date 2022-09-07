#!/bin/bash
# Helper script for importing resources targets for ecs module v3.
# Optional script to run after import_v3_ecs.sh.
# Only assumes single target associated to service. Has to be modified for multiple targets
# The name inside keepers will have to be modified if using a short_application_name in ecs.
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
target_key_name=service
host_header="${service_name}.${environment}.aws-ue1.happymoney.com"
ecs_application_name="${app_name}-${service_name}-green-${environment}"
ecs_cluster_name="ecs-cluster-infraFargate-${environment}-${region_abbrv}"
ecs_service_name="ecs-service-${ecs_application_name}-${region_abbrv}"
lb_name="ec2-lb-private-alb-${environment}-ue1"
random_uuid="GetFromExistingState"
lb_protocol="HTTP" # TLS for nlb

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

ecs_service_sg=$(aws ec2 describe-security-groups --profile "${account}_terraform" --filters "Name=group-name,Values=${ecs_sg_name}" --output json | jq -r ".SecurityGroups[0] | .GroupId")
ecs_application_target_arn=$(aws ecs describe-services --profile "${account}_terraform" --cluster "${ecs_cluster_name}" --services "${ecs_service_name}" --output json | jq -r ".services[0].loadBalancers[0].targetGroupArn")

lb_arn=$(aws elbv2 describe-load-balancers --profile "${account}_terraform" --names $lb_name --output json | jq -r ".LoadBalancers[0].LoadBalancerArn")

vpc_name="vpc-vpc-infra-${environment}-ue1"
vpc_id=$(aws ec2 describe-vpcs --profile "${account}_terraform" --output json | jq -r ".Vpcs[] | select(.Tags[] | .Value | contains(\"${vpc_name}\")) | .VpcId")


#--------------------------------
terragrunt import "${module_path}.random_uuid.tg[\"${target_key_name}\"]" $random_uuid
terragrunt import "${module_path}.aws_lb_target_group.ecs_application_targets[\"${target_key_name}\"]" $ecs_application_target_arn

if [[ "${lb_name[@]}" =~ "^ec2-lb-.*$" ]]
then
  # ALB specific
  ecs_service_listener=$(aws elbv2 describe-listeners --load-balancer-arn $lb_arn --profile "${account}_terraform" --output json | jq -r ".Listeners[] | select(.Protocol == \"HTTPS\") | .ListenerArn")
  alb_rule_arn=$(aws elbv2 describe-rules --listener-arn $ecs_service_listener --profile "${account}_terraform" --output json | jq -r ".Rules[] | select(.Conditions[] | select(.Field == \"host-header\") | .Values[] | contains(\"${host_header}\") ) | .RuleArn")
  terragrunt import "${module_path}.aws_lb_listener_rule.static[\"${target_key_name}\"]" $alb_rule_arn
  alb_sg_id=$(aws elbv2 describe-load-balancers --profile "${account}_terraform" --names $lb_name --output json | jq -r ".LoadBalancers[0].SecurityGroups[0]")
  ecs_service_service_port="${ecs_service_sg}_ingress_tcp_${service_port}_${service_port}_$alb_sg_id"
  terragrunt import "${module_path}.aws_security_group_rule.service_port[\"${target_key_name}\"]" $ecs_service_service_port
elif [[ "${lb_name[@]}" =~ "^ec2-nlb-.*$" ]]
then
  # NLB specific
  ecs_service_listener=$(aws elbv2 describe-listeners --load-balancer-arn $lb_arn --profile "${account}_terraform" --output json | jq -r ".Listeners[] | select(.DefaultActions[] | .TargetGroupArn | contains(\"${ecs_application_target_arn}\")) | .ListenerArn")
  terragrunt import "${module_path}.aws_lb_listener.container_service[\"${target_key_name}\"]" $ecs_service_listener

  elb_filter="ELB $(echo ${lb_arn} | cut -d"/" -f2-4)"
  elb_nics_json=$(aws ec2 describe-network-interfaces --filters Name=description,Values=$elb_filter --profile "${account}_terraform" --output json | jq -r ".NetworkInterfaces")
  nic1_cidr="$(echo $elb_nics_json | jq -r '.[] | select(.AvailabilityZone == "us-east-1a") | .PrivateIpAddress')/32"
  nic2_cidr="$(echo $elb_nics_json | jq -r '.[] | select(.AvailabilityZone == "us-east-1b") | .PrivateIpAddress')/32"
  nic3_cidr="$(echo $elb_nics_json | jq -r '.[] | select(.AvailabilityZone == "us-east-1c") | .PrivateIpAddress')/32"
  nlb_sg_rules="${nic1_cidr}_${nic2_cidr}_${nic3_cidr}"
  ecs_service_service_port="${ecs_service_sg}_ingress_tcp_${service_port}_${service_port}_$nlb_sg_rules"
  terragrunt import "${module_path}.aws_security_group_rule.service_port[\"${target_key_name}\"]" $ecs_service_service_port
fi
 
#--------------------------------
echo "Pulling state file to update values post import"
terragrunt state pull > state.json
serial_num=$(cat state.json | jq -r '.serial')
((serial_num++))

keepers=$(cat <<EOF
{
  "name": "${"${ecs_application_name}"/"-${environment}"/""}",
  "port": "${service_port}",
  "protocol": "${lb_protocol}",
  "target_type": "ip",
  "vpc_id": "${vpc_id}"
}
EOF
)
jq -r ".serial = ${serial_num} | .resources[] |= if .module == \"$module_path\" and .type == \"random_uuid\" and .name == \"tg\" then (.instances[0].attributes.keepers = ${keepers}) else . end" state.json > temp_state.json
terragrunt state push temp_state.json
rm temp_state.json
rm state.json