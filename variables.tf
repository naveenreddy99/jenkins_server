variable "SERVER_ENV" {
}
variable "region" {
  default ="us-west-2"
  }

variable "key_name" {
  default ="mm5-test"
  }

variable "iam_role" {
  default ="install_d5_software"
  }

variable "subnet_id" {}

variable "security_group" {}
variable "instance_type" {}
variable "instance_count" {}
variable "ami_id" {
  default = "ami-0acf31388f3373d01"
}

variable "encrypted" {
  type        = bool
  description = "If true, the file system will be encrypted"
  default     = true
}

variable "kms_key_id" {
  type        = string
  description = "If set, use a specific KMS key"
  default     = null
}

variable "performance_mode" {
  type        = string
  description = "The file system performance mode. Can be either `generalPurpose` or `maxIO`"
  default     = "generalPurpose"
}

variable "provisioned_throughput_in_mibps" {
  default     = 0
  description = "The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with `throughput_mode` set to provisioned"
}

variable "throughput_mode" {
  type        = string
  description = "Throughput mode for the file system. Defaults to bursting. Valid values: `bursting`, `provisioned`. When using `provisioned`, also set `provisioned_throughput_in_mibps`"
  default     = "bursting"
}

variable "mount_target_ip_address" {
  type        = string
  description = "The address (within the address range of the specified subnet) at which the file system may be mounted via the mount target"
  default     = null
}

variable "efs_mount_tags" {
  type        = map(string)
  description = "EFS mount tags"
  default     = null
}

variable "subnets" {
  type        = list(string)
  description = "Subnets"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}
