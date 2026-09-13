# Required inputs

variable "cluster_name" {
  description = "Name of the EKS cluster. Used in IAM role names and Pod Identity associations."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster runs. Used by AWS Load Balancer Controller."
  type        = string
}

variable "domain_name" {
  description = "Domain name for cert-manager ClusterIssuer and external-dns domain filter."
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for DNS validation and record management."
  type        = string
}

# Feature flags

variable "cert_manager_acme_email" {
  description = "Email address for Let's Encrypt ACME registration."
  type        = string
}

variable "deploy_aws_lbc" {
  description = "Deploy AWS Load Balancer Controller."
  type        = bool
  default     = true
}

variable "deploy_envoy_gateway" {
  description = "Deploy Envoy Gateway."
  type        = bool
  default     = true
}

variable "deploy_cert_manager" {
  description = "Deploy cert-manager."
  type        = bool
  default     = true
}

variable "deploy_external_secrets" {
  description = "Deploy External Secrets Operator."
  type        = bool
  default     = true
}

variable "deploy_external_dns" {
  description = "Deploy external-dns."
  type        = bool
  default     = true
}

# Version overrides

variable "aws_lbc_version" {
  description = "Helm chart version for AWS Load Balancer Controller."
  type        = string
  default     = "3.5.0"
}

variable "envoy_gateway_version" {
  description = "Helm chart version for Envoy Gateway."
  type        = string
  default     = "v1.9.1"
}

variable "cert_manager_version" {
  description = "Helm chart version for cert-manager."
  type        = string
  default     = "v1.21.2"
}

variable "external_secrets_version" {
  description = "Helm chart version for External Secrets Operator."
  type        = string
  default     = "0.12.1"
}

variable "external_dns_version" {
  description = "Helm chart version for external-dns."
  type        = string
  default     = "1.22.0"
}
