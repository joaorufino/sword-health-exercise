# Networking 
- VPC: 10.0.0.0/16
- 3 subnets: public, private, data
- 3 AZs
- 1 NAT Gateway (i know i know but it is an example :D) 

## Subnets
`src/live-infra/dev/_global/vpc/common.hcl`

- Public: /20 - ALBs
- Private: /18 - EKS
- Data: /22 - RDS

## Apply
```bash
cd src/live-infra/dev/_global/vpc
terragrunt apply
```

Module: `src/infra-modules/src/networking/vpc/`
