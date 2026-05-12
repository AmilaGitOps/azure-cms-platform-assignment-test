import axios, { AxiosError } from "axios";

/**
 * Task 3: Sanity CMS -> Directus migration script
 *
 * Usage:
 *   DIRECTUS_URL="https://your-directus.example.com" \
 *   DIRECTUS_TOKEN="example-token" \
 *   npm run migrate
 *
 * Notes:
 * - This script uses inline sample data because the assessment provides a small fixed source dataset.
 * - No credentials are hardcoded. Directus URL and token are read from environment variables.
 * - One failed record does not stop the migration.
 * - Basic retry logic is included for transient failures.
 */

type SanityPropertyListing = {
  _id: string;
  title: string;
  price: number;
  suburb: string;
  publishedAt: string;
  active: boolean;
};

type DirectusPropertyListing = {
  external_id: string;
  listing_title: string;
  asking_price: number;
  location: string;
  date_published: string;
  status: "published" | "draft";
};

type MigrationResult = {
  externalId: string;
  success: boolean;
  error?: string;
};

const sourceData: SanityPropertyListing[] = [
  {
    _id: "abc123",
    title: "Modern 2BR in Parramatta",
    price: 850000,
    suburb: "Parramatta",
    publishedAt: "2025-03-15",
    active: true,
  },
  {
    _id: "def456",
    title: "Luxury Penthouse Sydney CBD",
    price: 2400000,
    suburb: "Sydney",
    publishedAt: "2025-04-01",
    active: true,
  },
];

const DIRECTUS_URL = process.env.DIRECTUS_URL;
const DIRECTUS_TOKEN = process.env.DIRECTUS_TOKEN;
const DIRECTUS_COLLECTION = process.env.DIRECTUS_COLLECTION ?? "property_listings";

if (!DIRECTUS_URL) {
  throw new Error("Missing required environment variable: DIRECTUS_URL");
}

if (!DIRECTUS_TOKEN) {
  throw new Error("Missing required environment variable: DIRECTUS_TOKEN");
}

const directusClient = axios.create({
  baseURL: DIRECTUS_URL,
  timeout: 15_000,
  headers: {
    Authorization: `Bearer ${DIRECTUS_TOKEN}`,
    "Content-Type": "application/json",
  },
});

function transformRecord(source: SanityPropertyListing): DirectusPropertyListing {
  return {
    external_id: source._id,
    listing_title: source.title,
    asking_price: source.price,
    location: source.suburb,
    date_published: source.publishedAt,
    status: source.active ? "published" : "draft",
  };
}

function isRetryableError(error: unknown): boolean {
  if (!axios.isAxiosError(error)) {
    return false;
  }

  const status = error.response?.status;

  // Retry network errors, timeouts, rate limits and temporary server failures.
  return (
    !status ||
    status === 408 ||
    status === 429 ||
    (status >= 500 && status <= 599)
  );
}

function getErrorMessage(error: unknown): string {
  if (axios.isAxiosError(error)) {
    const axiosError = error as AxiosError;
    const status = axiosError.response?.status;
    const responseData = axiosError.response?.data;

    return JSON.stringify({
      status,
      message: axiosError.message,
      response: responseData,
    });
  }

  return error instanceof Error ? error.message : String(error);
}

async function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function postWithRetry(
  payload: DirectusPropertyListing,
  maxAttempts = 3
): Promise<void> {
  let lastError: unknown;

  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    try {
      await directusClient.post(`/items/${DIRECTUS_COLLECTION}`, payload);
      return;
    } catch (error) {
      lastError = error;

      if (!isRetryableError(error) || attempt === maxAttempts) {
        break;
      }

      const backoffMs = 500 * 2 ** (attempt - 1);
      console.warn(
        `Retrying ${payload.external_id}. Attempt ${attempt + 1}/${maxAttempts} in ${backoffMs}ms`
      );
      await sleep(backoffMs);
    }
  }

  throw lastError;
}

async function migrateRecord(
  source: SanityPropertyListing
): Promise<MigrationResult> {
  const payload = transformRecord(source);

  try {
    await postWithRetry(payload);
    console.log(`SUCCESS: migrated property ${payload.external_id}`);
    return {
      externalId: payload.external_id,
      success: true,
    };
  } catch (error) {
    const errorMessage = getErrorMessage(error);
    console.error(`FAILED: property ${payload.external_id}: ${errorMessage}`);

    return {
      externalId: payload.external_id,
      success: false,
      error: errorMessage,
    };
  }
}

async function main(): Promise<void> {
  console.log(`Starting migration of ${sourceData.length} property records`);

  const results: MigrationResult[] = [];

  for (const record of sourceData) {
    const result = await migrateRecord(record);
    results.push(result);
  }

  const successCount = results.filter((result) => result.success).length;
  const failureCount = results.length - successCount;

  console.log("Migration completed");
  console.log(`Successful records: ${successCount}`);
  console.log(`Failed records: ${failureCount}`);

  if (failureCount > 0) {
    console.log("Failed record summary:");
    results
      .filter((result) => !result.success)
      .forEach((result) => {
        console.log(`- ${result.externalId}: ${result.error}`);
      });
  }
}

main().catch((error) => {
  console.error(`Migration process failed unexpectedly: ${getErrorMessage(error)}`);
  process.exit(1);
});
