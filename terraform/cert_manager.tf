# Install cert-manager using Helm
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = "v1.17.2"

  # Install the CRDs as part of the Helm release
  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [
    civo_kubernetes_cluster.runner_cluster
  ]
}