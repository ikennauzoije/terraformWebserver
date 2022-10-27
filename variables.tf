variable "aws_region" {
  description = "Region where resource is being Provisioned"
  type        = string // Could be number or boolean
  default     = "us-east-1"
}

variable "AWS_ACCESS_KEY_ID" {
  description = "AWS_ACCESS_KEY_ID"
  type        = string
  default     = "" // empty string but the secret access key of the AWS account will be added here
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "AWS_SECRET_ACCESS_KEY"
  type        = string
  default     = "" // empty string but the secret access key of the AWS account will be added here
}

variable "env" {
  default = "prod"
}

variable "instance_size" {
  description = "EC2 Instance Size to provision"
  default = {
    prod       = "t2.medium"
    staging    = "t2.small"
    dev        = "t2.micro"
    my_default = "t2.nano"
  }
}

variable "servers_settings" {
  type = map(any)
  default = {
    Application = {
      ami           = "ami-026b57f3c383c2eec"
      instance_size = "t2.small"
      root_disksize = 20
      encrypted     = true
    }
    Database = {
      ami           = "ami-026b57f3c383c2eec"
      instance_size = "t2.micro"
      root_disksize = 10
      encrypted     = false
    }
  }
}

variable "port_list" {
  description = "List of Ports to open for WebServer"
  default = {
    rest = ["80", "443"]
    prod = ["80", "443", "8080", "22"]
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(any)
  default = {
    Owner       = "Ikenna Uzoije"
    Environment = "Prod"
    Project     = "WebServer Bootstrap"
  }
}

variable "key_pair" {
  description = "SSH Key pair name to ingest into EC2"
  type        = string
  default     = "Terraform_main_key"
  sensitive   = true
}
