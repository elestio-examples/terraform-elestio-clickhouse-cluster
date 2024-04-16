<!-- BEGIN_TF_DOCS -->

# Terraform Module ClickHouse Cluster

A terraform module created by [Elestio](https://elest.io/fully-managed-services) that simplifies ClickHouse cluster deployment and scaling.

## ClickHouse

ClickHouse is an open-source database, fast and efficient for real-time apps and analytics: https://clickhouse.com/use-cases

## ClickHouse Cluster

In a ClickHouse cluster, the replication works at the level of an individual table, not the database level.
A server can store both replicated and non-replicated tables at the same time.
ClickHouse Keeper provides the coordination system for data replication.

We strongly recommend you to read the ClickHouse Replication documentation https://clickhouse.com/docs/en/architecture/replication

![Cluster architecture](documentation/cluster\_architecture.png)

## Elestio

Elestio is a Fully Managed DevOps platform that helps you deploy services without spending weeks configuring them (security, dns, smtp, ssl, monitoring/alerts, backups, updates). If you want to use this module, you will need an Elestio account.

- [Create an account](https://dash.elest.io/signup)
- [Request the free credits](https://docs.elest.io/books/billing/page/free-trial)

The list of all services you can deploy with Elestio is [here](https://elest.io/fully-managed-services). The list is growing, so if you don't see what you need, let us know.

## Terraform

This module :

- Deploys independent Elestio ClickHouse services
- Enables Replication by updating the configuration (`docker-compose.yml`, `config.xml`, `users.xml`)
- Updates automatically this configuration when you add or remove replicas

You can scale vertically (upgrading the server type) or horizontally (adding more replicas or shards) without losing data.

At least 3 replicas are required to ensure quorum and high availability.

Also, we recommend using the Elestio Load Balancer to distribute the traffic between the replicas.

## Important notes

When you create replicated table, please use the simplified version:

```sql
CREATE TABLE table_name (
    x UInt32
) ENGINE = ReplicatedMergeTree
```

instead of:

```sql
CREATE TABLE table_name (
    x UInt32
) ENGINE = ReplicatedMergeTree(
    '/clickhouse/tables/{shard}/{database}/table_name',
    '{replica}',
    ver
)
```

The module specifies the default path `/clickhouse/tables/{shard}/{database}/{table}`.

Be careful with table renames when using these built-in substitutions. The path in ClickHouse Keeper cannot be changed, and when the table is renamed, the macros will expand into a different path, the table will refer to a path that does not exist in ClickHouse Keeper, and will go into read-only mode.

## Usage

If you want to use this module by itself, you can use the following code:

```hcl
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
```

## Complete example

If you want to deploy everything at once (replicas, load balancer), you can follow this example.

We will do the following:
- Install terraform and copy a ready-to-use configuration
- Deploy the cluster with 3 replicas
- Output the cluster information
- Verify that it's working
- Add a fourth replica

### Install Terraform

First, let's install the Terraform client on your machine: https://learn.hashicorp.com/tutorials/terraform/install-cli

<details><summary>Instructions for MacOS:</summary>

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
terraform -v
```

</details>

### Copy the configuration

Create a new directory and the following files step by step:

```response
.
├── main.tf
├── load_balancer.tf (optional)
├── terraform.tfvars
├── terraform_rsa
├── terraform_rsa.pub
└── .gitignore
```

<details><summary>Create `main.tf` file with this content:</summary>

```hcl
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
  source = "../.."

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

```

</details>

<details><summary>If you want to add a load balancer, create `load_balancer.tf` file with this content:</summary>

```hcl
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
```

</details>

<details><summary>Create `terraform.tfvars` file with this content and fill it with your sensitive information:</summary>

```hcl
# Generate your Elestio API token: https://dash.elest.io/account/security
elestio_email     = ""
elestio_api_token = ""

# Generate a safe password: https://api.elest.io/api/auth/passwordgenerator
clickhouse_password = ""
```

</details>

<details><summary>Generate a dedicated SSH Key (required by the module to configure the replicas):</summary>

```bash
ssh-keygen -t rsa -f terraform_rsa
```
</details>

<details><summary>If you want to commit your code, create `.gitignore` file with this content:</summary>

```plaintext
# Your new SSH key
terraform_rsa.pub
terraform_rsa

# Local .terraform directories
**/.terraform/*
**/.terraform

# .tfstate files
*.tfstate
*.tfstate.*

# Crash log files
crash.log
crash.*.log

# Exclude all .tfvars files, which are likely to contain sensitive data, such as
# password, private keys, and other secrets. These should not be part of version
# control as they are data points which are potentially sensitive and subject
# to change depending on the environment.
*.tfvars
*.tfvars.json

# Ignore override files as they are usually used to override resources locally and so
# are not checked in
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Ignore CLI configuration files
.terraformrc
terraform.rc
```

</details>

Your configuration is ready.

### Deploy the cluster

Run the following commands:

```bash
terraform init
terraform apply
```

It will ask you to confirm the deployment. Type `yes` and press `Enter`.

The deployment will take a few minutes.

### Output the cluster information

You can show all the information about the created resources with the `terraform show` command.

```bash
terraform show
```

The output is large so you can use the custom outputs for essential information.

The access information to the replicas:

```bash
terraform output replicas_admins
```

```response
{
"clickhouse-01" = {
"password" = "******"
"url" = "https://clickhouse-01-u525.vm.elestio.app:28125/"
"user" = "root"
}
"clickhouse-02" = {
"password" = "******"
"url" = "https://clickhouse-02-u525.vm.elestio.app:28125/"
"user" = "root"
}
"clickhouse-03" = {
"password" = "******"
"url" = "https://clickhouse-03-u525.vm.elestio.app:28125/"
"user" = "root"
}
}
```

The cname of the replicas:

```bash
terraform output replicas_cnames
```

```response
{
"clickhouse-01" = "clickhouse-01-u525.vm.elestio.app"
"clickhouse-02" = "clickhouse-02-u525.vm.elestio.app"
"clickhouse-03" = "clickhouse-03-u525.vm.elestio.app"
}
```

The ports used by the replicas:

```bash
terraform output replicas_ports
```

```response
{
"18123" = "HTTPS port"
"24306" = "MySQL port"
"25432" = "PostgreSQL port"
"28123" = "HTTP port"
"29000" = "Native TCP port (used by `clickhouse-server` and `clickhouse-client`)"
"9009" = "Inter-server communication port for low-level data access. Used for data exchange, replication, and inter-server communication."
}
```

The cname of the load balancer:

```bash
terraform output load_balancer_cname
```

```response
clickhouse-lb-u525.vm.elestio.app
```

## Verify that it's working

### Verify that clickhouse keeper is running

Output the cname of the replicas:

```bash
terraform output replicas_cnames
```

Connect to each one using the SSH key you generated earlier:

```bash
ssh -i terraform_rsa root@clickhouse-01-u525.vm.elestio.app
```

And execute the `mntr` command to verify that the ClickHouse Keeper is running and to get state information about the relationship of the replicas.

```bash
echo mntr | nc localhost 9181
```

Response from a leader replica:

```response
zk_version      v24.1.3.31-stable-135b08cbd28a5832e9e70c3b7d09dd4134845ed3
zk_avg_latency  1
zk_max_latency  3
zk_min_latency  0
zk_packets_received     72
zk_packets_sent 72
zk_num_alive_connections        2
zk_outstanding_requests 0
zk_server_state leader
zk_znode_count  7
zk_watch_count  2
zk_ephemerals_count     0
zk_approximate_data_size        1213
zk_key_arena_size       0
zk_latest_snapshot_size 0
zk_open_file_descriptor_count   103
zk_max_file_descriptor_count    1048576
zk_followers    2
zk_synced_followers     2
```

Response from a follower node:

```response
zk_version      v24.1.3.31-stable-135b08cbd28a5832e9e70c3b7d09dd4134845ed3
zk_avg_latency  0
zk_max_latency  0
zk_min_latency  0
zk_packets_received     0
zk_packets_sent 0
zk_num_alive_connections        0
zk_outstanding_requests 0
zk_server_state follower
zk_znode_count  7
zk_watch_count  0
zk_ephemerals_count     0
zk_approximate_data_size        1213
zk_key_arena_size       0
zk_latest_snapshot_size 0
zk_open_file_descriptor_count   92
zk_max_file_descriptor_count    1048576
```

If any replica responds with an error, you can replace it by :

- Changing the `server_name` in `main.tf` and running `terraform apply`.
- Or removing the replica from the `replicas` attribute and running `terraform apply`. Then add it back and run `terraform apply` again.

### Verify ClickHouse cluster functionality

We'll create a database and a table on the cluster with the `ReplicatedMergeTree` table engine. Then we'll insert data from a replica and query it on another replica.

Let's install the ClickHouse client on your machine: [clickhouse-client](https://clickhouse.tech/docs/en/getting-started/install/)

<details><summary>Install on MacOS:</summary>

```bash
brew install --cask clickhouse
```

</details>

Output the cname of the replicas:

```bash
terraform output replicas_cnames
```

Open two terminals and connect to two different replicas using the ClickHouse client.

```bash
clickhouse client --host clickhouse-01-u525.vm.elestio.app --port 29000 --user root --password MyPassword1234
```

```bash
clickhouse client --host clickhouse-02-u525.vm.elestio.app --port 29000 --user root --password MyPassword1234
```

From `clickhouse-01`, create a database and a table:

```sql
CREATE DATABASE db1 ON CLUSTER MyCluster;
```

```sql
CREATE TABLE db1.table1 ON CLUSTER MyCluster
(
`id` UInt64,
`column1` String
)
ENGINE = ReplicatedMergeTree
ORDER BY id;
```

Still from `clickhouse-01`, insert data into the table:

```sql
INSERT INTO db1.table1 (id, column1) VALUES (1, 'abc');
```

From `clickhouse-02`, query the table:

```sql
SELECT * FROM db1.table1;
```

The output should be:

```response
┌─id─┬─column1─┐
│  1 │ abc     │
└────┴─────────┘
```

Now let's do the opposite. Insert data from `clickhouse-02`:

```sql
INSERT INTO db1.table1 (id, column1) VALUES (2, 'def');
```

And query the table from `clickhouse-01`:

```sql
SELECT * FROM db1.table1;
```

The output should be:

```response
┌─id─┬─column1─┐
│  1 │ abc     │
└────┴─────────┘
┌─id─┬─column1─┐
│  2 │ def     │
└────┴─────────┘
```

## Add new replicas

You can add new replicas to the cluster by adding them to the `replicas` attribute in the `main.tf` file and running `terraform apply`.

```hcl
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
```

The new replica will join the cluster but **will not have by default the data replicated**.
You can see that if you connect to the new replica and try to query the table:

```bash
clickhouse client --host clickhouse-04-u525.vm.elestio.app --port 29000 --user root --password MyPassword1234
```

```sql
SELECT * FROM db1.table1;
```

The output should be:

```response
Code: 81. DB::Exception: Received from clickhouse-04-u525.vm.elestio.app:29000.
DB::Exception: Database db1 does not exist. (UNKNOWN_DATABASE)
```

This behavior is expected with the [ReplicatedMergeTree](https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/replication) table engine.

We have to create the database and table on the new replica.
To help us, we can re-execute the same CREATE queries but adding the `IF NOT EXISTS` clause.
The replicas who already have the database and table will ignore the query, and the new replica will create the database and table.

Execute from any replica:

```sql
CREATE DATABASE IF NOT EXISTS db1 ON CLUSTER MyCluster;
```

```sql
CREATE TABLE IF NOT EXISTS db1.table1 ON CLUSTER MyCluster
(
`id` UInt64,
`column1` String
)
ENGINE = ReplicatedMergeTree
ORDER BY id;
```

Now try again to query the table from the new replica `clickhouse-04`:

```sql
SELECT * FROM db1.table1;
```

The output should be:

```response
┌─id─┬─column1─┐
│  1 │ abc     │
└────┴─────────┘
┌─id─┬─column1─┐
│  2 │ def     │
└────┴─────────┘
```

## Sharding

ClickHouse always has at least one shard for your data, so if you do not split the data across multiple servers, your data will be stored in one shard.
Sharding data across multiple servers can be used to divide the load.

You can for example split the data by region.
The next configuration create a cluster with 2 shards (europe and asia) and 2 replicas per shard:

```hcl
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
```

Europe replicas `clickhouse-01` and `clickhouse-02` will replicate the data between them, and Asia replicas `clickhouse-03` and `clickhouse-04` will replicate the data between them.

## Need help?

If you need any help, you can [open a support ticket](https://dash.elest.io/support/creation) or send an email to [support@elest.io](mailto:support@elest.io).
We are always happy to help you with any questions you may have.
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_clickhouse_password"></a> [clickhouse\_password](#input\_clickhouse\_password) | The password for the default user `root` of the clickhouse cluster.<br>Rules: +10 characters, +1 digit, +1 uppercase, +1 lowercase.<br>If you need a valid strong password, you can generate one accessing this Elestio URL: https://api.elest.io/api/auth/passwordgenerator | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | n/a | `string` | n/a | yes |
| <a name="input_configuration_ssh_key"></a> [configuration\_ssh\_key](#input\_configuration\_ssh\_key) | After the replicas are created, Terraform must connect to apply some custom configuration.<br>This configuration is done using SSH from your local machine.<br>The Public Key will be added to the replicas and the Private Key will be used by your local machine to connect to the replicas.<br><br>Read the guide [\"How generate a valid SSH Key for Elestio\"](https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/ssh_keys). Example:<pre>configuration_ssh_key = {<br>  username = "admin"<br>  public_key = chomp(file("\~/.ssh/id_rsa.pub"))<br>  private_key = file("\~/.ssh/id_rsa")<br>}</pre> | <pre>object({<br>    username    = string<br>    public_key  = string<br>    private_key = string<br>  })</pre> | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | n/a | `string` | n/a | yes |
| <a name="input_clickhouse_version"></a> [clickhouse\_version](#input\_clickhouse\_version) | The clickhouse replicas will share the same version.<br>You can find the list of available versions here: https://hub.docker.com/r/clickhouse/clickhouse-server/tags<br>If you don't specify a version or set it to `null`, the Elestio recommended version will be used. | `string` | `null` | no |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | Replicas is a list of objects that define the clickhouse replicas of the cluster. Each object represents a replica. The minimum number of replicas is 3. | <pre>list(<br>    object({<br>      shard_name                                        = string<br>      replica_name                                      = string<br>      provider_name                                     = string<br>      datacenter                                        = string<br>      server_type                                       = string<br>      admin_email                                       = optional(string)<br>      alerts_enabled                                    = optional(bool)<br>      app_auto_update_enabled                           = optional(bool)<br>      backups_enabled                                   = optional(bool)<br>      custom_domain_names                               = optional(set(string))<br>      firewall_enabled                                  = optional(bool)<br>      keep_backups_on_delete_enabled                    = optional(bool)<br>      remote_backups_enabled                            = optional(bool)<br>      support_level                                     = optional(string)<br>      system_auto_updates_security_patches_only_enabled = optional(bool)<br>      ssh_public_keys = optional(list(object({<br>        username = string<br>        key_data = string<br>        })<br>      ), [])<br>    })<br>  )</pre> | `[]` | no |
## Modules

No modules.
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_replicas"></a> [replicas](#output\_replicas) | All the terraform information about the replicas in your cluster. |
| <a name="output_replicas_ports"></a> [replicas\_ports](#output\_replicas\_ports) | The list of ports used by the replica for ClickHouse. They are open by default in your Elestio firewall settings. |
## Providers

| Name | Version |
|------|---------|
| <a name="provider_elestio"></a> [elestio](#provider\_elestio) | >= 0.16.0 |
| <a name="provider_null"></a> [null](#provider\_null) | = 3.2.0 |
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_elestio"></a> [elestio](#requirement\_elestio) | >= 0.16.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | = 3.2.0 |
## Resources

| Name | Type |
|------|------|
| [elestio_clickhouse.replicas](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/clickhouse) | resource |
| [null_resource.configure_replicas](https://registry.terraform.io/providers/hashicorp/null/3.2.0/docs/resources/resource) | resource |

<!-- END_TF_DOCS -->
