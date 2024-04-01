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
