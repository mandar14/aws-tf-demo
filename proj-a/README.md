# Project A
Project A is independant terraform project, it showcase the use of aws modules and resources\

#### main.tf
Creates s3-bucket,security-groups,rds-db and VPC networking(using module)
#### iam.tf
Reads policy template and Creates iam-role for ec2-service, policy and instance profile
#### mk-s3-rds-policy.json
Policy template in json format
#### scaling.tf
Defines ELB and Autoscaling resources using aws-terraform module
#### state.tf
Defines terraform state backend config
#### variable.tf
variables to be defined for project


#### High-level design
![HLD](https://github.com/mandar14/aws-tf-demo/blob/master/proj-a/hld_diagram.png?raw=true)
