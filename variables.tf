variable "naming_prefix" {
  type        = string
  description = "Naming prefix for resources"
  default     = "vpc-assig"
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "Enable DNS hostnames in VPC"
  default     = true
}

variable "vpc_cidr_block" {
  type        = string
  description = "Base CIDR Block for VPC"
  default     = "10.1.0.0/16"
}

variable "vpc_subnet_count" {
  type        = number
  description = "Number of subnets to create in VPC"
  default     = 2
}

variable "map_public_ip_on_launch" {
  type        = bool
  description = "Map a public IP address for Subnet instances"
  default     = true
}

variable "public_subnets" {
  type = list(string)
  description = "Desired public_subnets as list of strings"
}

variable "private_subnets" {
  type = list(string)
  description = "Desired private_subnets as list of strings"
}

variable "availability_zone" {
  type = list(string)
  description = "Desired AZs as list of strings"
}

variable "company" {
  type        = string
  description = "Company name for resource tagging"
  default     = "Opsschool"
}

variable "common_tags" {
  type        = map(string)
  description = "Map of tags to be applied to all resources"
  default     = {}
}