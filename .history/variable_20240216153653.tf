


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

Tfvars

subnet_id                = "subnet-12345abcd"
master_sg_id             = "sg-12345abcd"
slave_sg_id              = "sg-abcde12345"
redshift_master_password = "YourSecurePassword1"


Provider.tf