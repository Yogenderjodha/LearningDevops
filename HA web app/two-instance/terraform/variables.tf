variable "project" {
  description = "Project Name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR range of VPC"
  type        = string
}

variable "public_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "private_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
}