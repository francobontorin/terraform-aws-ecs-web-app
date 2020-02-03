provider "aws" {
  region = var.region
}

module "label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  namespace  = var.namespace
  name       = var.name
  stage      = var.stage
  delimiter  = var.delimiter
  attributes = var.attributes
  tags       = var.tags
}

module "vpc" {
  source     = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=tags/0.8.1"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.name
  delimiter  = var.delimiter
  attributes = var.attributes
  cidr_block = var.vpc_cidr_block
  tags       = var.tags
}

module "subnets" {
  source               = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git?ref=tags/0.16.1"
  availability_zones   = var.availability_zones
  namespace            = var.namespace
  stage                = var.stage
  name                 = var.name
  attributes           = var.attributes
  delimiter            = var.delimiter
  vpc_id               = module.vpc.vpc_id
  igw_id               = module.vpc.igw_id
  cidr_block           = module.vpc.vpc_cidr_block
  nat_gateway_enabled  = true
  nat_instance_enabled = false
  tags                 = var.tags
}

module "alb" {
  source                                  = "git::https://github.com/cloudposse/terraform-aws-alb.git?ref=tags/0.7.0"
  namespace                               = var.namespace
  stage                                   = var.stage
  name                                    = var.name
  attributes                              = var.attributes
  delimiter                               = var.delimiter
  vpc_id                                  = module.vpc.vpc_id
  security_group_ids                      = [module.vpc.vpc_default_security_group_id]
  subnet_ids                              = module.subnets.public_subnet_ids
  internal                                = false
  http_enabled                            = true
  access_logs_enabled                     = false
  alb_access_logs_s3_bucket_force_destroy = true
  access_logs_region                      = var.region
  cross_zone_load_balancing_enabled       = true
  http2_enabled                           = true
  deletion_protection_enabled             = false
  tags                                    = var.tags
}

resource "aws_ecs_cluster" "default" {
  name = module.label.id
  tags = module.label.tags
}

resource "aws_sns_topic" "sns_topic" {
  name         = module.label.id
  display_name = "Test terraform-aws-ecs-web-app"
  tags         = module.label.tags
}

module "ecs_web_app" {
  source     = "../.."
  namespace  = var.namespace
  stage      = var.stage
  name       = var.name
  attributes = var.attributes
  delimiter  = var.delimiter
  tags       = var.tags

  region = var.region
  vpc_id = module.vpc.vpc_id

  // Container
  container_image              = var.container_image
  container_cpu                = var.container_cpu
  container_memory             = var.container_memory
  container_memory_reservation = var.container_memory_reservation
  port_mappings                = var.container_port_mappings
  log_driver                   = var.log_driver
  aws_logs_region              = var.region
  healthcheck                  = var.healthcheck
  mount_points                 = var.mount_points
  entrypoints                  = var.entrypoints
  volumes                      = var.volumes

  // Authentication
  authentication_type                           = var.authentication_type
  alb_ingress_listener_unauthenticated_priority = var.alb_ingress_listener_unauthenticated_priority
  alb_ingress_listener_authenticated_priority   = var.alb_ingress_listener_authenticated_priority
  alb_ingress_unauthenticated_hosts             = var.alb_ingress_unauthenticated_hosts
  alb_ingress_authenticated_hosts               = var.alb_ingress_authenticated_hosts
  alb_ingress_unauthenticated_paths             = var.alb_ingress_unauthenticated_paths
  alb_ingress_authenticated_paths               = var.alb_ingress_authenticated_paths
  authentication_cognito_user_pool_arn          = var.authentication_cognito_user_pool_arn
  authentication_cognito_user_pool_client_id    = var.authentication_cognito_user_pool_client_id
  authentication_cognito_user_pool_domain       = var.authentication_cognito_user_pool_domain
  authentication_oidc_client_id                 = var.authentication_oidc_client_id
  authentication_oidc_client_secret             = var.authentication_oidc_client_secret
  authentication_oidc_issuer                    = var.authentication_oidc_issuer
  authentication_oidc_authorization_endpoint    = var.authentication_oidc_authorization_endpoint
  authentication_oidc_token_endpoint            = var.authentication_oidc_token_endpoint
  authentication_oidc_user_info_endpoint        = var.authentication_oidc_user_info_endpoint

  // ECS
  ecs_private_subnet_ids            = module.subnets.private_subnet_ids
  ecs_cluster_arn                   = aws_ecs_cluster.default.arn
  ecs_cluster_name                  = aws_ecs_cluster.default.name
  ecs_security_group_ids            = var.ecs_security_group_ids
  health_check_grace_period_seconds = var.health_check_grace_period_seconds
  desired_count                     = var.desired_count
  launch_type                       = var.launch_type
  container_port                    = var.container_port

  // ALB
  alb_arn_suffix                                  = module.alb.alb_arn_suffix
  alb_security_group                              = module.alb.security_group_id
  alb_ingress_unauthenticated_listener_arns       = [module.alb.http_listener_arn]
  alb_ingress_unauthenticated_listener_arns_count = 1
  alb_ingress_healthcheck_path                    = var.alb_ingress_healthcheck_path

  // CodePipeline
  codepipeline_enabled                 = var.codepipeline_enabled
  badge_enabled                        = var.codepipeline_badge_enabled
  github_oauth_token                   = var.codepipeline_github_oauth_token
  github_webhooks_token                = var.codepipeline_github_webhooks_token
  github_webhook_events                = var.codepipeline_github_webhook_events
  repo_owner                           = var.codepipeline_repo_owner
  repo_name                            = var.codepipeline_repo_name
  branch                               = var.codepipeline_branch
  build_image                          = var.codepipeline_build_image
  build_timeout                        = var.codepipeline_build_timeout
  buildspec                            = var.codepipeline_buildspec
  poll_source_changes                  = var.poll_source_changes
  webhook_enabled                      = var.webhook_enabled
  webhook_target_action                = var.webhook_target_action
  webhook_authentication               = var.webhook_authentication
  webhook_filter_json_path             = var.webhook_filter_json_path
  webhook_filter_match_equals          = var.webhook_filter_match_equals
  codepipeline_s3_bucket_force_destroy = var.codepipeline_s3_bucket_force_destroy
  environment                          = var.environment
  secrets                              = var.secrets

  // Autoscaling
  autoscaling_enabled               = var.autoscaling_enabled
  autoscaling_dimension             = var.autoscaling_dimension
  autoscaling_min_capacity          = var.autoscaling_min_capacity
  autoscaling_max_capacity          = var.autoscaling_max_capacity
  autoscaling_scale_up_adjustment   = var.autoscaling_scale_up_adjustment
  autoscaling_scale_up_cooldown     = var.autoscaling_scale_up_cooldown
  autoscaling_scale_down_adjustment = var.autoscaling_scale_down_adjustment
  autoscaling_scale_down_cooldown   = var.autoscaling_scale_down_cooldown

  // ECS alarms
  ecs_alarms_enabled                                    = var.ecs_alarms_enabled
  ecs_alarms_cpu_utilization_high_threshold             = var.ecs_alarms_cpu_utilization_high_threshold
  ecs_alarms_cpu_utilization_high_evaluation_periods    = var.ecs_alarms_cpu_utilization_high_evaluation_periods
  ecs_alarms_cpu_utilization_high_period                = var.ecs_alarms_cpu_utilization_high_period
  ecs_alarms_cpu_utilization_low_threshold              = var.ecs_alarms_cpu_utilization_low_threshold
  ecs_alarms_cpu_utilization_low_evaluation_periods     = var.ecs_alarms_cpu_utilization_low_evaluation_periods
  ecs_alarms_cpu_utilization_low_period                 = var.ecs_alarms_cpu_utilization_low_period
  ecs_alarms_memory_utilization_high_threshold          = var.ecs_alarms_memory_utilization_high_threshold
  ecs_alarms_memory_utilization_high_evaluation_periods = var.ecs_alarms_memory_utilization_high_evaluation_periods
  ecs_alarms_memory_utilization_high_period             = var.ecs_alarms_memory_utilization_high_period
  ecs_alarms_memory_utilization_low_threshold           = var.ecs_alarms_memory_utilization_low_threshold
  ecs_alarms_memory_utilization_low_evaluation_periods  = var.ecs_alarms_memory_utilization_low_evaluation_periods
  ecs_alarms_memory_utilization_low_period              = var.ecs_alarms_memory_utilization_low_period
  ecs_alarms_cpu_utilization_high_alarm_actions         = [aws_sns_topic.sns_topic.arn]
  ecs_alarms_cpu_utilization_high_ok_actions            = [aws_sns_topic.sns_topic.arn]
  ecs_alarms_cpu_utilization_low_alarm_actions          = [aws_sns_topic.sns_topic.arn]
  ecs_alarms_cpu_utilization_low_ok_actions             = [aws_sns_topic.sns_topic.arn]
  ecs_alarms_memory_utilization_high_alarm_actions      = [aws_sns_topic.sns_topic.arn]
  ecs_alarms_memory_utilization_high_ok_actions         = [aws_sns_topic.sns_topic.arn]
  ecs_alarms_memory_utilization_low_alarm_actions       = [aws_sns_topic.sns_topic.arn]
  ecs_alarms_memory_utilization_low_ok_actions          = [aws_sns_topic.sns_topic.arn]

  // ALB and Target Group alarms
  alb_target_group_alarms_enabled                   = var.alb_target_group_alarms_enabled
  alb_target_group_alarms_evaluation_periods        = var.alb_target_group_alarms_evaluation_periods
  alb_target_group_alarms_period                    = var.alb_target_group_alarms_period
  alb_target_group_alarms_3xx_threshold             = var.alb_target_group_alarms_3xx_threshold
  alb_target_group_alarms_4xx_threshold             = var.alb_target_group_alarms_4xx_threshold
  alb_target_group_alarms_5xx_threshold             = var.alb_target_group_alarms_5xx_threshold
  alb_target_group_alarms_response_time_threshold   = var.alb_target_group_alarms_response_time_threshold
  alb_target_group_alarms_alarm_actions             = [aws_sns_topic.sns_topic.arn]
  alb_target_group_alarms_ok_actions                = [aws_sns_topic.sns_topic.arn]
  alb_target_group_alarms_insufficient_data_actions = [aws_sns_topic.sns_topic.arn]
}
