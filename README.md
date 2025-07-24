# AWS EKS Infrastructure - Requirements Implementation Map

This repository implements a production-ready Kubernetes infrastructure on AWS. The table below maps each requirement to its implementation.

## Requirements to Implementation Mapping

| Requirement | Description | Implementation Files | Status |
|-------------|-------------|---------------------|---------|
| **REQ-INFRA-001-AWS** | Use AWS as cloud provider | All modules use AWS provider | ✅ |
| **REQ-INFRA-002-EKS** | Deploy EKS for managed Kubernetes | `src/infra-modules/services/eks/eks-control-plane/`<br>`src/infra-modules/services/eks/eks-node-group/`<br>`src/live-infra/dev/eu-central-1/services/eks-control-plane/` | ✅ |
| **REQ-INFRA-003-IAC** | Use Terraform for infrastructure | All `.tf` files, Terragrunt for DRY | ✅ |
| **REQ-INFRA-004-MULTI-ENV** | Multi-environment support | `src/live-infra/_envcommon/`<br>`src/live-infra/dev/`<br>`src/live-infra/common.hcl` | ✅ |
| **REQ-SEC-001-PRIVATE-CLUSTER** | EKS not publicly accessible | `src/infra-modules/services/eks/eks-control-plane/main.tf`<br>`src/live-infra/_envcommon/eks-control-plane.hcl` | ⚠️ Public but IP-restricted |
| **REQ-SEC-002-ACCESS-METHOD** | Secure cluster access | IAM roles + kubectl configured in EKS module | ✅ |
| **REQ-SEC-003-POD-ISOLATION** | Isolate node-example app | | ⚠️TBD |
| **REQ-NET-001-LOAD-BALANCER** | Load balancer for traffic | `src/infra-modules/services/alb-controller-irsa/`<br>`src/live-infra/dev/eu-central-1/apps/aws-load-balancer-controller/` | ✅ |
| **REQ-DB-001-MYSQL** | MySQL database | `src/infra-modules/storage/rds/`<br>`src/live-infra/dev/eu-central-1/storage/rds-mysql/` | ✅ |
| **REQ-DB-002-BACKUP** | Database backup automation | `src/infra-modules/storage/rds/main.tf` (7-day backups) | ✅ |
| **REQ-APP-001-DEPLOYMENT** | Deploy node-example app | `src/kube-apps/charts/node-example/`<br>`src/live-infra/dev/eu-central-1/apps/node-example/` | ✅ |
| **REQ-APP-002-MYSQL-ACCESS** | App MySQL connectivity | `src/infra-modules/services/app-infrastructure/` | ✅ |
| **REQ-STOR-001-S3-READ** | S3 read-only bucket | `src/live-infra/dev/eu-central-1/storage/node-example-s3-readonly/` | ✅ |
| **REQ-STOR-002-S3-WRITE** | S3 write bucket | `src/live-infra/dev/eu-central-1/storage/node-example-s3/` | ✅ |
| **REQ-MSG-001-SQS** | SQS queue access | `src/infra-modules/messaging/sqs/`<br>`src/live-infra/dev/eu-central-1/messaging/node-example-sqs/` | ✅ |
| **REQ-K8S-001-API-ACCESS** | Kubernetes API access (Bonus) | `src/kube-apps/charts/node-example/templates/rbac.yaml` | ✅ |
| **REQ-DEL-001-STATE** | Terraform state management | `src/live-infra/common.hcl` (S3 backend) | ✅ |
| **REQ-DEL-002-CICD** | Terraform execution strategy | `src/live-infra/Makefile` | ✅ |
| **REQ-DEL-003-DOCS** | Access instructions | `docs/` folder with ADRs and guides | ✅ |
| **REQ-DEL-004-CLUSTER-ACCESS** | Live cluster access (Bonus) | Provided via kubectl config | ⚠️ Requires deployment |

## Quick Start

1. **Deploy Infrastructure**
   ```bash
   cd src/live-infra
   make apply ENV=dev
   ```

2. **Access Cluster**
   ```bash
   aws eks update-kubeconfig --region eu-central-1 --name dev-eks-cluster
   ```

## Key Implementation Notes

- **Terragrunt**: Used for DRY configuration across environments
- **Module Structure**: Reusable modules in `src/infra-modules/`
- **Environment Configs**: Live configurations in `src/live-infra/dev/`
- **Helm Charts**: Application deployment via Helm in `src/kube-apps/charts/`

## Status Legend
- ✅ Implemented
- 🚧 In Progress  
- ⚠️ Implemented with notes
- ❌ Not implemented
