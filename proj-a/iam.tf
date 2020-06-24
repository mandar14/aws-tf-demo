#####IAM Resources
##--Reads local policy template, substitute desired variable
##--Creates IAM role, iam_role_policy & instance profile


data "template_file" "policy"{
  template = file("mk-s3-rds-policy.json")
  vars = {
    bucket-arn = aws_s3_bucket.datalake.arn
    db-instance-arn = aws_db_instance.db1.arn
  }
}

resource "aws_iam_role" "a-role"{
  name = "a-role"
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "mk-policy" {
  depends_on = [aws_s3_bucket.datalake, aws_db_instance.db1]
  name = "mk-s3-rds-policy"
  role = aws_iam_role.a-role.id
  policy = data.template_file.policy.rendered
}

resource "aws_iam_instance_profile" "mk_asg_profile" {
  name = "mk_asg_profile"
  role = aws_iam_role.a-role.name
}

