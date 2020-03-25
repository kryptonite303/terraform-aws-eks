data "aws_iam_user" "brianmccarthy" {
  user_name = "brian.mccarthy"
}

data "aws_iam_user" "zakharkleyman" {
  user_name = "zakhar.kleyman"
}

data "aws_iam_user" "vitaliilirnyk" {
  user_name = "vitalii.lirnyk"
}

data "aws_iam_user" "jasonwalsh" {
  user_name = "jason.walsh"
}

data "aws_iam_user" "johnchen" {
  user_name = "john.chen"
}

resource "aws_eip" "nat" {
  count = 2
  vpc = true
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-2a", "us-east-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway        = true
  #map_public_ip_on_launch  = true
  enable_dns_hostnames      = true
  reuse_nat_ips             = true
  external_nat_ip_ids       = "${aws_eip.nat.*.id}"

  tags = {
    Terraform = "true"
    Environment = "dev"
    "kubernetes.io/cluster/my-cluster" = "shared"
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.my-cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.my-cluster.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}

module "my-cluster" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "my-cluster"
  cluster_version = "1.15"
  subnets         = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id

  worker_groups = [
    {
      instance_type = "m4.large"
      asg_max_size  = 5
      subnets = module.vpc.private_subnets
    }
  ]
  node_groups = {
    my-node-group = {
    }
  }
  map_users = [
    {
      userarn  = data.aws_iam_user.brianmccarthy.arn
      username = data.aws_iam_user.brianmccarthy.user_name
      groups   = ["system:masters"]
    },
    {
      userarn  = data.aws_iam_user.zakharkleyman.arn
      username = data.aws_iam_user.zakharkleyman.user_name
      groups   = ["system:masters"]
    },
    {
      userarn  = data.aws_iam_user.vitaliilirnyk.arn
      username = data.aws_iam_user.vitaliilirnyk.user_name
      groups   = ["system:masters"]
    },
    {
      userarn  = data.aws_iam_user.jasonwalsh.arn
      username = data.aws_iam_user.jasonwalsh.user_name
      groups   = ["system:masters"]
    },
    {
      userarn  = data.aws_iam_user.johnchen.arn
      username = data.aws_iam_user.johnchen.user_name
      groups   = ["system:masters"]
    },
  ]
}
