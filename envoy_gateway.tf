locals {
  envoy_gateway_namespace  = "envoy-gateway-system"
  envoy_proxy_name         = "nlb-proxy"
}

# Helm release for Envoy Gateway (OCI chart)
resource "helm_release" "envoy_gateway" {
  count = var.deploy_envoy_gateway ? 1 : 0

  name       = "envoy-gateway"
  repository = "oci://docker.io/envoyproxy"
  chart      = "gateway-helm"
  version    = var.envoy_gateway_version
  namespace  = local.envoy_gateway_namespace

  create_namespace = true

  depends_on = [
    helm_release.aws_lbc,
  ]
}

# EnvoyProxy CRD — configures the data-plane proxy with NLB annotations
resource "kubernetes_manifest" "envoy_proxy" {
  count = var.deploy_envoy_gateway ? 1 : 0

  manifest = {
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "EnvoyProxy"
    metadata = {
      name      = local.envoy_proxy_name
      namespace = local.envoy_gateway_namespace
    }
    spec = {
      provider = {
        type = "Kubernetes"
        kubernetes = {
          envoyService = {
            annotations = {
              "service.beta.kubernetes.io/aws-load-balancer-type"   = "external"
              "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
            }
            type = "LoadBalancer"
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.envoy_gateway,
  ]
}

# GatewayClass — references the EnvoyProxy via parametersRef
resource "kubernetes_manifest" "gateway_class" {
  count = var.deploy_envoy_gateway ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata = {
      name = "envoy-gateway"
    }
    spec = {
      controllerName = "gateway.envoyproxy.io/gatewayclass-controller"
      parametersRef = {
        group     = "gateway.envoyproxy.io"
        kind      = "EnvoyProxy"
        name      = local.envoy_proxy_name
        namespace = local.envoy_gateway_namespace
      }
    }
  }

  depends_on = [
    helm_release.envoy_gateway,
  ]
}

# Default Gateway
resource "kubernetes_manifest" "gateway" {
  count = var.deploy_envoy_gateway ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "default"
      namespace = local.envoy_gateway_namespace
    }
    spec = {
      gatewayClassName = "envoy-gateway"
      listeners = [
        {
          name     = "http"
          protocol = "HTTP"
          port     = 80
        },
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.gateway_class,
    kubernetes_manifest.envoy_proxy,
  ]
}
