variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-north-1"
}

variable "cluster_name" {
  description = "Name tag prefix for Kubernetes cluster infrastructure"
  type        = string
  default     = "k8s-hardway"
}

variable "vpc_cidr" {
  description = "CIDR block for the cluster VPC"
  type        = string
  default     = "10.240.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the public cluster subnet"
  type        = string
  default     = "10.240.0.0/24"
}

variable "controller_instance_type" {
  description = "EC2 instance type for the Kubernetes Control Plane"
  type        = string
  default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "EC2 instance type for Kubernetes Worker Nodes"
  type        = string
  default     = "t3.medium"
}

variable "worker_count" {
  description = "Number of worker nodes to provision"
  type        = number
  default     = 2
}

variable "public_key_path" {
  description = "Local path to the SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
