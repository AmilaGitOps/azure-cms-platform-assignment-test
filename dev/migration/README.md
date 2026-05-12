# Task 3 — Data Migration Script

This folder contains the deliverables for Task 3 of the technical assessment.

## Deliverables

- `/migration/migrate.ts`
- `package.json`
- `SCALABILITY_NOTES.md`

## Run locally

```bash
npm install

DIRECTUS_URL="https://your-directus.example.com" \
DIRECTUS_TOKEN="replace-with-token" \
npm run migrate
```

No real credentials are included in this repository. Directus connection details are supplied through environment variables.
