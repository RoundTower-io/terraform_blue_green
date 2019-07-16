# terraform_blue_green
A simple terraform script to demonstrate blue/green deployments with a lambda script

# Background 
This borrows heavily from [this article](https://learn.hashicorp.com/terraform/aws/lambda-api-gateway).

# To use this

## First, we bring up the basic environment
```bash
terraform init
terraform apply -auto-approve
``` 
## Then, we switch between Blue and Green deployments
```bash
terraform apply -var="deployment=green"
```
