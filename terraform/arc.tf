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

# Create the runner deployment custom resource if repository is specified
resource "kubernetes_manifest" "runner_deployment" {
  count = var.github_username != "" && var.github_repo != "" ? 1 : 0

  manifest = {
    apiVersion = "actions.summerwind.dev/v1alpha1"
    kind       = "RunnerDeployment"
    metadata = {
      name      = "github-runner"
      namespace = kubernetes_namespace.actions_runner_system.metadata[0].name
    }
    spec = {
      replicas = 1
      template = {
        spec = {
          repository = "${var.github_username}/${var.github_repo}"
          labels     = ["self-hosted", "linux", "x64"]
          resources = {
            limits = {
              cpu    = "1000m"
              memory = "2Gi"
            }
            requests = {
              cpu    = "500m"
              memory = "1Gi"
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.actions_runner_controller
  ]
}

# Create the horizontal runner autoscaler custom resource if repository is specified
resource "kubernetes_manifest" "runner_autoscaler" {
  count = var.github_username != "" && var.github_repo != "" ? 1 : 0

  manifest = {
    apiVersion = "actions.summerwind.dev/v1alpha1"
    kind       = "HorizontalRunnerAutoscaler"
    metadata = {
      name      = "github-runner-autoscaler"
      namespace = kubernetes_namespace.actions_runner_system.metadata[0].name
    }
    spec = {
      scaleTargetRef = {
        name = "github-runner"
      }
      minReplicas      = 1
      maxReplicas      = 20
      metrics = [
        {
          type               = "TotalNumberOfQueuedAndInProgressWorkflowRuns"
          scaleUpThreshold   = "2"
          scaleDownThreshold = "1"
          scaleUpFactor      = "2"
          scaleDownFactor    = "0.5"
        }
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.runner_deployment
  ]
}