provider "aws" {
  region = var.region
}

module "vpc" {
  source     = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=tags/0.8.1"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.name
  cidr_block = "172.16.0.0/16"
}

data "aws_availability_zones" "available" {
}

locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "subnets" {
  source               = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git?ref=tags/0.16.1"
  availability_zones   = local.availability_zones
  namespace            = var.namespace
  stage                = var.stage
  name                 = var.name
  vpc_id               = module.vpc.vpc_id
  igw_id               = module.vpc.igw_id
  cidr_block           = module.vpc.vpc_cidr_block
  nat_gateway_enabled  = true
  nat_instance_enabled = false
  tags                 = var.tags
}

module "alb" {
  source                    = "git::https://github.com/cloudposse/terraform-aws-alb.git?ref=tags/0.7.0"
  name                      = var.name
  namespace                 = var.namespace
  stage                     = var.stage
  attributes                = compact(concat(var.attributes, ["alb"]))
  vpc_id                    = module.vpc.vpc_id
  ip_address_type           = "ipv4"
  subnet_ids                = module.subnets.public_subnet_ids
  security_group_ids        = [module.vpc.vpc_default_security_group_id]
  access_logs_region        = var.region
  https_enabled             = true
  http_ingress_cidr_blocks  = ["0.0.0.0/0"]
  https_ingress_cidr_blocks = ["0.0.0.0/0"]
  certificate_arn           = var.certificate_arn
  health_check_interval     = 60
}

module "label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  name       = var.name
  namespace  = var.namespace
  stage      = var.stage
  tags       = var.tags
  attributes = var.attributes
  delimiter  = var.delimiter
}

# ECS Cluster (needed even if using FARGATE launch type)
resource "aws_ecs_cluster" "default" {
  name = module.label.id
}

resource "aws_cloudwatch_log_group" "app" {
  name = module.label.id
  tags = module.label.tags
}

module "web_app" {
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
  entrypoint                   = var.entrypoint
  volumes                      = var.volumes

 // ECS
  ecs_private_subnet_ids            = module.subnets.private_subnet_ids
  ecs_cluster_arn                   = aws_ecs_cluster.default.arn
  ecs_cluster_name                  = aws_ecs_cluster.default.name
  ecs_security_group_ids            = var.ecs_security_group_ids
  health_check_grace_period_seconds = var.health_check_grace_period_seconds
  desired_count                     = var.desired_count
  launch_type                       = var.launch_type
  container_port                    = var.container_port

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

  // ALB
  alb_security_group                              = module.alb.security_group_id
  alb_target_group_alarms_enabled                 = true
  alb_target_group_alarms_3xx_threshold           = 25
  alb_target_group_alarms_4xx_threshold           = 25
  alb_target_group_alarms_5xx_threshold           = 25
  alb_target_group_alarms_response_time_threshold = 0.5
  alb_target_group_alarms_period                  = 300
  alb_target_group_alarms_evaluation_periods      = 1

  alb_arn_suffix = module.alb.alb_arn_suffix

  alb_ingress_healthcheck_path = "/"

  # Without authentication, both HTTP and HTTPS endpoints are supported
  alb_ingress_unauthenticated_listener_arns       = module.alb.listener_arns
  alb_ingress_unauthenticated_listener_arns_count = 2

  # All paths are unauthenticated
  alb_ingress_unauthenticated_paths             = ["/*"]
  alb_ingress_listener_unauthenticated_priority = 100
}