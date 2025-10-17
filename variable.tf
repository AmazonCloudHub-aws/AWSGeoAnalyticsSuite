## General ##
variable "subnet_id" {
  description = "Subnet ID for EMR cluster"
  type        = string
}

variable "master_sg_id" {
  description = "Security group ID for the master node of the EMR cluster"
  type        = string
}

variable "slave_sg_id" {
  description = "Security group ID for the slave nodes of the EMR cluster"
  type        = string
}

variable "redshift_master_password" {
  description = "Master password for the Redshift cluster"
  type        = string
}

variable "use_localstack" {
  description = "If true, configure provider to use LocalStack endpoints"
  type        = bool
  default     = false
}

