variable "name_prefix" {
  type        = string
  description = "Name prefix for resources"
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "Enable DNS hostnames in VPC"
}

variable "vpc_cidr_block" {
  type        = string
  description = "Base CIDR Block for VPC"
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

variable "common_tags" {
  type        = map(string)
  description = "Map of tags to be applied to all resources"
  default     = {}
}

# variable "vpc_tags" {
#   type        = map(string)
#   description = "Map of tags to be applied to public subnets"
#   default     = {}
# }

variable "public_subnet_tags" {
  type        = map(string)
  description = "Map of tags to be applied to public subnets"
  default     = {}
}

variable "private_subnet_tags" {
  type        = map(string)
  description = "Map of tags to be applied to private subnets"
  default     = {}
}