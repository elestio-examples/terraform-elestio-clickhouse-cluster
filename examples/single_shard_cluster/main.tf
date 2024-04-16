terraform {
  required_providers {
    elestio = {
      source = "elestio/elestio"
    }
  }
}

# Set the variables values in the `terraform.tfvars` file
variable "elestio_email" {
  type      = string
  sensitive = true
}
variable "elestio_api_token" {
  type      = string
  sensitive = true
}
variable "clickhouse_password" {
  type      = string
  sensitive = true
}

provider "elestio" {
  email     = var.elestio_email
  api_token = var.elestio_api_token
}

resource "elestio_project" "project" {
  name = "Clickhouse Cluster"
}

module "cluster" {
  source = "elestio-examples/clickhouse-cluster/elestio"

  project_id          = elestio_project.project.id
  cluster_name        = "MyCluster"
  clickhouse_password = var.clickhouse_password

  configuration_ssh_key = {
    # You can generate a new one: `ssh-keygen -t rsa -f terraform_rsa`
    # Never commit the key. Add it to .gitignore
    username    = "terraform"
    public_key  = chomp(file("./terraform_rsa.pub"))
    private_key = file("./terraform_rsa")
  }

  replicas = [
    {
      replica_name  = "clickhouse-01"
      shard_name    = "shard-01"
      provider_name = "hetzner"
      datacenter    = "fsn1"
      server_type   = "SMALL-1C-2G"
    },
    {
      replica_name  = "clickhouse-02"
      shard_name    = "shard-01"
      provider_name = "hetzner"
      datacenter    = "fsn1"
      server_type   = "SMALL-1C-2G"
    },
    {
      replica_name  = "clickhouse-03"
      shard_name    = "shard-01"
      provider_name = "hetzner"
      datacenter    = "fsn1"
      server_type   = "SMALL-1C-2G"
    }
  ]
}

output "replicas_ports" {
  value = module.cluster.replicas_ports
}

output "replicas_cnames" {
  value     = { for replica in module.cluster.replicas : replica.server_name => replica.cname }
  sensitive = true
}

output "replicas_admins" {
  value       = { for replica in module.cluster.replicas : replica.server_name => replica.admin }
  sensitive   = true
  description = "Web Admin Interface (documentation  https://tabix.io/doc/)"
}

