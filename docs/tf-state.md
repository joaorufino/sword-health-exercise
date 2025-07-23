# Terraform State Management

## Overview

Terraform state is persisted using AWS S3 backend with DynamoDB for state locking. 

Configuration is in `src/live-infra/root.hcl:108-132`.

Bucket name will be `{name_prefix}-{account_name}-{aws_region}-tf-state`

I have disabled both logs and versioning but you can enable them for best practices.

