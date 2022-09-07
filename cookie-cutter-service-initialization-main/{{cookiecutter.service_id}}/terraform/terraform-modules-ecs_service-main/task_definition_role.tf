locals {
  default_exec_policy = {
    Version   = "2012-10-17",
    Statement = local.policy_combined
  }

  default_task_policy = {
    Version   = "2012-10-17",
    Statement = concat(local.policy_combined, local.ecs_exec_policy)
  }

  policy_combined     = concat(local.base_role_policy, jsondecode(local.env_access_policy), local.appmesh_policy)
  ecr_envoy_repo_arns = var.app_mesh_resource_type != "" ? [var.envoy_ecr_repo_arn] : []
  ecr_repo_arns       = var.ecr_repo_arn == "" ? [] : [var.ecr_repo_arn]
  ecr_arns            = concat(local.ecr_repo_arns, local.ecr_envoy_repo_arns)

  ecs_exec_policy = var.enable_execute_command ? [
    {
      Sid    = "AllowEcsExec"
      Effect = "Allow",
      Action = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      Resource = "*"
    }
  ] : []

  secrets_role_policy = length(var.secret_variables) > 0 ? [
    {
      Sid    = "EnvSecretsAccess",
      Effect = "Allow",
      Action = [
        "secretsmanager:GetSecretValue",
        "ssm:GetParameters"
      ],
      Resource = [for secret_item in var.secret_variables : secret_item["valueFrom"]]
    }
  ] : []
  base_role_policy = concat([
    {
      Sid    = "VisualEditor0",
      Effect = "Allow",
      Action = [
        "logs:CreateLogStream",
        "ecr:GetAuthorizationToken",
        "logs:PutLogEvents"
      ],
      Resource = "*"
    },
    {
      Sid      = "VisualEditor2",
      Effect   = "Allow",
      Action   = "ecr:*",
      Resource = local.ecr_arns
    },
    {
      Sid    = "SecretsManagerAccess",
      Effect = "Allow",
      Action = [
        "secretsmanager:GetSecretValue"
      ],
      Resource = [
        data.aws_secretsmanager_secret.dockerhub.arn
      ]
    },
    {
      Sid    = "ParameterStoreAccess",
      Effect = "Allow",
      Action = [
        "ssm:GetParameters"
      ],
      Resource = [
        "arn:aws:ssm:${var.region}:${var.account_id}:parameter/logging/datadog_token"
      ]
    }
  ], local.secrets_role_policy)

  env_access_policy = length(var.environmentfile_bucket_paths) == 0 ? jsonencode([]) : jsonencode([
    {
      Sid    = "EnvfileKMSAccess",
      Effect = "Allow",
      Action = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:CreateGrant",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      Resource = var.environmentfile_kms_arn
    },
    {
      Effect = "Allow",
      Action = [
        "s3:GetBucketLocation",
        "s3:ListBucket"
      ],
      Resource = [
        for path in var.environmentfile_bucket_paths : path.arn
      ]
    },
    {
      Sid    = "EnvfileS3Access",
      Effect = "Allow",
      Action = [
        "s3:Get*",
        "s3:List*"
      ],
      Resource = [
        for path in var.environmentfile_bucket_paths : "${path.arn}/${path.key_name}"
      ]
    }
  ])

  appmesh_policy = var.app_mesh_resource_type != "" ? [
    {
      Sid    = "AppmeshEnvoyAccessForAccessingVirtualNodeConfigs",
      Effect = "Allow",
      Action = [
        "appmesh:StreamAggregatedResources",
        "acm:DescribeCertificate",
        "acm:ExportCertificate",
        "acm-pca:DescribeCertificateAuthority",
        "acm-pca:GetCertificateAuthorityCertificate",
        "servicediscovery:DiscoverInstances"
      ],
      Resource = "*"
    }
  ] : []
}

# ----------------------------------------
# ECS Task Role
# ----------------------------------------
resource "aws_iam_role_policy" "task" {
  name = "iam-pol-ecs-task-${var.application_name}-${var.environment}"
  role = aws_iam_role.task.id

  policy = var.ecs_task_role_policy != null ? var.ecs_task_role_policy : jsonencode(local.default_task_policy)
}

resource "aws_iam_role" "task" {
  name                 = "iam-ecs-task-${var.application_name}-${var.environment}"
  permissions_boundary = var.permissions_boundary
  assume_role_policy   = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": [
            "ecs-tasks.amazonaws.com",
            "ec2.amazonaws.com"
          ]
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF

  tags = merge(
    var.tags,
    {
      Name               = "iam-ecs-task-${var.application_name}-${var.environment}"
      terraform-resource = "aws_iam_role.task"
    }
  )
}


resource "aws_iam_role_policy_attachment" "task_role_extras" {
  for_each = {
    for idx, v in var.ecs_task_role_extra_policy_arns : idx => v
  }

  role       = aws_iam_role.task.name
  policy_arn = each.value
}

# ----------------------------------------
# ECS Exec Role
# ----------------------------------------
resource "aws_iam_role_policy" "exec" {
  name = "iam-pol-ecs-exec-${var.application_name}-${var.environment}"
  role = aws_iam_role.exec.id

  policy = var.ecs_exec_role_policy != null ? var.ecs_exec_role_policy : jsonencode(local.default_exec_policy)
}

resource "aws_iam_role" "exec" {
  name                 = "iam-ecs-exec-${var.application_name}-${var.environment}"
  permissions_boundary = var.permissions_boundary
  assume_role_policy   = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": [
            "ecs-tasks.amazonaws.com",
            "ec2.amazonaws.com"
          ]
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF

  tags = merge(
    var.tags,
    {
      Name               = "iam-ecs-exec-${var.application_name}-${var.environment}"
      terraform-resource = "aws_iam_role.exec"
    }
  )
}

resource "aws_iam_role_policy_attachment" "exec_ec2" {
  count      = var.launch_type == "EC2" ? 1 : 0
  role       = aws_iam_role.exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "exec_role_extras" {
  for_each = {
    for idx, v in var.ecs_exec_role_extra_policy_arns : idx => v
  }

  role       = aws_iam_role.exec.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "exec" {
  count = var.launch_type == "EC2" ? 1 : 0
  name  = "ecs-inpro-exec-${var.application_name}-${var.environment}"
  role  = aws_iam_role.exec.name

  tags = merge(
    var.tags,
    {
      Name               = "ecs-inpro-exec-${var.application_name}-${var.environment}"
      terraform-resource = "aws_iam_instance_profile.exec"
    }
  )
}
