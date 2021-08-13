locals {
  cluster_name = "demo-eks-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

variable "region" {
  default = "us-east-2"
}


data "terraform_remote_state" "demo_vpc" {
  backend = "s3"
  config = {
    bucket = "backend-state1234"
    key    = "demo-vpc/terraform.tfstate"
    region = "us-east-2"
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_version = "1.18"
  subnets         = [tostring(data.terraform_remote_state.demo_vpc.outputs.public_subnets[0]), tostring(data.terraform_remote_state.demo_vpc.outputs.public_subnets[1]), tostring(data.terraform_remote_state.demo_vpc.outputs.private_subnets[0]), tostring(data.terraform_remote_state.demo_vpc.outputs.private_subnets[1])]

  tags = {
    Environment = "development"
  }

  vpc_id = data.terraform_remote_state.demo_vpc.outputs.vpc_id

  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.small"
      additional_userdata           = "echo foo bar"
      asg_desired_capacity          = 1
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
    },
    {
      name                          = "worker-group-2"
      instance_type                 = "t2.small"
      additional_userdata           = "echo foo bar"
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_two.id]
      asg_desired_capacity          = 1
    },
  ]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
