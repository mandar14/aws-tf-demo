terraform {
  backend "s3" {
    bucket = "mk-tf-state"
    key    = "mkdev.state"
    region = "eu-central-1"
  }  
}  
