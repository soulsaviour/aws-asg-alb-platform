# --- General ---------------------------------------------------------------

variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Project name, used as a prefix for resource names."
  type        = string
  default     = "webapp"
}

variable "environment" {
  description = "Environment name, e.g. dev, staging or prod."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Extra tags applied to every resource."
  type        = map(string)
  default     = {}
}

# --- Network ---------------------------------------------------------------

variable "vpc_id" {
  description = "ID of the VPC to deploy into."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the load balancer, in at least two availability zones."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "An Application Load Balancer needs subnets in at least two availability zones."
  }
}

variable "private_subnet_ids" {
  description = "Subnets for the application instances."
  type        = list(string)
}

variable "allowed_ingress_cidrs" {
  description = "IPv4 CIDR blocks allowed to reach the load balancer."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# --- Application -----------------------------------------------------------

variable "app_port" {
  description = "Port the application listens on."
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Path the load balancer uses for target health checks."
  type        = string
  default     = "/health"
}

variable "deregistration_delay" {
  description = "Seconds the load balancer waits for in-flight requests before deregistering a target."
  type        = number
  default     = 30
}

variable "app_version" {
  description = "Version string reported by the application."
  type        = string
  default     = "0.1.0"
}

# --- Compute ---------------------------------------------------------------

variable "architecture" {
  description = "CPU architecture for the fleet: x86_64, or arm64 for Graviton."
  type        = string
  default     = "x86_64"

  validation {
    condition     = contains(["x86_64", "arm64"], var.architecture)
    error_message = "architecture must be x86_64 or arm64."
  }
}

variable "instance_type" {
  description = "Instance type. Defaults to t3.small (x86_64) or t4g.small (arm64)."
  type        = string
  default     = null
}

variable "ami_id" {
  description = "Pin a specific AMI. Defaults to the latest Amazon Linux 2023 image."
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 20
}

variable "detailed_monitoring" {
  description = "Enable 1-minute EC2 metrics, which makes scaling react faster."
  type        = bool
  default     = true
}

variable "asg_min_size" {
  description = "Minimum number of instances."
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of instances."
  type        = number
  default     = 6
}

variable "asg_desired_capacity" {
  description = "Initial number of instances. Scaling policies manage it afterwards."
  type        = number
  default     = 2
}

# --- Scaling ---------------------------------------------------------------

variable "cpu_target_value" {
  description = "Average CPU utilisation (%) the Auto Scaling group aims for."
  type        = number
  default     = 60
}

variable "requests_per_target" {
  description = "ALB requests per minute per instance to aim for. 0 disables request-based scaling."
  type        = number
  default     = 0
}

# --- Observability ---------------------------------------------------------

variable "log_retention_days" {
  description = "Retention for the application and bootstrap log groups."
  type        = number
  default     = 30
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic to notify on alarm state changes. Leave null to create alarms without actions."
  type        = string
  default     = null
}

variable "target_5xx_threshold" {
  description = "Number of target 5xx responses in 5 minutes that raises the alarm."
  type        = number
  default     = 10
}

variable "memory_alarm_threshold" {
  description = "Fleet-average memory use (%) that raises the alarm."
  type        = number
  default     = 85
}

# --- TLS -------------------------------------------------------------------

variable "certificate_arn" {
  description = "ACM certificate for the HTTPS listener. When null, the ALB serves plain HTTP only."
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "TLS policy for the HTTPS listener."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}
