# AQvis infrastructure

IaC Terraform code to provision resources for **TODO:** project.

Applying the code provisions:
- ECR registries for backend and frontend application (AQvis-backend, AQvis-frontend)
- ECS cluster
- ECS task definition
- VPC
- necessary policies, etc.

The code does not provision services that are not necessary but might be beneficial in the future 
for cost saving reasons. 
Those include:
- ALB (Application Load Balancer)
- ...

## Useful commands
```bash
terraform fmt
```
```bash
terraform init
```
```bash
terraform plan
```
```bash
terraform apply
```
```bash
terraform destroy
```
