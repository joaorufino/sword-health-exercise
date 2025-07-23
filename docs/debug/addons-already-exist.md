Sometimes when you are creating the addons without nodes the addons start having issues.

if that happens 
1. check the cluster status
2. check the state of the addon

`bash
  aws eks describe-cluster --name
  sword-health-dev-eks --region
  eu-central-1 --query 'cluster.status'
`

`
terragrunt import 'aws_eks_addon.main["coredn
s"]' sword-health-dev-eks:coredns

`
