###### TF file describing provider and resources ####

provider "aws" {
region = var.region     #eu-central-1
#  access_key = 
#  secret_key = 
}

resource "aws_s3_bucket" "datalake" {
bucket = "eu-datalake"
server_side_encryption_configuration {
rule {
apply_server_side_encryption_by_default {
sse_algorithm = "AES256"
}
}
}
}


####################
###VPC_NETWORKING###
####################

resource "aws_vpc" "kmandar" {
cidr_block  = "10.20.0.0/16"
enable_dns_hostnames = true
tags = {
Name = "kmandar" 
}
}

resource "aws_internet_gateway" "igw"{
vpc_id = aws_vpc.kmandar.id
tags = {Name = "external"} 
}

resource "aws_route_table" "ext-rtable"{
vpc_id = aws_vpc.kmandar.id
route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.igw.id
}
tags= { Name = "external" } 
}

resource "aws_route_table" "int-rtable" {
vpc_id = aws_vpc.kmandar.id
tags = {Name ="internal"}
}


### Get availability_zones from region###

data "aws_availability_zones" "available" {
state = "available"
}
locals{
azs = data.aws_availability_zones.available.names
}

output "azs" {
value = local.azs
}

resource "aws_subnet" "public-subnet" {
count = length(local.azs) # (data.aws_availability_zones.available.names)
vpc_id = aws_vpc.kmandar.id
cidr_block = "10.20.${count.index}.0/24"
tags= { Name = "dmz-az${count.index}"}
availability_zone= local.azs[count.index]
}

resource "aws_route_table_association" "ext" {
count = length(local.azs)
subnet_id = aws_subnet.public-subnet[count.index].id
route_table_id = aws_route_table.ext-rtable.id
}


resource "aws_subnet" "private-subnet" {
count = length(local.azs) # (data.aws_availability_zones.available.names)
vpc_id = aws_vpc.kmandar.id
cidr_block = "10.20.${10 + count.index}.0/24"
tags= { Name = "pvt-az${count.index}"}
availability_zone= local.azs[count.index]
}

resource "aws_route_table_association" "int" {
count = length(local.azs)
subnet_id = aws_subnet.private-subnet[count.index].id
route_table_id = aws_route_table.int-rtable.id
}

resource "aws_security_group" "web" {
name = "web"
vpc_id = aws_vpc.kmandar.id

ingress {
from_port = 80
to_port   = 80
protocol  = "tcp"
cidr_blocks = ["10.0.0.0/24"]
}
ingress {
from_port = 22
to_port   = 22
protocol  = "tcp"
cidr_blocks = ["18.157.215.15/32"]
}

egress {
from_port   = 0
to_port     = 0
protocol    = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
}

resource "aws_security_group" "db-access" {
name = "db-access"
vpc_id = aws_vpc.kmandar.id
depends_on = [aws_security_group.web]
ingress {
from_port = 3306
to_port   = 3306
protocol  = "tcp"
security_groups = [aws_security_group.web.id]
}
egress {
from_port   = 0
to_port     = 0
protocol    = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
}

### Database ###

resource "aws_db_subnet_group" "mkdb"{
  name = "mkdb"
  subnet_ids = [for subnet in aws_subnet.private-subnet:
                  subnet.id]
}
resource "aws_db_instance" "db1" {
allocated_storage    = 5
storage_type         = "gp2"
engine               = "mysql"
engine_version       = "5.7"
instance_class       = "db.t2.micro"
name                 = "mkdb"
username             = "admin"
password             = var.db_password

vpc_security_group_ids = [aws_security_group.db-access.id]
db_subnet_group_name = aws_db_subnet_group.mkdb.id

}  
