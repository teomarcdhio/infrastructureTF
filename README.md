Create a terrafomr.auto.tfvars and define the following:
location = "uksouth"
resource_group = "resourcegroupname"
cloud_shell_source = "ipoforigin"
domain_name_prefix = "azuredomainname"
management_ip = "ipoforigin"
winvmuser = "ausername"
winvmpass = "somestrongpassword"
Terraform init
Terraform plan
Terraform apply
Run terraform output -raw tls_private_key to see the actual ssh key