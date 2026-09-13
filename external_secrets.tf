locals {
  external_secrets_namespace       = "external-secrets"
  external_secrets_service_account = "external-secrets"
}

# IAM role for External Secrets with Pod Identity trust policy
resource "aws_iam_role" "external_secrets" {
  count = var.deploy_external_secrets ? 1 : 0

  name = "${var.cluster_name}-external-secrets"

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

resource "aws_iam_policy" "external_secrets" {
  count = var.deploy_external_secrets ? 1 : 0

  name = "${var.cluster_name}-external-secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
        ]
        Resource = "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:*"
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:ListSecrets"]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  count = var.deploy_external_secrets ? 1 : 0

  role       = aws_iam_role.external_secrets[0].name
  policy_arn = aws_iam_policy.external_secrets[0].arn
}

# Pod Identity association
resource "aws_eks_pod_identity_association" "external_secrets" {
  count = var.deploy_external_secrets ? 1 : 0

  cluster_name    = var.cluster_name
  namespace       = local.external_secrets_namespace
  service_account = local.external_secrets_service_account
  role_arn        = aws_iam_role.external_secrets[0].arn
}

# Helm release
resource "helm_release" "external_secrets" {
  count = var.deploy_external_secrets ? 1 : 0

  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = var.external_secrets_version
  namespace  = local.external_secrets_namespace

  create_namespace = true

  set = [
    {
      name  = "serviceAccount.name"
      value = local.external_secrets_service_account
    },
  ]

  depends_on = [
    aws_eks_pod_identity_association.external_secrets,
  ]
}

# ClusterSecretStore — no auth block; Pod Identity handles authentication
resource "kubernetes_manifest" "cluster_secret_store" {
  count = var.deploy_external_secrets ? 1 : 0

  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "aws-secrets-manager"
    }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = data.aws_region.current.region
        }
      }
    }
  }

  depends_on = [
    helm_release.external_secrets,
  ]
}
