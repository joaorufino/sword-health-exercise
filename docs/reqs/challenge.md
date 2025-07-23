# Platform Challenge: setting up a cloud
based cluster
The main goal of the technical challenge is to Set-up a Kubernetes (K8s) using an Infrastructure
as Code approach, in particular:
- As cloud provider, use Google Cloud or Amazon Web Services (AWS)
- Use the Cloud hosted flavor of K8s, EX: EKS (Elastic Kubernetes Service)
- Terraform should be the tool driving the entire configuration.
- Make sure that cluster is not publicly available
- Provision a way to access the cluster
- Provision a load balancer and configure it to distribute traffic to the Kubernetes nodes
- Prevision a MySQL database and automate the backup and restore of the database
- Deploy the following application to the previously created cluster:
https://hub.docker.com/r/swordhealth/node-example and create the following cloud
resources for it:
- MySQL Database
- This application should be able to access two buckets, in one bucket should only
be able to list and get and in the other bucket should be able to write
- This application should be able to consume from a queue (SQS if you choose
AWS or PubSub if you choose Google Cloud)
- Bonus: Using the Kubernetes API, the application should be able to list all the
pods running inside the kube-system namespace
- Deny access to this application from any other pod running inside the cluster
NOTES:
- All configuration made in this challenge should be flexible and reusable to enable the
creation of different environments (staging, pre-prod, prod, etc).
- The application running in docker image we are providing doesn’t require any of the
resources specified. The goal with those resources is to only create them as a code
Regarding additional requirements related to the delivery:
- You are free to choose how terraform state is persisted and how planning and execution
should be done (Github and/or Terraform Cloud, etc)
- Share instructions on how to access and execute your solution for creating the cluster.
- Bonus: if you have the cluster up and running, it would be ideal to be able to access it
too.
