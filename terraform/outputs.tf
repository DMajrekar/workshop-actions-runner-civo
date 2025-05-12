output "cluster_id" {
  description = "ID of the created Kubernetes cluster"
  value       = civo_kubernetes_cluster.runner_cluster.id
}

output "cluster_name" {
  description = "Name of the created Kubernetes cluster"
  value       = civo_kubernetes_cluster.runner_cluster.name
}

output "api_endpoint" {
  description = "API endpoint for the Kubernetes cluster"
  value       = civo_kubernetes_cluster.runner_cluster.api_endpoint
}

output "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  value       = "${path.module}/kubeconfig"
}

output "master_ip" {
  description = "IP address of the master node"
  value       = civo_kubernetes_cluster.runner_cluster.master_ip
}

output "dns_entry" {
  description = "DNS entry for the cluster"
  value       = civo_kubernetes_cluster.runner_cluster.dns_entry
}