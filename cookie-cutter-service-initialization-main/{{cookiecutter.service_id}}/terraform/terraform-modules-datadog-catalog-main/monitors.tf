# Maps of monitors
locals {
  #--------------------------------------------------------------------------------
  # ALB
  catalog_alb_files         = [for filename in fileset("${path.module}/monitors/alb/", "*.json") : trimsuffix(filename, ".json")]
  catalog_alb_monitors_list = var.alb_monitor.enabled == true ? local.catalog_alb_files : []
  catalog_alb_list = flatten([
    for item in local.catalog_alb_monitors_list : [
      for attr_key, attr_val in var.alb_monitor.attributes : {
        key = "${attr_key}/alb/${item}"
        value = jsondecode(templatefile("${path.module}/monitors/alb/${item}.json", {
          lb_name              = attr_val.lb_name
          lb_dns_name          = attr_val.lb_dns_name
          notification_targets = lookup(attr_val, "notification_targets", var.notification_targets)
        }))
      }
    ]
  ])
  catalog_alb = { for item in local.catalog_alb_list : item.key => item.value }

  custom_alb_list = var.alb_monitor.enabled == true && var.alb_monitor.custom_monitors != null ? flatten([
    for key, val in var.alb_monitor.custom_monitors : [
      for attr_key, attr_val in var.alb_monitor.attributes :
      {
        id         = "${attr_key}/${key}"
        template   = val
        attributes = attr_val
      }
    ]
  ]) : []
  custom_alb = {
    for item in local.custom_alb_list : item.id => jsondecode(templatefile(item.template, merge({
      notification_targets = lookup(item.attributes, "notification_targets", var.notification_targets)
    }, item.attributes)))
  }

  #--------------------------------------------------------------------------------
  # Apigateway
  catalog_apigateway_files         = [for filename in fileset("${path.module}/monitors/apigateway/", "*.json") : trimsuffix(filename, ".json")]
  catalog_apigateway_monitors_list = var.apigateway_monitor.enabled == true ? local.catalog_apigateway_files : []
  catalog_apigateway_list = flatten([
    for item in local.catalog_apigateway_monitors_list : [
      for attr_key, attr_val in var.apigateway_monitor.attributes : {
        key = "${attr_key}/apigateway/${item}"
        value = jsondecode(templatefile("${path.module}/monitors/apigateway/${item}.json", {
          name                 = lookup(attr_val, "name", attr_val.api_id)
          api_id               = attr_val.api_id
          notification_targets = lookup(attr_val, "notification_targets", var.notification_targets)
        }))
      }
    ]
  ])
  catalog_apigateway = { for item in local.catalog_apigateway_list : item.key => item.value }

  custom_apigateway_list = var.apigateway_monitor.enabled == true && var.apigateway_monitor.custom_monitors != null ? flatten([
    for key, val in var.apigateway_monitor.custom_monitors : [
      for attr_key, attr_val in var.apigateway_monitor.attributes :
      {
        id         = "${attr_key}/${key}"
        template   = val
        attributes = attr_val
      }
    ]
  ]) : []
  custom_apigateway = {
    for item in local.custom_apigateway_list : item.id => jsondecode(templatefile(item.template, merge({
      notification_targets = lookup(item.attributes, "notification_targets", var.notification_targets)
    }, item.attributes)))
  }

  #--------------------------------------------------------------------------------
  # ApigatewayV2
  catalog_apigatewayv2_files         = [for filename in fileset("${path.module}/monitors/apigatewayv2/", "*.json") : trimsuffix(filename, ".json")]
  catalog_apigatewayv2_monitors_list = var.apigatewayv2_monitor.enabled == true ? local.catalog_apigatewayv2_files : []
  catalog_apigatewayv2_list = flatten([
    for item in local.catalog_apigatewayv2_monitors_list : [
      for attr_key, attr_val in var.apigatewayv2_monitor.attributes : {
        key = "${attr_key}/apigatewayv2/${item}"
        value = jsondecode(templatefile("${path.module}/monitors/apigatewayv2/${item}.json", {
          name                 = lookup(attr_val, "name", attr_val.api_id)
          api_id               = attr_val.api_id
          notification_targets = lookup(attr_val, "notification_targets", var.notification_targets)
        }))
      }
    ]
  ])
  catalog_apigatewayv2 = { for item in local.catalog_apigatewayv2_list : item.key => item.value }

  custom_apigatewayv2_list = var.apigatewayv2_monitor.enabled == true && var.apigatewayv2_monitor.custom_monitors != null ? flatten([
    for key, val in var.apigatewayv2_monitor.custom_monitors : [
      for attr_key, attr_val in var.apigatewayv2_monitor.attributes :
      {
        id         = "${attr_key}/${key}"
        template   = val
        attributes = attr_val
      }
    ]
  ]) : []
  custom_apigatewayv2 = {
    for item in local.custom_apigatewayv2_list : item.id => jsondecode(templatefile(item.template, merge({
      notification_targets = lookup(item.attributes, "notification_targets", var.notification_targets)
    }, item.attributes)))
  }

  #--------------------------------------------------------------------------------
  # Cloudfront
  catalog_cloudfront_files         = [for filename in fileset("${path.module}/monitors/cloudfront/", "*.json") : trimsuffix(filename, ".json")]
  catalog_cloudfront_monitors_list = var.cloudfront_monitor.enabled == true ? local.catalog_cloudfront_files : []
  catalog_cloudfront_list = flatten([
    for item in local.catalog_cloudfront_monitors_list : [
      for attr_key, attr_val in var.cloudfront_monitor.attributes : {
        key = "${attr_key}/cloudfront/${item}"
        value = jsondecode(templatefile("${path.module}/monitors/cloudfront/${item}.json", {
          name                 = lookup(attr_val, "name", attr_val.distribution_id)
          distribution_id      = attr_val.distribution_id
          notification_targets = lookup(attr_val, "notification_targets", var.notification_targets)
        }))
      }
    ]
  ])
  catalog_cloudfront = { for item in local.catalog_cloudfront_list : item.key => item.value }

  custom_cloudfront_list = var.cloudfront_monitor.enabled == true && var.cloudfront_monitor.custom_monitors != null ? flatten([
    for key, val in var.cloudfront_monitor.custom_monitors : [
      for attr_key, attr_val in var.cloudfront_monitor.attributes :
      {
        id         = "${attr_key}/${key}"
        template   = val
        attributes = attr_val
      }
    ]
  ]) : []
  custom_cloudfront = {
    for item in local.custom_cloudfront_list : item.id => jsondecode(templatefile(item.template, merge({
      notification_targets = lookup(item.attributes, "notification_targets", var.notification_targets)
    }, item.attributes)))
  }

  #--------------------------------------------------------------------------------
  # docdb
  catalog_docdb_files         = [for filename in fileset("${path.module}/monitors/docdb/", "*.json") : trimsuffix(filename, ".json")]
  catalog_docdb_monitors_list = var.docdb_monitor.enabled == true ? local.catalog_docdb_files : []
  catalog_docdb_list = flatten([
    for item in local.catalog_docdb_monitors_list : [
      for attr_key, attr_val in var.docdb_monitor.attributes : {
        key = "${attr_key}/docdb/${item}"
        value = jsondecode(templatefile("${path.module}/monitors/docdb/${item}.json", {
          db_cluster_identifier = attr_val.db_cluster_identifier
          notification_targets  = lookup(attr_val, "notification_targets", var.notification_targets)
        }))
      }
    ]
  ])
  catalog_docdb = { for item in local.catalog_docdb_list : item.key => item.value }

  custom_docdb_list = var.docdb_monitor.enabled == true && var.docdb_monitor.custom_monitors != null ? flatten([
    for key, val in var.docdb_monitor.custom_monitors : [
      for attr_key, attr_val in var.docdb_monitor.attributes :
      {
        id         = "${attr_key}/${key}"
        template   = val
        attributes = attr_val
      }
    ]
  ]) : []
  custom_docdb = {
    for item in local.custom_docdb_list : item.id => jsondecode(templatefile(item.template, merge({
      notification_targets = lookup(item.attributes, "notification_targets", var.notification_targets)
    }, item.attributes)))
  }

  #--------------------------------------------------------------------------------
  # dynamodb
  catalog_dynamodb_files         = [for filename in fileset("${path.module}/monitors/dynamodb/", "*.json") : trimsuffix(filename, ".json")]
  catalog_dynamodb_monitors_list = var.dynamodb_monitor.enabled == true ? local.catalog_dynamodb_files : []
  catalog_dynamodb_list = flatten([
    for item in local.catalog_dynamodb_monitors_list : [
      for attr_key, attr_val in var.dynamodb_monitor.attributes : {
        key = "${attr_key}/dynamodb/${item}"
        value = jsondecode(templatefile("${path.module}/monitors/dynamodb/${item}.json", {
          table_name           = attr_val.table_name
          notification_targets = lookup(attr_val, "notification_targets", var.notification_targets)
        }))
      }
    ]
  ])
  catalog_dynamodb = { for item in local.catalog_dynamodb_list : item.key => item.value }

  custom_dynamodb_list = var.dynamodb_monitor.enabled == true && var.dynamodb_monitor.custom_monitors != null ? flatten([
    for key, val in var.dynamodb_monitor.custom_monitors : [
      for attr_key, attr_val in var.dynamodb_monitor.attributes :
      {
        id         = "${attr_key}/${key}"
        template   = val
        attributes = attr_val
      }
    ]
  ]) : []
  custom_dynamodb = {
    for item in local.custom_dynamodb_list : item.id => jsondecode(templatefile(item.template, merge({
      notification_targets = lookup(item.attributes, "notification_targets", var.notification_targets)
    }, item.attributes)))
  }

  #--------------------------------------------------------------------------------
  # ECS 
  catalog_ecs_files         = [for filename in fileset("${path.module}/monitors/ecs/", "*.json") : trimsuffix(filename, ".json")]
  catalog_ecs_monitors_list = var.ecs_monitor.enabled == true ? local.catalog_ecs_files : []
  catalog_ecs_list = flatten([
    for item in local.catalog_ecs_monitors_list : [
      for attr_key, attr_val in var.ecs_monitor.attributes : {
        key = "${attr_key}/ecs/${item}"
        value = jsondecode(templatefile("${path.module}/monitors/ecs/${item}.json", {
          service_name         = attr_val.service_name
          notification_targets = lookup(attr_val, "notification_targets", var.notification_targets)
        }))
      }
    ]
  ])
  catalog_ecs = { for item in local.catalog_ecs_list : item.key => item.value }

  custom_ecs_list = var.ecs_monitor.enabled == true && var.ecs_monitor.custom_monitors != null ? flatten([
    for key, val in var.ecs_monitor.custom_monitors : [
      for attr_key, attr_val in var.ecs_monitor.attributes :
      {
        id         = "${attr_key}/${key}"
        template   = val
        attributes = attr_val
      }
    ]
  ]) : []
  custom_ecs = {
    for item in local.custom_ecs_list : item.id => jsondecode(templatefile(item.template, merge({
      notification_targets = lookup(item.attributes, "notification_targets", var.notification_targets)
    }, item.attributes)))
  }

  #--------------------------------------------------------------------------------
  # lambda 
  catalog_lambda_files         = [for filename in fileset("${path.module}/monitors/lambda/", "*.json") : trimsuffix(filename, ".json")]
  catalog_lambda_monitors_list = var.lambda_monitor.enabled == true ? local.catalog_lambda_files : []
  catalog_lambda_list = flatten([
    for item in local.catalog_lambda_monitors_list : [
      for attr_key, attr_val in var.lambda_monitor.attributes : {
        key = "${attr_key}/lambda/${item}"
        value = jsondecode(templatefile("${path.module}/monitors/lambda/${item}.json", {
          function_name        = attr_val.function_name
          notification_targets = lookup(attr_val, "notification_targets", var.notification_targets)
        }))
      }
    ]
  ])
  catalog_lambda = { for item in local.catalog_lambda_list : item.key => item.value }

  custom_lambda_list = var.lambda_monitor.enabled == true && var.lambda_monitor.custom_monitors != null ? flatten([
    for key, val in var.lambda_monitor.custom_monitors : [
      for attr_key, attr_val in var.lambda_monitor.attributes :
      {
        id         = "${attr_key}/${key}"
        template   = val
        attributes = attr_val
      }
    ]
  ]) : []
  custom_lambda = {
    for item in local.custom_lambda_list : item.id => jsondecode(templatefile(item.template, merge({
      notification_targets = lookup(item.attributes, "notification_targets", var.notification_targets)
    }, item.attributes)))
  }
  #--------------------------------------------------------------------------------
  # NLB
  catalog_nlb_files         = [for filename in fileset("${path.module}/monitors/nlb/", "*.json") : trimsuffix(filename, ".json")]
  catalog_nlb_monitors_list = var.nlb_monitor.enabled == true ? local.catalog_nlb_files : []
  catalog_nlb_list = flatten([
    for item in local.catalog_nlb_monitors_list : [
      for attr_key, attr_val in var.nlb_monitor.attributes : {
        key = "${attr_key}/nlb/${item}"
        value = jsondecode(templatefile("${path.module}/monitors/nlb/${item}.json", {
          lb_name              = attr_val.lb_name
          lb_dns_name          = attr_val.lb_dns_name
          notification_targets = lookup(attr_val, "notification_targets", var.notification_targets)
        }))
      }
    ]
  ])
  catalog_nlb = { for item in local.catalog_nlb_list : item.key => item.value }

  custom_nlb_list = var.nlb_monitor.enabled == true && var.nlb_monitor.custom_monitors != null ? flatten([
    for key, val in var.nlb_monitor.custom_monitors : [
      for attr_key, attr_val in var.nlb_monitor.attributes :
      {
        id         = "${attr_key}/${key}"
        template   = val
        attributes = attr_val
      }
    ]
  ]) : []
  custom_nlb = {
    for item in local.custom_nlb_list : item.id => jsondecode(templatefile(item.template, merge({
      notification_targets = lookup(item.attributes, "notification_targets", var.notification_targets)
    }, item.attributes)))
  }

  #--------------------------------------------------------------------------------
  # rds
  catalog_rds_files         = [for filename in fileset("${path.module}/monitors/rds/", "*.json") : trimsuffix(filename, ".json")]
  catalog_rds_monitors_list = var.rds_monitor.enabled == true ? local.catalog_rds_files : []
  catalog_rds_list = flatten([
    for item in local.catalog_rds_monitors_list : [
      for attr_key, attr_val in var.rds_monitor.attributes : {
        key = "${attr_key}/rds/${item}"
        value = jsondecode(templatefile("${path.module}/monitors/rds/${item}.json", {
          db_cluster_identifier = attr_val.db_cluster_identifier
          notification_targets  = lookup(attr_val, "notification_targets", var.notification_targets)
        }))
      }
    ]
  ])
  catalog_rds = { for item in local.catalog_rds_list : item.key => item.value }

  custom_rds_list = var.rds_monitor.enabled == true && var.rds_monitor.custom_monitors != null ? flatten([
    for key, val in var.rds_monitor.custom_monitors : [
      for attr_key, attr_val in var.rds_monitor.attributes :
      {
        id         = "${attr_key}/${key}"
        template   = val
        attributes = attr_val
      }
    ]
  ]) : []
  custom_rds = {
    for item in local.custom_rds_list : item.id => jsondecode(templatefile(item.template, merge({
      notification_targets = lookup(item.attributes, "notification_targets", var.notification_targets)
    }, item.attributes)))
  }

  #--------------------------------------------------------------------------------
  monitors_map = merge(
    local.catalog_alb,
    local.custom_alb,

    local.catalog_apigateway,
    local.custom_apigateway,

    local.catalog_apigatewayv2,
    local.custom_apigatewayv2,

    local.catalog_docdb,
    local.custom_docdb,

    local.catalog_dynamodb,
    local.custom_dynamodb,

    local.catalog_ecs,
    local.custom_ecs,

    local.catalog_lambda,
    local.custom_lambda,

    local.catalog_nlb,
    local.custom_nlb,

    local.catalog_rds,
    local.custom_rds
  )
  monitors = { for key, val in local.monitors_map : key => val if !contains(var.exclude_monitors, key) }
}