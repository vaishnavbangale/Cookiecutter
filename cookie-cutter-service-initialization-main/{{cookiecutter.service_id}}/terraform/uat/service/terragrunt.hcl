include {
  path = find_in_parent_folders("nonprod.hcl")
}

inputs = {
  environment               = "uat"
  provider_assume_role_name = "ecs-app-infra-${get_env("ROLE_ACTION")}"
}