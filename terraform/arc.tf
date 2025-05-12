# Create namespace for ARC
resource "kubernetes_namespace" "actions_runner_system" {
  metadata {
    name = "actions-runner-system"
  }

  depends_on = [
    civo_kubernetes_cluster.runner_cluster
  ]
}

# Create the GitHub PAT secret for ARC
resource "kubernetes_secret" "controller_manager" {
  metadata {
    name      = "controller-manager"
    namespace = kubernetes_namespace.actions_runner_system.metadata[0].name
  }

  data = {
    github_token = var.github_token
  }

  depends_on = [
    kubernetes_namespace.actions_runner_system
  ]
}

# Install Actions Runner Controller using Helm
resource "helm_release" "actions_runner_controller" {
  name       = "actions-runner-controller"
  repository = "https://actions-runner-controller.github.io/actions-runner-controller"
  chart      = "actions-runner-controller"
  namespace  = kubernetes_namespace.actions_runner_system.metadata[0].name
  version    = "0.23.7"

  set {
    name  = "syncPeriod"
    value = "1m"
  }

  # Configure GitHub PAT authentication
  set {
    name  = "authSecret.create"
    value = "false"
  }

  set {
    name  = "authSecret.name"
    value = "controller-manager"
  }

  set {
    name  = "github.authType"
    value = "token"
  }

  depends_on = [
    civo_kubernetes_cluster.runner_cluster,
    helm_release.cert_manager,
    kubernetes_secret.controller_manager
  ]
}