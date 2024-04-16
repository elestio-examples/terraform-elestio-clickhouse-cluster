resource "elestio_load_balancer" "load_balancer" {
  project_id    = elestio_project.project.id
  provider_name = "hetzner"
  datacenter    = "fsn1"
  server_type   = "SMALL-1C-2G"
  config = {
    target_services = [for replica in module.cluster.replicas : replica.id]
    forward_rules = [
      {
        # Clickhouse HTTPS port (handled by Nginx)
        # HTTPS:18123 -> Nginx -> HTTP:21823
        port            = "18123"
        protocol        = "HTTPS"
        target_port     = "18123"
        target_protocol = "HTTPS"
      },
      {
        # Clickhouse TCP port
        port            = "29000"
        protocol        = "TCP"
        target_port     = "29000"
        target_protocol = "TCP"
      },
      {
        # MySQL port
        port            = "24306"
        protocol        = "TCP"
        target_port     = "24306"
        target_protocol = "TCP"
      },
      {
        # PostgreSQL port
        port            = "25432"
        protocol        = "TCP"
        target_port     = "25432"
        target_protocol = "TCP"
      },
    ]
  }
}

output "load_balancer_cname" {
  value = elestio_load_balancer.load_balancer.cname
}
