locals {
  external_dns_namespace       = "external-dns"
  external_dns_service_account = "external-dns"
}

# IAM role for external-dns with Pod Identity trust policy
resource "aws_iam_role" "external_dns" {
  count = var.deploy_external_dns ? 1 : 0

  name = "${var.cluster_name}-external-dns"

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

resource "aws_iam_policy" "external_dns" {
  count = var.deploy_external_dns ? 1 : 0

  name = "${var.cluster_name}-external-dns"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets",
        ]
        Resource = "arn:aws:route53:::hostedzone/${var.route53_zone_id}"
      },
      {
        Effect   = "Allow"
        Action   = ["route53:ListHostedZones"]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  count = var.deploy_external_dns ? 1 : 0

  role       = aws_iam_role.external_dns[0].name
  policy_arn = aws_iam_policy.external_dns[0].arn
}

# Pod Identity association
resource "aws_eks_pod_identity_association" "external_dns" {
  count = var.deploy_external_dns ? 1 : 0

  cluster_name    = var.cluster_name
  namespace       = local.external_dns_namespace
  service_account = local.external_dns_service_account
  role_arn        = aws_iam_role.external_dns[0].arn
}

# Helm release
resource "helm_release" "external_dns" {
  count = var.deploy_external_dns ? 1 : 0

  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = var.external_dns_version
  namespace  = local.external_dns_namespace

  create_namespace = true

  set = [
    {
      name  = "serviceAccount.name"
      value = local.external_dns_service_account
    },
    {
      name  = "sources[0]"
      value = "gateway-httproute"
    },
    {
      name  = "policy"
      value = "sync"
    },
    {
      name  = "registry"
      value = "txt"
    },
    {
      name  = "txtOwnerId"
      value = var.cluster_name
    },
    {
      name  = "txtPrefix"
      value = "edns-"
    },
    {
      name  = "domainFilters[0]"
      value = var.domain_name
    },
    {
      name  = "zoneIdFilters[0]"
      value = var.route53_zone_id
    },
  ]

  depends_on = [
    aws_eks_pod_identity_association.external_dns,
    helm_release.envoy_gateway,
  ]
}
