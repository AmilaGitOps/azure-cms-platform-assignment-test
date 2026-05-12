# Scalability Notes for Migration Script

## How I would extend this for 10,000+ records

For a larger migration, I would not keep all source records inline or load the full dataset into memory. The source fetch should use pagination or cursor-based reads from Sanity, for example 500 records per page, then process each page before requesting the next page.

I would process records in controlled batches instead of sending all API requests at once. For example, a batch size of 50 records with a concurrency limit of 5 to 10 requests would reduce pressure on the Directus API and database while still keeping the migration efficient.

Retry logic should be expanded with exponential backoff, jitter, and a retry limit for transient errors such as HTTP 429, 408, and 5xx responses. Permanent errors such as schema validation failures should not be retried repeatedly; they should be logged for manual review.

For reliability, I would write failed records to a separate error file or dead-letter table with the original source payload, transformed payload, error message, and timestamp. This allows only failed records to be reprocessed later instead of rerunning the full migration.

I would also make the migration idempotent by checking `external_id` before creating a record, or by using an upsert approach if supported by the API. This prevents duplicate property listings if the script is restarted.

For observability, I would add structured JSON logs, counters for success/failure/retry counts, and a final summary report. In production, the script could run as a Container App Job or GitHub Actions workflow with secrets supplied from Azure Key Vault or GitHub Secrets.

Before running against production, I would test with a dry-run mode, validate required fields, and run a small pilot batch first. After migration, I would compare source and target counts and sample records to confirm data quality.
