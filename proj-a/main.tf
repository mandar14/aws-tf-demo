###### Defination of AWS resources to be create
### using module

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

locals{
  azs= data.aws_availability_zones.available.names
  dmz-cidrs = [ for az in local.azs:
                  "${var.vpc-prefix}.${1 + index(local.azs,az)}.0/24"]
  pvt-cidrs = [ for az in local.azs:
                  "${var.vpc-prefix}.${11 + index(local.azs,az)}.0/24"]
}


module "vpc"{
    source = "terraform-aws-modules/vpc/aws"
    version = "~>2.0"
    name = var.vpc-name
    cidr = "${var.vpc-prefix}.0.0/16"
    public_subnets = local.dmz-cidrs
    private_subnets = local.pvt-cidrs
    azs = local.azs
    enable_nat_gateway = true
    single_nat_gateway = true
    enable_s3_endpoint = true

}

resource "aws_security_group" "web" {
  name = "web"
  vpc_id = module.vpc.vpc_id
  
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
  vpc_id = module.vpc.vpc_id
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
  subnet_ids = module.vpc.private_subnets #[for subnet in aws_subnet.private-subnet:subnet.id]
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
