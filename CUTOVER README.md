# Cutover Risk Answer

The biggest risk during DNS cutover is sending real users to the new platform before the full request path has been proven end-to-end. DNS may look simple, but failures can appear in different places such as TLS certificates, CDN or Front Door routing, Container Apps ingress, CMS authentication, media asset access, database connectivity, or cached DNS records still pointing to the old platform.

I would reduce DNS TTL well before the cutover window, for example 24–48 hours earlier, so traffic can move faster and rollback is practical. Before switching production DNS, I would validate the new platform using a temporary hostname or hosts-file testing and confirm login, CMS APIs, media uploads, database reads/writes, health endpoints, logs, and alerts. I would also run a small smoke test from an external network, not only from my laptop or Azure.

For traffic switching, I would avoid changing everything at once where possible. I would first confirm the backend and CMS are healthy, then move a small controlled path or lower-risk hostname if supported, and only then update the main production DNS record. During the cutover, I would monitor HTTP 5xx errors, response latency, container restarts, database connections, and application logs in near real time.

My rollback trigger would be clear before starting: for example sustained 5xx errors, failed login or content publishing, broken media delivery, or database errors for more than a few minutes. Rollback would mean restoring the previous DNS target and keeping the old platform unchanged until the new issue is understood. I would not delete or modify the old production platform during the cutover window because DNS caching means some users may still reach it for a period of time.
