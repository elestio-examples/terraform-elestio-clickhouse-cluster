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
  # You can add more replicas here
  {
    replica_name  = "clickhouse-04"
    shard_name    = "shard-01"
    provider_name = "hetzner"
    datacenter    = "fsn1"
    server_type   = "SMALL-1C-2G"
  }
]
