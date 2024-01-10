resource "aws_apprunner_auto_scaling_configuration_version" "ngnix-apprunner-autoscaling" {
  auto_scaling_configuration_name = "${var.auto_scaling_configuration_name}-${var.environment}-${var.random_id_prefix}"
  max_concurrency = 100
  max_size        = 5
  min_size        = 1

  tags = {
    Name = var.auto_scaling_configuration_name
  }
}

resource "random_id" "random_id_prefix" {
  byte_length = 2
}

module "iam" {
  source = "../iam"

  region           = var.region
  environment      = var.environment
  random_id_prefix = random_id.random_id_prefix.hex
}

resource "aws_apprunner_service" "ngnix-apprunner-service-ecr" {
  count = (var.isECR && var.image_repository_type == "ECR") ? 1 : 0

   depends_on = [module.iam]

  service_name = "nginx-apprunner-${var.random_id_prefix}"

  source_configuration {
    image_repository {
      image_configuration {
        port = var.port
        runtime_environment_variables = {
        }
      }
      image_identifier      = var.image_identifier
      image_repository_type = var.image_repository_type
    }
    authentication_configuration{
      access_role_arn = var.app_runner_role
    }
    auto_deployments_enabled = var.auto_deployments_enabled
  }


  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.ngnix-apprunner-autoscaling.arn

  health_check_configuration {
          healthy_threshold   = 1
          interval            = 10
          path                = "/"
          protocol            = "TCP"
          timeout             = 5
          unhealthy_threshold = 5
        }

        instance_configuration {
          cpu               = 1024
          instance_role_arn = var.app_runner_role
          memory            = 2048
        }

  tags = {
    Name = var.service_name
  }
}

resource "aws_apprunner_service" "ngnix-apprunner-service-ecr-public" {
  count = (var.isECR && var.image_repository_type == "ECR_PUBLIC") ? 1 : 0

  service_name = "${var.service_name}-${var.environment}-${var.random_id_prefix}"

  source_configuration {
    image_repository {
      image_configuration {
        port = var.port
      }
      image_identifier      = var.image_identifier
      image_repository_type = var.image_repository_type
    }
    auto_deployments_enabled = false
  }

  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.ngnix-apprunner-autoscaling.arn

  health_check_configuration {
          healthy_threshold   = 1
          interval            = 10
          path                = "/"
          protocol            = "TCP"
          timeout             = 5
          unhealthy_threshold = 5
        }

  tags = {
    Name = var.service_name
  }
}
