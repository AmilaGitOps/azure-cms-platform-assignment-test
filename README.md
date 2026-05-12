## azure-cms-platform-assignment-test further improvements.  (Task 5)

### If I had one additional day, I would focus on improving production readiness, security, observability and deployment reliability across the platform.

First, I would enhance the Terraform infrastructure by introducing reusable modules, environment separation (dev/staging/prod), remote state storage and state locking using Azure Storage Accounts. I would also add diagnostic settings and monitoring integrations for PostgreSQL, Container Apps and Key Vault.

For security improvements, I would integrate Managed Identities for Azure Container Apps instead of using connection strings directly where possible. I would also configure private networking, restrict public access to services such as PostgreSQL and Key Vault and introduce Azure WAF or Front Door for edge protection.

For CI/CD, I would extend the GitHub Actions workflow to include automated testing, linting, container vulnerability scanning and image signing before deployment. I would also add deployment approvals for production environments and blue/green or revision-based deployment strategies for safer releases.

On the application side, I would add proper health probes, structured logging and centralized monitoring using Application Insights and Log Analytics. This would improve troubleshooting and operational visibility during incidents.

For scalability and resilience, I would test horizontal scaling behaviour under load and validate database connection limits, retry handling and failover scenarios. I would also implement backup validation and disaster recovery considerations for PostgreSQL and storage services.

Finally, I would improve documentation by adding architecture diagrams, deployment steps, rollback procedures and operational runbooks to make the solution easier for future engineers to maintain and support.
