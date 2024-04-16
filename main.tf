resource "elestio_clickhouse" "replicas" {
  for_each         = { for replica in var.replicas : "${replica.shard_name}.${replica.replica_name}" => replica }
  project_id       = var.project_id
  version          = var.clickhouse_version
  default_password = var.clickhouse_password
  server_name      = each.value.replica_name
  provider_name    = each.value.provider_name
  datacenter       = each.value.datacenter
  server_type      = each.value.server_type
  firewall_enabled = each.value.firewall_enabled
  ssh_public_keys = concat(each.value.ssh_public_keys, [{
    username = var.configuration_ssh_key.username
    key_data = var.configuration_ssh_key.public_key
  }])
  local_field = {
    shard_name   = each.value.shard_name
    replica_name = each.value.replica_name
  }

  connection {
    type        = "ssh"
    host        = self.ipv4
    private_key = var.configuration_ssh_key.private_key
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt/app",
      "docker-compose down",
      "rm docker-compose.yml",
      "rm -rf config/*",
      "rm -rf data/*",
      "rm -rf log/*",
      "echo 'GLOBAL_PRIVATE_IP=${self.global_ip}' >> .env",
      "echo 'CNAME=${self.cname}' >> .env",
    ]
  }
}

resource "null_resource" "configure_replicas" {
  # Changes to any replicas of the cluster requires re-provisioning
  for_each = elestio_clickhouse.replicas


  triggers = {
    ids = join(",", [for replica in elestio_clickhouse.replicas : replica.id])
  }

  connection {
    type        = "ssh"
    host        = each.value.ipv4
    private_key = var.configuration_ssh_key.private_key
  }

  # Copy the new configuration
  provisioner "file" {
    source      = "${path.module}/src/docker-compose.yml"
    destination = "/opt/app/docker-compose.yml"
  }

  provisioner "file" {
    content = templatefile("${path.module}/src/config.xml.tftpl", {
      clickhouse_password       = var.clickhouse_password,
      cluster_name              = var.cluster_name,
      current_replica           = each.value,
      grouped_replicas_by_shard = { for replica in elestio_clickhouse.replicas : replica.local_field.shard_name => replica... },
    })
    destination = "/opt/app/config/config.xml"
  }

  provisioner "file" {
    content = templatefile("${path.module}/src/users.xml.tftpl", {
      clickhouse_password = var.clickhouse_password
    })
    destination = "/opt/app/config/users.xml"
  }

  # Start the new configuration
  provisioner "remote-exec" {
    inline = [
      "cd /opt/app",
      "docker-compose up -d",
    ]
  }
}
