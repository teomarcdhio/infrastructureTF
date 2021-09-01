#Basic setup of an infrastrucre in Azure using Terraform

Create a terrafomr.auto.tfvars and define the following:
```
location = "uksouth"
resource_group = "resourcegroupname"
cloud_shell_source = "ipoforigin"
domain_name_prefix = "azuredomainname"
management_ip = "ipoforigin"
winvmuser = "ausername"
winvmpass = "somestrongpassword"
```
Initialize the terrafrom project
```
Terraform init
```
Test and apply
```
Terraform plan
Terraform apply
```
To see the actual ssh key run 
```
terraform output -raw tls_private_key
``` 