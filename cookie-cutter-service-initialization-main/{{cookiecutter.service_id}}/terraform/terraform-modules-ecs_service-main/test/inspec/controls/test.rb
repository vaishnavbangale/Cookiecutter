# Read from output file
file_name = "output.json"
json_file = inspec.profile.file(file_name)
attributes = JSON.parse(json_file)

app_1_outputs = attributes['ecs_service_alb_output']
app_2_outputs = attributes['ecs_service_nlb_output']
app_name_1 = attributes['app_name_1']
app_name_2 = attributes['app_name_2']
cluster_name = attributes['cluster_name']
id = attributes['id']
environment = attributes['environment']
region_abbrv = attributes['region_abbrv']
subnets = attributes['subnets']
vpc_id = attributes['vpc_id']
auto_scaling_thresholds_app_1 = attributes['auto_scaling_thresholds']['app_1']
auto_scaling_thresholds_app_2 = attributes['auto_scaling_thresholds']['app_2']

#---------------------------------------
control 'services' do
    impact 1.0
    title 'Test ECS service resources'

    describe aws_ecs_cluster(cluster_name: cluster_name) do
        it { should exist }
        its ('status') { should eq 'ACTIVE' }
        its ('active_services_count') { should be > 0 }
    end

    # Test ECS service with ALB
    describe aws_ecs_service(cluster_name: cluster_name, service_name: "ecs-service-#{app_name_1}-#{environment}-#{region_abbrv}") do
        it { should exist }
        its('desired_count') { should cmp 1  }
        # its('launch_type') { should cmp "FARGATE"  }
        its('network_configuration.awsvpc_configuration.assign_public_ip') { should cmp "DISABLED" }
        its('network_configuration.awsvpc_configuration.subnets') { should include(subnets[0]) }
        its('network_configuration.awsvpc_configuration.subnets') { should include(subnets[1]) }
        its('network_configuration.awsvpc_configuration.subnets') { should include(subnets[2]) }
        its('load_balancers_list') { should include(container_name: "ecs1-#{id}", container_port: 80, target_group_arn: app_1_outputs["ecs_target_group_arn"]["one"]) }
        its('load_balancers_list') { should include(container_name: "ecs1-#{id}", container_port: 88, target_group_arn: app_1_outputs["ecs_target_group_arn"]["two"]) }
        its('load_balancers_list') { should include(container_name: "ecs1-#{id}", container_port: 98, target_group_arn: app_1_outputs["ecs_target_group_arn"]["three"]) }
        its('network_configuration.awsvpc_configuration.security_groups') { should include(app_1_outputs["ecs_service_security_group_id"]) }
        its('tags_list') { should include(key: "account", value: "sandbox") }
        its('tags_list') { should include(key: "terraform", value: "true") }
        its('tags_list') { should include(key: "env", value: "sandbox") }
        its('tags_list') { should include(key: "terraform-repo", value: "terraform-modules-ecs_service") }
        its('tags_list') { should include(key: "hm-service", value: "test") }
        its('tags_list') { should include(key: "hm-project", value: "devops") }
        its('tags_list') { should include(key: "public-facing", value: "false") }
        its('tags_list') { should include(key: "region", value: "us-east-1") }
    end

    describe aws_ecs_task_definition(app_1_outputs["task_definition"]) do
        it { should exist }
        its('cpu') { should cmp 512 }
        its('memory') { should cmp 1024 }
        its('network_mode') { should cmp 'awsvpc' }
        its('tags_list') { should include(key: "account", value: "sandbox") }
        its('tags_list') { should include(key: "terraform", value: "true") }
        its('tags_list') { should include(key: "env", value: "sandbox") }
        its('tags_list') { should include(key: "terraform-repo", value: "terraform-modules-ecs_service") }        
        its('tags_list') { should include(key: "hm-service", value: "test") }
        its('tags_list') { should include(key: "hm-project", value: "devops") }
        its('tags_list') { should include(key: "public-facing", value: "false") }
        its('tags_list') { should include(key: "region", value: "us-east-1") }
    end

    describe aws_cloudwatch_alarm(alarm_name: app_1_outputs["fargate_auto_scaling"]["utilization_low_alarm"]["alarm_name"]) do
        it { should exist }
        its ('metrics') { should include(id: "e1",
                                   expression: "IF(cpu < #{auto_scaling_thresholds_app_1["ecs_alarms_cpu_low_threshold"]} AND memory < #{auto_scaling_thresholds_app_1["ecs_alarms_memory_low_threshold"]}, 1, 0)",
                                   label: "CPU and Memory Utilization low",
                                   return_data: true) 
                        }
    end
    describe aws_cloudwatch_alarm(alarm_name: app_1_outputs["fargate_auto_scaling"]["utilization_high_alarm"]["alarm_name"]) do
        it { should exist }
        its ('metrics') { should include(id: "e1",
                                   expression: "IF(cpu >= #{auto_scaling_thresholds_app_1["ecs_alarms_cpu_high_threshold"]}, 1, 0) OR IF(memory >= #{auto_scaling_thresholds_app_1["ecs_alarms_memory_high_threshold"]}, 1, 0)",
                                   label: "CPU or Memory Utilization high",
                                   return_data: true)
                        }
    end

    # Test ECS service with NLB
    describe aws_ecs_service(cluster_name: cluster_name, service_name: "ecs-service-#{app_name_2}-#{environment}-#{region_abbrv}") do
        it { should exist }
        its('desired_count') { should cmp 1  }
        # its('launch_type') { should cmp "FARGATE"  }
        its('network_configuration.awsvpc_configuration.assign_public_ip') { should cmp "DISABLED" }
        its('network_configuration.awsvpc_configuration.subnets') { should include(subnets[0]) }
        its('network_configuration.awsvpc_configuration.subnets') { should include(subnets[1]) }
        its('network_configuration.awsvpc_configuration.subnets') { should include(subnets[2]) }
        its('load_balancers_list') { should include(container_name: "ecs2-#{id}", container_port: 80, target_group_arn: app_2_outputs["ecs_target_group_arn"]["one"]) }
        its('network_configuration.awsvpc_configuration.security_groups') { should include(app_2_outputs["ecs_service_security_group_id"]) }
        its('tags_list') { should include(key: "account", value: "sandbox") }
        its('tags_list') { should include(key: "terraform", value: "true") }
        its('tags_list') { should include(key: "env", value: "sandbox") }
        its('tags_list') { should include(key: "terraform-repo", value: "terraform-modules-ecs_service") }
        its('tags_list') { should include(key: "hm-service", value: "test") }
        its('tags_list') { should include(key: "hm-project", value: "devops") }
        its('tags_list') { should include(key: "public-facing", value: "false") }
        its('tags_list') { should include(key: "region", value: "us-east-1") }
    end

    describe aws_ecs_task_definition(app_2_outputs["task_definition"]) do
        it { should exist }
        its('cpu') { should cmp 512 }
        its('memory') { should cmp 1024 }
        its('network_mode') { should cmp 'awsvpc' }
        its('tags_list') { should include(key: "account", value: "sandbox") }
        its('tags_list') { should include(key: "terraform", value: "true") }
        its('tags_list') { should include(key: "env", value: "sandbox") }
        its('tags_list') { should include(key: "terraform-repo", value: "terraform-modules-ecs_service") }        
        its('tags_list') { should include(key: "hm-service", value: "test") }
        its('tags_list') { should include(key: "hm-project", value: "devops") }
        its('tags_list') { should include(key: "public-facing", value: "false") }
        its('tags_list') { should include(key: "region", value: "us-east-1") }
    end

    describe aws_cloudwatch_alarm(alarm_name: app_2_outputs["fargate_auto_scaling"]["utilization_low_alarm"]["alarm_name"]) do
        it { should exist }
        its ('metrics') { should include(id: "e1", 
                                   expression: "IF(cpu < #{auto_scaling_thresholds_app_2["ecs_alarms_cpu_low_threshold"]} AND memory < #{auto_scaling_thresholds_app_2["ecs_alarms_memory_low_threshold"]}, 1, 0)",
                                   label: "CPU and Memory Utilization low",
                                   return_data: true) 
                        }
    end 

    describe aws_cloudwatch_alarm(alarm_name: app_2_outputs["fargate_auto_scaling"]["utilization_high_alarm"]["alarm_name"]) do
        it { should exist }
        its ('metrics') { should include(id: "e1",
                                   expression: "IF(cpu >= #{auto_scaling_thresholds_app_2["ecs_alarms_cpu_high_threshold"]}, 1, 0) OR IF(memory >= #{auto_scaling_thresholds_app_2["ecs_alarms_memory_high_threshold"]}, 1, 0)",
                                   label: "CPU or Memory Utilization high",
                                   return_data: true)
                        }
    end        
end
