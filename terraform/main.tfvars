cluster_name="munya-qa-aws-za"
kubernetes_version = "1.17"
worker_count = 3
max_worker_count = 3
environment = "qa"
project = "munya"
region = "eu-west-1"
map_users = ["munya"]
# Official Cape Town Amazon ami owner
worker_ami_owner = "877085696533"

databases = {
    "infra-db" = {
        instance_class = "db.t3.small"
        engine         = "postgres"
        engine_version = "11.10"
    }
}
