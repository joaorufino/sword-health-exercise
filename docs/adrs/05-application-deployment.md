# Application Deployment

- Helm chart for the swordhealth/node-example app
- Kubernetes deployment with configurable replicas
- Service account with IRSA for AWS permissions
- ClusterRole to list pods in kube-system namespace
- NetworkPolicy to isolate the app from other pods