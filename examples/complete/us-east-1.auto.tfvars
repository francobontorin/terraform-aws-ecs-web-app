region = "us-east-1"

availability_zones = ["us-east-1a", "us-east-1b"]

namespace = "eg"

stage = "test"

name = "ecs-web-app"

vpc_cidr_block = "172.1.0.0/16"

container_image = "francobontorin/simple-docker-app"

container_cpu = 256

container_memory = 256

container_memory_reservation = 128

container_port = 80

container_port_mappings = [
  {
    containerPort = 80
    hostPort      = 80
    protocol      = "tcp"
  }
]

entrypoint = ["/usr/sbin/apache2", "-D", "FOREGROUND"]

mount_points = [
  {
    containerPath = "/var/www/my-vol"
    sourceVolume = "my-vol"
  }
]

volumes = [
  {
    name      = "my-vol"
    host_path = ""
    docker_volume_configuration = []
  }
]

desired_count = 4

launch_type = "FARGATE"

alb_target_group_alarms_enabled = true

alb_target_group_alarms_3xx_threshold = 25

alb_target_group_alarms_4xx_threshold = 25

alb_target_group_alarms_5xx_threshold = 25

alb_target_group_alarms_response_time_threshold = 0.5

alb_target_group_alarms_period = 300

alb_target_group_alarms_evaluation_periods = 1

alb_ingress_healthcheck_path = "/"

alb_ingress_listener_unauthenticated_priority = 1000

alb_ingress_unauthenticated_paths = ["/"]

aws_logs_region = "us-east-1"

log_driver = "awslogs"

ecs_alarms_enabled = true

ecs_alarms_cpu_utilization_high_threshold = 80

ecs_alarms_cpu_utilization_high_evaluation_periods = 1

ecs_alarms_cpu_utilization_high_period = 300

ecs_alarms_cpu_utilization_low_threshold = 20

ecs_alarms_cpu_utilization_low_evaluation_periods = 1

ecs_alarms_cpu_utilization_low_period = 300

ecs_alarms_memory_utilization_high_threshold = 80

ecs_alarms_memory_utilization_high_evaluation_periods = 1

ecs_alarms_memory_utilization_high_period = 300

ecs_alarms_memory_utilization_low_threshold = 20

ecs_alarms_memory_utilization_low_evaluation_periods = 1

ecs_alarms_memory_utilization_low_period = 300

autoscaling_enabled = true

autoscaling_dimension = "memory"

autoscaling_min_capacity = 1

autoscaling_max_capacity = 2

autoscaling_scale_up_adjustment = 1

autoscaling_scale_up_cooldown = 60

autoscaling_scale_down_adjustment = -1

autoscaling_scale_down_cooldown = 300

poll_source_changes = false

webhook_enabled = true

webhook_target_action = "Source"

webhook_filter_json_path = "$.ref"

webhook_filter_match_equals = "refs/heads/{Branch}"

authentication_type = ""

codepipeline_enabled = true

codepipeline_s3_bucket_force_destroy = true

codepipeline_github_oauth_token = "test"

codepipeline_github_webhooks_token = "test"

codepipeline_github_webhook_events = ["push"]

codepipeline_repo_owner = "francobontorin"

codepipeline_repo_name = "simple-docker-app"

codepipeline_branch = "master"

codepipeline_badge_enabled = false

codepipeline_build_image = "aws/codebuild/docker:17.09.0"

codepipeline_build_timeout = 20
