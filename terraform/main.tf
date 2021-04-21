data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

locals {
  map_users = [for user in var.map_users: {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${user}"
      username = user
      groups   = ["system:masters"]
  }]
}

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.64.0"

  name                 = var.cluster_name
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  database_subnets     = ["10.0.21.0/24", "10.0.22.0/24"]
  elasticache_subnets  = ["10.0.31.0/24", "10.0.32.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

resource "aws_security_group" "sec_grp_rds" {
  name_prefix = "${var.cluster_name}-"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_security_group_rule" "allow_worker_nodes_rds" {
  description              = "Allow worker nodes to communicate with database"
  from_port                = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec_grp_rds.id
  source_security_group_id = module.eks.worker_security_group_id
  to_port                  = 5432
  type                     = "ingress"
}

resource "random_password" "db_password" {
  for_each = var.databases
  length = 16
  special = true
  override_special = "_"
}

resource "aws_db_instance" "pg_databases" {
  for_each = var.databases
  allocated_storage     = 5
  max_allocated_storage = 100
  multi_az              = true

  db_subnet_group_name = module.vpc.database_subnet_group
  engine               = each.value.engine
  engine_version       = each.value.engine_version
  identifier           = each.key
  instance_class       = each.value.instance_class
  storage_encrypted    = true
  username             = "postgres"
  password             = random_password.db_password[each.key].result
  ca_cert_identifier   = "rds-ca-2019-af-south-1"

  parameter_group_name = aws_db_parameter_group.rds_postgres_parameter_group.name


  vpc_security_group_ids  = [
    aws_security_group.sec_grp_rds.id,
    module.eks.cluster_primary_security_group_id
  ]

  backup_retention_period = 7

  tags = {
    Environment = var.environment
    Project     = var.project
  }

  final_snapshot_identifier = "${each.key}-snap-${uuid()}"

  skip_final_snapshot = false
}

resource "aws_elasticache_cluster" "infra-redis" {
  cluster_id           = "infra-redis"
  engine               = "redis"
  node_type            = "cache.t3.small"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  engine_version       = "5.0.6"
  port                 = 6379
  subnet_group_name    = module.vpc.database_subnet_group
  security_group_ids   = [
    module.eks.cluster_primary_security_group_id
  ]

  snapshot_retention_limit = 7
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "13.2.1"

  cluster_name = var.cluster_name
  subnets      = module.vpc.private_subnets
  cluster_version = var.kubernetes_version

  tags = {
    Environment = var.environment
    Project  = var.project
  }

  vpc_id = module.vpc.vpc_id

  # Need this for CPT region even though we are using managed node groups.
  worker_ami_owner_id = var.worker_ami_owner

  node_groups_defaults = {
    ami_type  = "AL2_x86_64" # Non GPU
    disk_size = 50
  }

  node_groups = {
    node_group1 = {
      desired_capacity = var.worker_count
      max_capacity     = var.max_worker_count
      min_capacity     = var.worker_count

      instance_type = "t3.medium"
      k8s_labels = {
        Environment = var.environment
      }
    }
  }
  # map_roles                            = var.map_roles
  map_users                            = local.map_users
  map_accounts                         = var.map_accounts
}

module "deploy_clusterapps" {
  source             = "git@github.com:praekeltfoundation/cluster-infra-terraform.git//modules/bootstrap-deploy?ref=v0.0.2"
  deploy_clusterapps = var.deploy_clusterapps

  depends_on = [
    module.eks.cluster_id,
    module.eks.node_groups,
  ]

  kubeconfig_filename = module.eks.kubeconfig_filename
  secret_filename     = "munya-qa-sealed-secrets.json"

  database_credentials = {
    for db_id, db in var.databases: db_id => {
      namespace      = "ext-postgres-operator-${db_id}"
      cloud_provider = "AWS"
      db_host        = aws_db_instance.pg_databases[db_id].address
      db_name        = "postgres"
      db_user        = aws_db_instance.pg_databases[db_id].username
      db_password    = random_password.db_password[db_id].result
    }
  }
}
