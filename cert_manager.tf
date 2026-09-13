locals {
  cert_manager_namespace       = "cert-manager"
  cert_manager_service_account = "cert-manager"
}

# IAM role for cert-manager with Pod Identity trust policy
resource "aws_iam_role" "cert_manager" {
  count = var.deploy_cert_manager ? 1 : 0

  name = "${var.cluster_name}-cert-manager"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession",
      ]
    }]
  })
}

resource "aws_iam_policy" "cert_manager" {
  count = var.deploy_cert_manager ? 1 : 0

  name = "${var.cluster_name}-cert-manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:GetChange"]
        Resource = "arn:aws:route53:::change/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets",
        ]
        Resource = "arn:aws:route53:::hostedzone/${var.route53_zone_id}"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cert_manager" {
  count = var.deploy_cert_manager ? 1 : 0

  role       = aws_iam_role.cert_manager[0].name
  policy_arn = aws_iam_policy.cert_manager[0].arn
}

# Pod Identity association
resource "aws_eks_pod_identity_association" "cert_manager" {
  count = var.deploy_cert_manager ? 1 : 0

  cluster_name    = var.cluster_name
  namespace       = local.cert_manager_namespace
  service_account = local.cert_manager_service_account
  role_arn        = aws_iam_role.cert_manager[0].arn
}

# Helm release
resource "helm_release" "cert_manager" {
  count = var.deploy_cert_manager ? 1 : 0

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_version
  namespace  = local.cert_manager_namespace

  create_namespace = true

  set = [
    {
      name  = "config.gatewayAPI.enabled"
      value = "true"
    },
    {
      name  = "crds.enabled"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = local.cert_manager_service_account
    },
  ]

  depends_on = [
    aws_eks_pod_identity_association.cert_manager,
    helm_release.envoy_gateway,
  ]
}

# ClusterIssuer with DNS-01 solver via Route53 (Pod Identity handles auth)
resource "kubernetes_manifest" "cluster_issuer" {
  count = var.deploy_cert_manager ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt"
    }
    spec = {
      acme = {
        email  = var.cert_manager_acme_email
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-account-key"
        }
        solvers = [
          {
            dns01 = {
              route53 = {}
            }
          },
        ]
      }
    }
  }

  depends_on = [
    helm_release.cert_manager,
  ]
}
