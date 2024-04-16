module "cluster" {
  source = "elestio-examples/clickhouse-cluster/elestio"

  project_id          = "12345"
  cluster_name        = "MyCluster"
  clickhouse_password = "MyPassword1234"

  configuration_ssh_key = {
    username    = "terraform-user"
    public_key  = chomp(file("~/.ssh/id_rsa.pub"))
    private_key = file("~/.ssh/id_rsa")
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
    },
  ]
}
