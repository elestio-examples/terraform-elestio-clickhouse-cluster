# ClickHouse Cluster Terraform Module Elestio

This module helps you deploy a ClickHouse Cluster on Elestio with that is configured, scalable and ready to use in minutes.

## ClickHouse

ClickHouse offers high-performance, scalable, and cost-effective analytics on large datasets with real-time capabilities and SQL compatibility: https://clickhouse.com/use-cases

## ClickHouse cluster

ClickHouse replication works at the level of an individual table, not the database level.
A server can store both replicated and non-replicated tables at the same time.
ClickHouse Keeper is the coordination system for data replication.

https://clickhouse.com/docs/en/architecture/replication

![Cluster architecture](https://raw.githubusercontent.com/elestio-examples/terraform-elestio-clickhouse-cluster/main/documentation/cluster_architecture.png)

## Module design

This terraform module deploys ClickHouse resources on Elestio.
Then it connects to the resources using SSH and changes the configuration files to enable replication.
It updates again the configuration when a replica is added or removed.

A minimum of 3 replicas and 1 shard is required for the cluster to work.

The Load balancer is recommended to distribute the queries between replicas.

![Terraform architecture](https://raw.githubusercontent.com/elestio-examples/terraform-elestio-clickhouse-cluster/main/documentation/terraform_architecture.png)

## Elestio features

At Elestio, we are developing a platform that helps you deploy services without spending weeks configuring them.
Services are fully managed with best practices in mind: security, monitoring, backups, updates, and more.
Check out the [Elestio website](https://elest.io) for more information.

You need to have an Elestio account to use this module.

- [Create an account](https://dash.elest.io/signup)
- [Request the free credits](https://docs.elest.io/books/billing/page/free-trial)
