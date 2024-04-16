output "replicas" {
  value       = elestio_clickhouse.replicas
  sensitive   = true
  description = "All the terraform information about the replicas in your cluster."
}

output "replicas_ports" {
  value = {
    18123 = "HTTPS port",
    28123 = "HTTP port",
    29000 = "Native TCP port (used by `clickhouse-server` and `clickhouse-client`)"
    24306 = "MySQL port",
    25432 = "PostgreSQL port"
    9009  = "Inter-server communication port for low-level data access. Used for data exchange, replication, and inter-server communication."
  }
  description = "The list of ports used by the replica for ClickHouse. They are open by default in your Elestio firewall settings."
}
