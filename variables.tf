variable "project_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "clickhouse_version" {
  type        = string
  nullable    = true
  default     = null
  description = <<-EOF
    The clickhouse replicas will share the same version.
    You can find the list of available versions here: https://hub.docker.com/r/clickhouse/clickhouse-server/tags
    If you don't specify a version or set it to `null`, the Elestio recommended version will be used.
  EOF
}

variable "clickhouse_password" {
  type        = string
  sensitive   = true
  description = <<-EOF
    The password for the default user `root` of the clickhouse cluster.
    Rules: +10 characters, +1 digit, +1 uppercase, +1 lowercase.
    If you need a valid strong password, you can generate one accessing this Elestio URL: https://api.elest.io/api/auth/passwordgenerator
  EOF
}

variable "replicas" {
  type = list(
    object({
      shard_name                                        = string
      replica_name                                      = string
      provider_name                                     = string
      datacenter                                        = string
      server_type                                       = string
      admin_email                                       = optional(string)
      alerts_enabled                                    = optional(bool)
      app_auto_update_enabled                           = optional(bool)
      backups_enabled                                   = optional(bool)
      custom_domain_names                               = optional(set(string))
      firewall_enabled                                  = optional(bool)
      keep_backups_on_delete_enabled                    = optional(bool)
      remote_backups_enabled                            = optional(bool)
      support_level                                     = optional(string)
      system_auto_updates_security_patches_only_enabled = optional(bool)
      ssh_public_keys = optional(list(object({
        username = string
        key_data = string
        })
      ), [])
    })
  )
  default     = []
  description = "Replicas is a list of objects that define the clickhouse replicas of the cluster. Each object represents a replica. The minimum number of replicas is 3."

  validation {
    error_message = "You must provide at least 3 replicas."
    condition     = length(var.replicas) >= 3
  }

  validation {
    error_message = "Each replica must have a unique replica_name."
    condition     = length(var.replicas) == length(toset([for replica in var.replicas : replica.replica_name]))
  }
}

variable "configuration_ssh_key" {
  type = object({
    username    = string
    public_key  = string
    private_key = string
  })
  sensitive   = true
  description = <<-EOF
    After the replicas are created, Terraform must connect to apply some custom configuration.
    This configuration is done using SSH from your local machine.
    The Public Key will be added to the replicas and the Private Key will be used by your local machine to connect to the replicas.

    Read the guide [\"How generate a valid SSH Key for Elestio\"](https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/ssh_keys). Example:
    ```
    configuration_ssh_key = {
      username = "admin"
      public_key = chomp(file("\~/.ssh/id_rsa.pub"))
      private_key = file("\~/.ssh/id_rsa")
    }
    ```
  EOF
}
