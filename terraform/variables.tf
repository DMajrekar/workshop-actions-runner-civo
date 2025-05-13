variable "region" {
  description = "Civo Region to provision resources in"
  type        = string
  default     = "PHX1"
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "github-actions-runners"
}

variable "node_size" {
  description = "Size of the nodes in the cluster"
  type        = string
  default     = "g4s.kube.medium"
}

variable "node_count" {
  description = "Initial number of nodes in the cluster"
  type        = number
  default     = 2
}

variable "min_node_count" {
  description = "Minimum number of nodes for autoscaling"
  type        = number
  default     = 2
}

variable "max_node_count" {
  description = "Maximum number of nodes for autoscaling"
  type        = number
  default     = 10
}

variable "kubernetes_api_access" {
  description = "List of allowed IPs/networks for K8s API access"
  default     = ["0.0.0.0/0"]
}

variable "cluster_web_access" {
  description = "List of allowed IPs/networks for HTTP/80 access"
  default     = ["0.0.0.0/0"]
}

variable "cluster_websecure_access" {
  description = "List of allowed IPs/networks for HTTPS/443 access"
  default     = ["0.0.0.0/0"]
}

# GitHub Personal Access Token for Actions Runner Controller
variable "github_token" {
  description = "GitHub Personal Access Token for Actions Runner Controller"
  type        = string
  sensitive   = true
}