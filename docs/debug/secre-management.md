`bash
  kubectl create namespace node-example
  kubectl create secret generic
  node-example-rds-credentials \
    --namespace=node-example \
    --from-literal=host="<RDS_HOST>" \
    --from-literal=port="3306" \
    --from-literal=database="<DB_NAME>" \
    --from-literal=username="<USERNAME>" \
    --from-literal=password="<PASSWORD>"
`
