replicas = [
  // Europe replicas
  {
    replica_name  = "clickhouse-01"
    shard_name    = "shard-europe"
    provider_name = "hetzner"
    datacenter    = "fsn1"
    server_type   = "SMALL-1C-2G"
  },
  {
    replica_name  = "clickhouse-02"
    shard_name    = "shard-europe"
    provider_name = "hetzner"
    datacenter    = "fsn1"
    server_type   = "SMALL-1C-2G"
  },

  // Asia replicas
  {
    replica_name  = "clickhouse-03"
    shard_name    = "shard-asia"
    provider_name = "hetzner"
    datacenter    = "fsn1"
    server_type   = "SMALL-1C-2G"
  },
  {
    replica_name  = "clickhouse-04"
    shard_name    = "shard-asia"
    provider_name = "hetzner"
    datacenter    = "fsn1"
    server_type   = "SMALL-1C-2G"
  }
]
