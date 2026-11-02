# FOODSAFE security upgrade

Adds backend verification of AI excerpts against the published PDF search index, a 3-requests-per-minute per-user AI limit, and raises PBKDF2 iterations to 210,000 for newly created/reset passwords. Existing password hashes remain usable: migration records their existing 100,000 iteration count. New accounts and password resets use 210,000 iterations. Existing user/session/usage tables are preserved.

## Before deployment
- Back up the GitHub repository and D1 database.
- Confirm `https://nikkhill678-ai.github.io/FOODSAFE-HPSC-FSO/content/search/pdf-index.json` is publicly reachable.
- Keep `GEMINI_API_KEY` and `ADMIN_PROVISIONING_SECRET` only in Cloudflare Worker Secrets; never commit them.
- Review `wrangler.toml` and retain your actual D1 database ID and allowed origin.

## Deploy backend (PowerShell, from this project folder)
```powershell
npx.cmd wrangler d1 migrations apply foodsafe-auth --remote
npx.cmd wrangler deploy
```
The new migration is additive and creates only `ai_minute_usage`.

## Deploy frontend
Publish the contents of this folder to the existing GitHub repository, keeping paths unchanged. Do not create a second Worker or database.

## Verify
- Worker `/health` returns `ok:true`.
- A standard account can still use non-AI study features.
- An account without AI permission receives 403 from `/api/ask`.
- An AI-enabled account can ask about indexed notes.
- A fabricated or modified source passage is rejected with 400.
- More than 3 requests in one minute are throttled; daily limit remains 30.

## Scope
This verifies that excerpts match the public FOODSAFE search index. It does not make public notes private, guarantee correctness of the notes, or constitute a penetration test.
