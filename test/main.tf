

variable "region" {
  default = "eu-central-1"
}


provider "aws" {
  region = "${var.region}"     #eu-central-1
}

data "aws_availability_zones" "available" {}

locals{
azs= data.aws_availability_zones.available.names
dmz-cidr = [
   for az in local.azs:
     "10.20.${10+index(local.azs,az)}.0/24"
	]
}

output "dmz" {
  value = local.dmz-cidr
}
