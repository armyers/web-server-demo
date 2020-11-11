resource "aws_lb" "lb-ext" {
    name               = "lb-web-server-dev"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.lb-ext-sg.id]
    subnets            = module.vpc.public_subnets.*

    enable_deletion_protection = true

    access_logs {
        bucket = aws_s3_bucket.lb-log-bucket.id
        prefix = "lb-logs"
        enabled = true
    }

    tags = merge(var.common_tags,
            {
                Name = "lb-web-server-dev"
            }
        )
}

resource "aws_lb_listener" "lb-ext-listener" {
    load_balancer_arn = aws_lb.lb-ext.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.tg-web-server.arn
    }
}

resource "aws_lb_listener_rule" "lb-ext-listener-rule" {
  listener_arn = aws_lb_listener.lb-ext-listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg-web-server.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_security_group" "lb-ext-sg" {
    name = "lb-webserver-ext-sg"
    description = "SG for ext LB web-server"
    vpc_id = module.vpc.vpc_id
    tags = merge(var.common_tags,
        {
            role = "SG for ext LB web-server"
        }
    )
}

resource "aws_security_group_rule" "lb-ext-sg-ingress" {
    type              = "ingress"
    description       = "allow ingress to ext LB on port 80 from allowed CIDRs"
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    cidr_blocks       = var.vpc_default_ingress_cidr_blocks
    security_group_id = aws_security_group.lb-ext-sg.id
}

resource "aws_security_group_rule" "lb-ext-sg-egress" {
    type              = "egress"
    description       = "allow egress to ALL"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.lb-ext-sg.id
}

resource "aws_s3_bucket" "lb-log-bucket" {
    bucket = "lb-logs-web-server-dev"
    acl    = "private"
    policy = file("log-bucket-policy.json")

    tags = var.common_tags
}

resource "aws_s3_bucket_public_access_block" "lb-log-bucket-no-public" {
    bucket = aws_s3_bucket.lb-log-bucket.id

    # lock it down
    block_public_acls   = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}
resource "aws_lb_target_group" "tg-web-server" {
    name     = "tg-web-server-dev"
    port     = 40080
    protocol = "HTTP"
    vpc_id   = module.vpc.vpc_id
}

resource "aws_autoscaling_group" "asg-web-server" {
    name                      = "asg-web-server-dev"
    launch_configuration      = aws_launch_configuration.lc-web-server.name
    min_size                  = 3
    desired_capacity          = 3
    max_size                  = 12
    health_check_grace_period = 60
    health_check_type         = "ELB"
    force_delete              = true
    vpc_zone_identifier       = module.vpc.private_subnets.*
    target_group_arns         = [aws_lb_target_group.tg-web-server.arn]
    default_cooldown          = 150
    termination_policies      = ["OldestInstance", "Default"]


    lifecycle {
        create_before_destroy = true
    }
}

data "aws_ami" "web-server" {
        most_recent = true

        filter {
                name   = "name"
                values = ["web-server-golden-*"]
        }

        filter {
                name   = "virtualization-type"
                values = ["hvm"]
        }

        owners = ["540656036051"] # Canonical
}

resource "aws_launch_configuration" "lc-web-server" {
    name_prefix   = "lc-web-server-dev-"
    image_id      = data.aws_ami.web-server.id
    instance_type = var.instance_type
    key_name = "web-server-demo-dev"
    security_groups = [aws_security_group.web-server.id]

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_policy" "asg-scale-up" {
    name                   = "asg-scale-up-web-server"
    policy_type            = "SimpleScaling"
    adjustment_type        = "ChangeInCapacity"
    scaling_adjustment     = 1
    cooldown               = 300
    autoscaling_group_name = aws_autoscaling_group.asg-web-server.name
}

resource "aws_cloudwatch_metric_alarm" "avgcpu-high" {
    alarm_name = "avgcpu-high-agents"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "5"
    metric_name = "CPUUtilization"
    namespace = "System/Linux"
    period = "30"
    statistic = "Average"
    threshold = "80"
    alarm_description = "This metric monitors ec2 average cpu for high utilization on agent hosts"
    alarm_actions = [
        aws_autoscaling_policy.asg-scale-up.arn
    ]
    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.asg-web-server.name
    }
}

resource "aws_autoscaling_policy" "asg-scale-down" {
    name                   = "asg-scale-down-web-server"
    policy_type            = "SimpleScaling"
    adjustment_type        = "ChangeInCapacity"
    scaling_adjustment     = -1
    cooldown               = 300
    autoscaling_group_name = aws_autoscaling_group.asg-web-server.name
}

resource "aws_cloudwatch_metric_alarm" "avgcpu-low" {
    alarm_name = "avgcpu-high-agents"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "5"
    metric_name = "CPUUtilization"
    namespace = "System/Linux"
    period = "30"
    statistic = "Average"
    threshold = "30"
    alarm_description = "This metric monitors ec2 average cpu for low utilization on agent hosts"
    alarm_actions = [
        aws_autoscaling_policy.asg-scale-down.arn
    ]
    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.asg-web-server.name
    }
}

resource "aws_security_group" "web-server" {
    name = "web-server-sg"
    description = "SG for web-server"
    vpc_id = module.vpc.vpc_id
    tags = merge(var.common_tags,
            {
                role = "SG for web-server"
            }
        )
}

resource "aws_security_group_rule" "web-server-ingress-service-port-from-lb" {
    type              = "ingress"
    description       = "allow ingress to web-server from the ext LB on the service port"
    from_port         = 40080
    to_port           = 40080
    protocol          = "tcp"
    source_security_group_id = aws_security_group.lb-ext-sg.id
    security_group_id = aws_security_group.web-server.id
}

resource "aws_security_group_rule" "web-server-ingress-service-port-from-bastion" {
    type              = "ingress"
    description       = "allow ingress to web-server from the bastion on the service port"
    from_port         = 40080
    to_port           = 40080
    protocol          = "tcp"
    source_security_group_id = aws_security_group.bastion.id
    security_group_id = aws_security_group.web-server.id
}

resource "aws_security_group_rule" "web-server-ingress-ssh" {
    type              = "ingress"
    description       = "allow ingress to web-server on ssh port from ssh bastion"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    source_security_group_id = aws_security_group.bastion.id
    security_group_id = aws_security_group.web-server.id
}

resource "aws_security_group_rule" "web-server-egress" {
    type              = "egress"
    description       = "allow egress to ALL"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.web-server.id
}

