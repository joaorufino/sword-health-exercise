# AWS Resources for App

- S3 bucket "app-readonly" with ListBucket and GetObject permissions
- S3 bucket "app-readwrite" with full permissions
- SQS queue with ReceiveMessage and DeleteMessage permissions
- Application Load Balancer in public subnets
- Target group with health checks for the app pods