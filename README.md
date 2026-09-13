# terraform-aws-eks-platform

Reusable Terraform module that deploys operational add-ons on top of an EKS cluster:

- **AWS Load Balancer Controller** — provisions NLBs for Kubernetes Services
- **Envoy Gateway** — Gateway API-based ingress with NLB integration
- **cert-manager** — automated TLS certificates via DNS-01 / Route53
- **External Secrets Operator** — syncs AWS Secrets Manager into Kubernetes
- **external-dns** — automated DNS records for Gateway API resources

Each component is independently toggleable via `deploy_*` feature flags.

## Usage

```hcl
module "platform" {
  source = "github.com/tentozen/terraform-aws-eks-platform"

  cluster_name    = "my-cluster"
  vpc_id          = "vpc-abc123"
  domain_name     = "dev.example.com"
  route53_zone_id = "Z1234567890"
}
```

## Fresh cluster deployment

`kubernetes_manifest` resources validate CRDs at plan time. On a fresh cluster the CRDs don't exist yet, so a full plan fails. Two-pass apply:

```bash
terraform apply -target=module.platform.helm_release.envoy_gateway
terraform apply
```

After the first apply, CRDs are registered and subsequent plans work normally.

## Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `cluster_name` | EKS cluster name | `string` | — |
| `vpc_id` | VPC ID for AWS LBC | `string` | — |
| `domain_name` | Domain for cert-manager and external-dns | `string` | — |
| `route53_zone_id` | Route53 zone ID | `string` | — |
| `deploy_aws_lbc` | Deploy AWS Load Balancer Controller | `bool` | `true` |
| `deploy_envoy_gateway` | Deploy Envoy Gateway | `bool` | `true` |
| `deploy_cert_manager` | Deploy cert-manager | `bool` | `true` |
| `deploy_external_secrets` | Deploy External Secrets Operator | `bool` | `true` |
| `deploy_external_dns` | Deploy external-dns | `bool` | `true` |
| `aws_lbc_version` | Helm chart version | `string` | `"3.5.0"` |
| `envoy_gateway_version` | Helm chart version | `string` | `"v1.9.1"` |
| `cert_manager_version` | Helm chart version | `string` | `"v1.21.2"` |
| `external_secrets_version` | Helm chart version | `string` | `"0.12.1"` |
| `external_dns_version` | Helm chart version | `string` | `"1.22.0"` |
