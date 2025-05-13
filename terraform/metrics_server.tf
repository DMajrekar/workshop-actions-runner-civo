# Install Kubernetes metrics-server using Helm
resource "helm_release" "metrics_server" {
  name             = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  namespace        = "kube-system"
  version          = "3.11.0"  # Use the latest stable version

  # Configuration values for metrics-server
  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"  # Required for some environments where kubelet doesn't have proper certificates
  }

  set {
    name  = "args[1]"
    value = "--kubelet-preferred-address-types=InternalIP"  # Prefer internal IPs for Civo cluster communication
  }

  set {
    name  = "resources.limits.cpu"
    value = "100m"
  }

  set {
    name  = "resources.limits.memory"
    value = "200Mi"
  }

  set {
    name  = "resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "resources.requests.memory"
    value = "100Mi"
  }

  depends_on = [
    civo_kubernetes_cluster.runner_cluster
  ]
}