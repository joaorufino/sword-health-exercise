## Infrastructure Requirements

### REQ-INFRA-001-AWS
**Title**: Cloud Provider Selection  
**Description**: Use Amazon Web Services (AWS) as the cloud provider  
**Priority**: Must Have  

### REQ-INFRA-002-EKS
**Title**: Kubernetes Cluster  
**Description**: Deploy Elastic Kubernetes Service (EKS) for managed Kubernetes  
**Priority**: Must Have  

### REQ-INFRA-003-IAC
**Title**: Infrastructure as Code  
**Description**: Use Terraform for all infrastructure provisioning and configuration  
**Priority**: Must Have  

### REQ-INFRA-004-MULTI-ENV
**Title**: Multi-Environment Support  
**Description**: Infrastructure code must be flexible and reusable to enable creation of different environments (staging, pre-prod, prod, etc.)  
**Priority**: Must Have  

## Security Requirements

### REQ-SEC-001-PRIVATE-CLUSTER
**Title**: Private EKS Cluster  
**Description**: EKS cluster must not be publicly accessible from the internet  
**Priority**: Must Have  
**ARGUMENT AGAINST**: It will be publicacly available but only accessible from specific IPs 


### REQ-SEC-002-ACCESS-METHOD
**Title**: Secure Cluster Access  
**Description**: Provision a secure method to access the private EKS cluster  
**Priority**: Must Have


### REQ-SEC-003-POD-ISOLATION
**Title**: Application Pod Isolation  
**Description**: Deny access to the node-example application from any other pod running inside the cluster  
**Priority**: Must Have  

## Networking Requirements

### REQ-NET-001-LOAD-BALANCER
**Title**: Load Balancer Configuration  
**Description**: Provision a load balancer and configure it to distribute traffic to the Kubernetes nodes  
**Priority**: Must Have  

## Database Requirements

### REQ-DB-001-MYSQL
**Title**: MySQL Database  
**Description**: Provision a MySQL database for the application  
**Priority**: Must Have  

### REQ-DB-002-BACKUP
**Title**: Database Backup Automation  
**Description**: Automate the backup and restore process for the MySQL database  
**Priority**: Must Have  

## Application Requirements

### REQ-APP-001-DEPLOYMENT
**Title**: Node Example Application  
**Description**: Deploy swordhealth/node-example Docker image to the EKS cluster  
**Priority**: Must Have  

### REQ-APP-002-MYSQL-ACCESS
**Title**: Database Connectivity  
**Description**: Application must have access to the MySQL database  
**Priority**: Must Have  

## Storage Requirements

### REQ-STOR-001-S3-READ
**Title**: S3 Read-Only Bucket  
**Description**: Create S3 bucket where the application can only list and get objects  
**Priority**: Must Have  

### REQ-STOR-002-S3-WRITE
**Title**: S3 Write Bucket  
**Description**: Create S3 bucket where the application has write permissions  
**Priority**: Must Have  

## Messaging Requirements

### REQ-MSG-001-SQS
**Title**: SQS Queue Access  
**Description**: Application must be able to consume messages from an SQS queue  
**Priority**: Must Have  

## Kubernetes API Requirements

### REQ-K8S-001-API-ACCESS
**Title**: Kubernetes API Access  
**Description**: Application should be able to list all pods running in the kube-system namespace using the Kubernetes API  
**Priority**: Nice to Have (Bonus)  

## Delivery Requirements

### REQ-DEL-001-STATE
**Title**: Terraform State Management  
**Description**: Implement persistent storage for Terraform state  
**Priority**: Must Have  

### REQ-DEL-002-CICD
**Title**: Terraform Execution Strategy  
**Description**: Define how Terraform planning and execution should be performed (e.g., GitHub Actions, Terraform Cloud)  
**Priority**: Must Have  

### REQ-DEL-003-DOCS
**Title**: Access Instructions  
**Description**: Provide clear instructions on how to access and execute the solution  
**Priority**: Must Have  

### REQ-DEL-004-CLUSTER-ACCESS
**Title**: Live Cluster Access  
**Description**: If cluster is running, provide access to it  
**Priority**: Nice to Have (Bonus)  
