terraform {
  backend "s3" {
    bucket = "my-tf-bucket-nishchi"
    key    = "terraform/infra.tfstate"
    region = "us-east-1"
  }
}
