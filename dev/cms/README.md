# Local to Production: What Changes for Azure Container Apps?

For local development, `docker-compose.yml` uses simple environment variables, local named volumes, and local service discovery between Directus, PostgreSQL, and Redis.

In production on Azure Container Apps, I would not store secrets in `.env` files or directly in the compose file. Database passwords, Directus `KEY`, Directus `SECRET`, admin credentials, and Redis connection strings should be stored in Azure Key Vault and referenced by Container Apps secrets.

The Directus container should be treated as stateless. Local named volumes are useful for development, but they are not reliable for production scaling because Container Apps replicas can start on different underlying nodes.

Uploaded media should move from the local `/uploads` volume to Azure Blob Storage, using the `media-assets` container created in Task 1. This allows multiple Directus replicas to read and write media consistently.

The database should move from the local PostgreSQL container to Azure Database for PostgreSQL Flexible Server. This provides managed backups, patching, monitoring, high availability options, and easier operational support.

Redis should also be a managed service in production, such as Azure Cache for Redis, instead of a local Redis container. This avoids losing cache state when containers restart.

Container Apps should use health checks for Directus, for example a readiness/liveness probe against the Directus health endpoint. This prevents unhealthy revisions from receiving traffic.

For scaling, I would configure Container Apps with minimum replicas for availability and maximum replicas for traffic spikes. Scaling can be based on HTTP concurrency or request volume.

Production images should be built once in CI/CD, pushed to Azure Container Registry, and deployed by immutable image tag rather than using `latest`.

Networking should be restricted where possible. PostgreSQL, Redis, and Key Vault should not be publicly exposed unless required, and access should be controlled with managed identity and private networking where available.

Application logs and metrics should be sent to Log Analytics or Azure Monitor so failures, slow requests, and container restarts are visible.

For production readiness, I would also add backup verification, alerting, custom domain/TLS, revision-based rollback, and clear deployment approval steps before routing traffic to a new revision.
