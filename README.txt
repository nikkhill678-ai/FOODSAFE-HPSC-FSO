FOODSAFE — HARYANA FSO LEARNING STUDIO
CLOUDFLARE SECURE AUTH + ADMIN-ONLY GEMINI RELEASE

IMPORTANT SECURITY TRUTH
No internet-facing application can be guaranteed “unhackable” or impossible to bypass. This release moves account authentication, AI entitlement checks, session validation and the 30-question quota to a Cloudflare Worker backed by D1. The Gemini key is a Worker Secret and is never included in GitHub, HTML, JavaScript or this ZIP. This is a substantial improvement over the previous browser-local login and Python/Render proxy, but it still requires correct deployment, secret handling, monitoring and updates.

WHAT CHANGED
- Public website remains static and can be hosted on GitHub Pages.
- Cloudflare Worker handles account registration, login, session checks, admin operations and Gemini requests.
- Cloudflare D1 stores salted password hashes, active/AI permissions, hashed session tokens, login-attempt counters and daily AI usage.
- Passwords are hashed server-side using PBKDF2-HMAC-SHA256 (100,000 iterations) with a unique 128-bit random salt. Plain passwords are never stored.
- Password minimum is 12 characters; maximum 128.
- Login responses are generic; repeated failed attempts are limited to 8 per 15-minute username/IP window.
- User session token is random, stored as a SHA-256 hash in D1 and held in sessionStorage in the browser; it expires after 12 hours. Logout deletes the server-side session.
- New self-registered accounts have ai_enabled=0. Only admin can grant Gemini access.
- Every /api/ask request verifies the live session and ai_enabled flag on the server. Hiding the navigation item is only a UI convenience, not the security boundary.
- D1 atomically enforces a maximum of 30 AI requests per username per UTC day, including failed upstream requests (so retries cannot evade the quota).
- AI source context is limited to five retrieved passages; full PDFs are not uploaded by this feature.
- Admin endpoints require a separate high-entropy ADMIN_PROVISIONING_SECRET stored as a Cloudflare Worker Secret.
- CORS allowlist, request-size limits, response no-store headers, no credential logging and generic server errors are applied.
- The old Python/Render backend and old local account authentication have been removed from this package to avoid two competing authentication paths.

PRESERVED
All Phase 1–10 site content and learning features from the previous package are retained: question banks, notes and PDFs, FSS Act Master Notes, search index, practice, revision, mock simulator, analytics, descriptive evaluator, study assistant, flashcards, adaptive planner, backup and PWA shell. Study progress continues to be stored locally per username in the current browser. It is not cloud-synchronised.

PART A — CREATE CLOUDFLARE ACCOUNT / D1 DATABASE
1. Visit https://dash.cloudflare.com/ and create/sign in to your Cloudflare account.
2. Open Workers & Pages. The Workers Free plan currently includes up to 100,000 requests/day and 10 ms CPU time per invocation. D1 Free includes 5 million rows read/day, 100,000 rows written/day, 5 GB total account storage and 500 MB per database. Limits can change; check the official pages linked at the end.
3. Create a D1 database named foodsafe-auth (Workers & Pages / Storage & databases / D1 SQL Database / Create).
4. Copy the database ID shown in the dashboard.
5. Open wrangler.toml in this folder. Replace REPLACE_WITH_YOUR_D1_DATABASE_ID with the real ID.
6. In wrangler.toml, replace YOUR-GITHUB-USERNAME with your GitHub username. The allowed origin is the origin only, e.g. https://myname.github.io — do not add /foodsafe or another repository path.
7. Install Node.js LTS from https://nodejs.org/ if it is not already installed.
8. Open Command Prompt/PowerShell in this fso-platform folder and run:
   npm install --global wrangler
   npx wrangler login
9. Create the D1 schema remotely:
   npx wrangler d1 migrations apply foodsafe-auth --remote
   Confirm that users, sessions, usage and login_attempts tables exist in the Cloudflare D1 dashboard.

PART B — ADD SECRETS (DO NOT COMMIT THESE)
10. Generate a long random admin secret locally. PowerShell example:
    $bytes = New-Object byte[] 32
    [Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
    $AdminSecret = [Convert]::ToBase64String($bytes)
    $AdminSecret
    Save it in a password manager. Do not put it in a source file, GitHub issue, README, chat, screenshot or ZIP.
11. Add the secret to Cloudflare:
    npx wrangler secret put ADMIN_PROVISIONING_SECRET
    Paste the generated secret when prompted.
12. Add your Gemini key:
    npx wrangler secret put GEMINI_API_KEY
    Paste the key when prompted. Never use a command-line argument containing the key because shell history can retain it.
13. Set/confirm GEMINI_MODEL in wrangler.toml. Default is gemini-2.5-flash; use a model enabled for your Google AI project.

PART C — DEPLOY THE API
14. From the same folder, run:
    npx wrangler deploy
15. Copy the deployed Worker URL, usually https://foodsafe-api.YOUR-SUBDOMAIN.workers.dev.
16. Test in a browser: open https://YOUR-WORKER-URL/health. It should return {"ok":true,...}.
17. In api-config.js replace the value with the exact Worker URL:
    window.FOODSAFE_API_BASE = 'https://foodsafe-api.YOUR-SUBDOMAIN.workers.dev';
    This URL is public, not a secret. Do not put any keys in api-config.js.

PART D — DEPLOY WEBSITE TO GITHUB PAGES
18. Create a GitHub repository. Set it to Public only if you intend all HTML, JS, PDFs, notes and question banks in the repository to be publicly downloadable. Otherwise use a private repository and verify GitHub Pages availability for your plan.
19. Upload/push the contents of this fso-platform folder to the repository root (not the enclosing parent folder).
20. In GitHub repository Settings / Pages, select GitHub Actions as the deployment source.
21. The included .github/workflows/pages.yml deploys the repository root. Push to main or manually run the workflow.
22. Wait for deployment. Open the GitHub Pages URL. Check that the website loads, login works, and /health is reachable at the Worker URL.
23. If the Worker rejects the website, confirm ALLOWED_ORIGINS in wrangler.toml matches the browser's exact Origin. For project Pages, origin is still https://USERNAME.github.io, without the project path.

PART E — ACCOUNT AND AI APPROVAL FLOW
24. A learner creates a normal FOODSAFE account using a username and password of at least 12 characters. This account has no Gemini permission by default.
25. To grant Gemini to an existing account, run the included admin-enable-ai.ps1 in PowerShell. Enter the Worker URL, ADMIN_PROVISIONING_SECRET and the learner's exact username. This does not reset their account password.
26. To remove only Gemini access, run admin-disable-ai.ps1.
27. To disable the whole account and invalidate sessions, run admin-revoke.ps1. To reactivate, run admin-activate.ps1. Use admin-list.ps1 to list account states and admin-reset-password.ps1 for password resets (which invalidate all sessions).
28. To create a brand-new AI-enabled account directly, run admin-provision.ps1. It creates the user with AI enabled and asks for a separate 12+ character password. If the username already exists, use admin-enable-ai instead; do not create a duplicate.
29. The user signs into FOODSAFE normally. The Gemini Tutor navigation appears only after /api/auth/me confirms ai_enabled=true. There is no separate AI password.
30. Every AI request is checked again by the Worker. Editing JavaScript, manually adding a navigation button, calling /api/ask directly or changing localStorage cannot grant AI access without a valid active server session and ai_enabled=1.

ADMIN ENDPOINTS (ADVANCED)
POST /admin/provision       Create a new AI-enabled account (x-foodsafe-admin-secret header)
POST /admin/ai-enable       Grant Gemini to an existing account
POST /admin/ai-revoke       Remove Gemini permission and invalidate sessions
POST /admin/revoke          Disable account and invalidate sessions
POST /admin/activate        Reactivate account (Gemini flag is unchanged)
POST /admin/reset-password Reset password and invalidate all sessions
GET  /admin/list           List accounts and AI entitlement status
All admin operations require ADMIN_PROVISIONING_SECRET. Keep this secret private and rotate it with `npx wrangler secret put ADMIN_PROVISIONING_SECRET` if exposed.

LOGIN / SECURITY CHANGES
- Replaced localStorage account/password-hash authentication with server-side authentication.
- New password minimum raised to 12 characters; passwords are salted and hashed server-side.
- Passwords and session tokens are not stored in localStorage. The short-lived bearer token is in sessionStorage, which is cleared when the browser tab/session ends. A same-origin script injection (XSS) could still steal a token while the session is active; keep dependencies and content safe and deploy only over HTTPS.
- Generic login errors reduce username enumeration.
- Login and registration attempts are rate-limited by username/IP.
- AI permission is checked on the server for every request; UI-only restrictions are not trusted.
- Request size and source excerpt counts are bounded.
- No user prompts, passwords, API keys or bearer tokens are written to application logs.
- Logout invalidates the server session.
- Legacy local account hashes from older versions are not used for authentication. Learners must create a new server account using the same username to continue using the existing locally stored progress. Their progress keys are preserved in the browser.

SECURITY LIMITATIONS — READ THIS
- No system can be promised “unhackable” or impossible to bypass. Cloudflare protects infrastructure; application security still depends on configuration, code review, account security and maintenance.
- Protect your Cloudflare account with a unique password and MFA/passkey. Use least-privilege Cloudflare API tokens; do not share the admin provisioning secret.
- Use a private GitHub repository if you do not want the notes PDFs, question banks or study material to be publicly visible. GitHub Pages from a public repository makes those assets public.
- Session tokens in sessionStorage are safer than long-lived localStorage tokens but remain accessible to JavaScript. A future custom-domain same-site HttpOnly Secure cookie architecture would improve token theft resistance; GitHub Pages + workers.dev are cross-site and browser cookie restrictions make that approach less reliable.
- CORS is not authentication. Attackers can call an API outside a browser; server-side session checks and admin secrets provide the real authorization.
- Cloudflare Workers Free has a 10 ms CPU limit per invocation. Password hashing uses WebCrypto PBKDF2 at 100,000 iterations; validate login under your deployed free-tier account. If Cloudflare reports CPU-limit errors, the safe options are to tune after measurement or move to Workers Paid; do not weaken password hashing blindly.
- A 30-question quota is a request-count limit, not a fixed rupee/dollar spending cap. A request can consume different token amounts. The Worker truncates question and source text, but set Google Cloud/API budget alerts and restrictions too. Gemini charges are separate from Cloudflare hosting.
- Free D1 limits can stop database operations after daily quotas/storage are exceeded. Monitor the Cloudflare dashboard and maintain backups. D1 Time Travel is not a substitute for an independent export.
- Study progress remains in browser localStorage and can be altered by the device owner. It is not a trusted exam score or cloud backup. Download backups regularly.
- Admin provisioning secret is effectively a master key. If compromised, an attacker could grant AI privileges. Rotate it immediately if exposed.
- Do not paste secrets into ChatGPT, GitHub, public issue trackers or screenshots. If a Gemini key has ever been committed, revoke it in Google AI Studio and generate a new one; deleting the commit alone is insufficient.

TEST CHECKLIST BEFORE SHARING PUBLICLY
[ ] /health responds successfully.
[ ] Register a standard account; /api/auth/me returns ai_enabled=false.
[ ] Standard account does not see Gemini Tutor.
[ ] Direct /api/ask with standard account returns 403.
[ ] Grant AI from admin-enable-ai.ps1; sign out and sign in again.
[ ] Approved account sees Gemini Tutor and can ask one question.
[ ] After 30 requests, next request returns 429 (do not burn tokens just to test this; use a test D1 user/usage row).
[ ] Revoke AI and verify direct /api/ask returns 403 after fresh login.
[ ] Revoke account and verify existing token returns 401.
[ ] Confirm the repository contains no .dev.vars, .env, D1 export, API key or admin secret.
[ ] Test on mobile and desktop; confirm question banks, PDFs, flashcards, analytics and backup work.

LOCAL FRONTEND PREVIEW
GitHub Pages is the intended frontend host. For local preview only, run:
  py -m http.server 8000
Then open http://127.0.0.1:8000. Add http://127.0.0.1:8000 to ALLOWED_ORIGINS temporarily in wrangler.toml and redeploy if you want to test API calls locally. Remove it before public production if not needed.

OFFICIAL DOCUMENTATION
Workers limits: https://developers.cloudflare.com/workers/platform/limits/
Workers pricing: https://developers.cloudflare.com/workers/platform/pricing/
D1 limits: https://developers.cloudflare.com/d1/platform/limits/
D1 pricing: https://developers.cloudflare.com/d1/platform/pricing/
Worker secrets: https://developers.cloudflare.com/workers/configuration/secrets/
Wrangler: https://developers.cloudflare.com/workers/wrangler/
D1 migrations: https://developers.cloudflare.com/d1/reference/migrations/
Google Gemini API keys: https://ai.google.dev/gemini-api/docs/api-key
