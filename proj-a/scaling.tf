### Defination of launch config, auto-scaling group and ELB

module "elb" {
  source = "terraform-aws-modules/elb/aws"

  name = "web-elb"

  subnets         = module.vpc.public_subnets
  security_groups = [aws_security_group.web.id]
  internal        = false

  listener = [
    {
      instance_port     = "80"
      instance_protocol = "HTTP"
      lb_port           = "80"
      lb_protocol       = "HTTP"
    },
  ]

  health_check = {
    target              = "HTTP:80/index.html"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  tags = {
    Name = "web-front"
  }
}

output "dns"{
  value = module.elb.this_elb_dns_name
}


data "aws_ami" "ubuntu"{
  most_recent = true
  owners = ["099720109477"]

  filter{
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}


### auto-scaling module for lunch config and group setttings

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"

  name = "asg-mk"

#----launch config-----
  lc_name = "mk-lc"

  image_id = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  security_groups = [aws_security_group.web.id]
  load_balancers  = [module.elb.this_elb_id]
  root_block_device = [
   {
     volume_size = "10"
     volume_type = "gp2"
   },
  ]
  ebs_block_device = [
    {
      device_name           = "/dev/xvdz"
      volume_type           = "gp2"
      volume_size           = "5"
      delete_on_termination = true
      encrypted             = true
    },
  ]

  user_data = <<-EOF
		#! /bin/bash
                sudo apt-get update
		sudo apt-get install -y apache2
		sudo systemctl start apache2
		sudo systemctl enable apache2
		echo "<h1>Deployed via Terraform by MK... \(^_^)/</h1>" | sudo tee /var/www/html/index.html
	EOF
  key_name = "mk"
  iam_instance_profile = aws_iam_instance_profile.mk_asg_profile.name


#----auto scaling----
  asg_name = "mk-asg"
  vpc_zone_identifier = module.vpc.private_subnets
  health_check_type         = "EC2"
  min_size                  = 2
  max_size                  = 5
  desired_capacity          = 2
  wait_for_capacity_timeout = "150s"
}
