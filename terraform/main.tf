# Main Terraform configuration for Civo Kubernetes cluster
# This file manages the Kubernetes cluster where GitHub Actions runners will be deployed

terraform {
  required_providers {
    civo = {
      source = "civo/civo"
      version = "~> 1.1"
    }
    helm = {
      source = "hashicorp/helm"
      version = "~> 2.17"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
  required_version = ">= 1.0.0"
}

provider "civo" {
  region = var.region
}

# Create a firewall for the K8s cluster
resource "civo_firewall" "kubernetes-firewall" {
  name = "${var.cluster_name}-firewall"
  create_default_rules = false

  # Allow inbound access to Kubernetes API
  ingress_rule {
    label      = "kubernetes-api"
    protocol   = "tcp"
    port_range = "6443"
    cidr       = var.kubernetes_api_access
    action     = "allow"
  }

  # Allow inbound HTTP access
  ingress_rule {
    label      = "http"
    protocol   = "tcp"
    port_range = "80"
    cidr       = var.cluster_web_access
    action     = "allow"
  }

  # Allow inbound HTTPS access
  ingress_rule {
    label      = "https"
    protocol   = "tcp"
    port_range = "443"
    cidr       = var.cluster_websecure_access
    action     = "allow"
  }
}

# Create the Kubernetes cluster
resource "civo_kubernetes_cluster" "runner_cluster" {
  name = var.cluster_name
  firewall_id = civo_firewall.kubernetes-firewall.id
  write_kubeconfig = true
  pools {
    size = var.node_size
    node_count = var.node_count
    label = "github-actions-runners"
  }
}

# Configure the Kubernetes provider
provider "kubernetes" {
  host                   = civo_kubernetes_cluster.runner_cluster.api_endpoint
  client_certificate     = base64decode(yamldecode(civo_kubernetes_cluster.runner_cluster.kubeconfig).users[0].user.client-certificate-data)
  client_key             = base64decode(yamldecode(civo_kubernetes_cluster.runner_cluster.kubeconfig).users[0].user.client-key-data)
  cluster_ca_certificate = base64decode(yamldecode(civo_kubernetes_cluster.runner_cluster.kubeconfig).clusters[0].cluster.certificate-authority-data)
}

# Configure the Helm provider
provider "helm" {
  kubernetes {
    host                   = civo_kubernetes_cluster.runner_cluster.api_endpoint
    client_certificate     = base64decode(yamldecode(civo_kubernetes_cluster.runner_cluster.kubeconfig).users[0].user.client-certificate-data)
    client_key             = base64decode(yamldecode(civo_kubernetes_cluster.runner_cluster.kubeconfig).users[0].user.client-key-data)
    cluster_ca_certificate = base64decode(yamldecode(civo_kubernetes_cluster.runner_cluster.kubeconfig).clusters[0].cluster.certificate-authority-data)
  }
}

# Save the kubeconfig to a local file
resource "local_file" "kubeconfig" {
  content  = civo_kubernetes_cluster.runner_cluster.kubeconfig
  filename = "${path.module}/kubeconfig"
}