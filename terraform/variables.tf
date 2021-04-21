variable "environment" {
  type    = string
}

variable "project" {
  type    = string
}

variable "region" {
  default = "eu-west-1"
}

variable "cluster_name" {
  type = string
}

variable "worker_count" {
  type = number
  default = 1
}

variable "max_worker_count" {
  type = number
  default = 1
}

variable "worker_ami_owner" {
  type = string
}

variable "kubernetes_version" {
  type    = string
}

variable "output_directory" {
  type    = string
  default = "./output"
}

variable "kubeconfig_to_disk" {
  description = "This disables or enables the kube config file from being written to disk."
  type        = string
  default     = "true"
}

variable "kubeconfig_recreate" {
  description = "Make any change to this value to trigger the recreation of the kube config file to disk."
  type        = string
  default     = ""
}

variable "kubeconfig_filename" {
  description = "Name of the kube config file saved to disk."
  type        = string
  default     = "kube_config"
}

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap."
  type        = list(string)

  default = []
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(string)
}

# variable "map_roles" {
#   description = "Additional IAM roles to add to the aws-auth configmap."
#   type = list(object({
#     rolearn  = string
#     username = string
#     groups   = list(string)
#   }))

#   default = [
#     {
#       rolearn  = "arn:aws:iam::377592029167:user/munya"
#       username = "munya"
#       groups   = ["system:masters"]
#     },
#   ]
# }

variable "deploy_clusterapps" {
  type    = string
  default = "true"
}

variable "databases" {
  type    = map(
    object(
      {
        instance_class = string
        engine         = string
        engine_version = string
      }
    )
  )
  default = {}
}
