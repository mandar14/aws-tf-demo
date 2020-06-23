terraform {
  backend "s3" {
    bucket = "mk-tf-state"
    key    = "proj-a/dev.state"
    region = "eu-central-1"
  }  
}  
