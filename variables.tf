
################### Lambda Provisioning Specific Variables ###################
variable "user_vpc_id" {
  default = ""
}

variable "user_subnet_id" {
  default = ""
}

variable "runtime" {
  default = "python3.6"
}

variable "region" {
  default = "us-east-2"
}

variable "aws_profile" {
  default = "nasuni"
}

variable "admin_secret" {
  default = "nasuni-labs-os-admin"
}

variable "internal_secret" {
  default = ""
}

variable "stage_name" {
  default     = "dev"
  description = "api stage name"
}

variable "use_private_ip" {
  default = "N"
}

variable "vpc_endpoint_id" {
  default = "vpce-*"
} 