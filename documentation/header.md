# Terraform Module ClickHouse Cluster

A terraform module created by [Elestio](https://elest.io/fully-managed-services) that simplifies ClickHouse cluster deployment and scaling.

## ClickHouse

ClickHouse is an open-source database, fast and efficient for real-time apps and analytics: https://clickhouse.com/use-cases

## ClickHouse Cluster

In a ClickHouse cluster, the replication works at the level of an individual table, not the database level.
A server can store both replicated and non-replicated tables at the same time.
ClickHouse Keeper provides the coordination system for data replication.

We strongly recommend you to read the ClickHouse Replication documentation https://clickhouse.com/docs/en/architecture/replication

![Cluster architecture](https://raw.githubusercontent.com/elestio-examples/terraform-elestio-clickhouse-cluster/main/documentation/cluster_architecture.png)

## Elestio

Elestio is a Fully Managed DevOps platform that helps you deploy services without spending weeks configuring them (security, dns, smtp, ssl, monitoring/alerts, backups, updates). If you want to use this module, you will need an Elestio account.

- [Create an account](https://dash.elest.io/signup)
- [Request the free credits](https://docs.elest.io/books/billing/page/free-trial)

The list of all services you can deploy with Elestio is [here](https://elest.io/fully-managed-services). The list is growing, so if you don't see what you need, let us know.

## Terraform

![Terraform architecture](https://raw.githubusercontent.com/elestio-examples/terraform-elestio-clickhouse-cluster/main/documentation/terraform_architecture.png)

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
