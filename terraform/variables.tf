variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
  default     = "us-east-1"
}

variable "github_org" {
  type        = string
  description = "GitHub username or organization (case-sensitive)"
  default     = "TahyrHussayn"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name (case-sensitive)"
  default     = "efn"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.medium"
}
