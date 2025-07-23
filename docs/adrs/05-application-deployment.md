# Application Deployment

- Change the app to ensure we can properly test and visualize the permissions
- Helm chart for the swordhealth/node-example app
- Service account with IRSA for AWS permissions
- ClusterRole to list pods in kube-system namespace
- NetworkPolicy to isolate the app from other pods

Considerations:
- we need the load balancer controller to create the aws resources
- we shall deploy the chart with terraform since we dont really have a deployment system in place
