# ITR Platform — Documentation Index

Central reference for the monorepo. Use this index when working on any app so you can quickly find architecture, API contracts, UI flows, and environment setup.

---

## Quick navigation

| I want to… | Read this |
|------------|-----------|
| Understand the whole system | [ARCHITECTURE.md](./ARCHITECTURE.md) |
| Know request/response shapes for any API | [API_CONTRACT.md](./API_CONTRACT.md) |
| Trace a user journey (mobile or admin) | [WORKFLOWS.md](./WORKFLOWS.md) |
| Build or update mobile UI from Figma | [FIGMA.md](./FIGMA.md) + [SCREEN_API_MAP.md](./SCREEN_API_MAP.md) |
| Start a safe mobile UI refactor | [projects/MOBILE_UI_REFACTOR_ANALYSIS.md](./projects/MOBILE_UI_REFACTOR_ANALYSIS.md) |
| Review the first mobile screen refactor step | [projects/MOBILE_STEP2_LOGIN_ANALYSIS.md](./projects/MOBILE_STEP2_LOGIN_ANALYSIS.md) |
| Set up local / staging / production | [ENVIRONMENTS.md](./ENVIRONMENTS.md) |
| Work on the Flutter app | [projects/MOBILE.md](./projects/MOBILE.md) |
| Work on the PHP API | [projects/API.md](./projects/API.md) |
| Work on the React admin panel | [projects/ADMIN.md](./projects/ADMIN.md) |
| Clone and run everything | [../README.md](../README.md) |

---

## Repository layout

```
itr-platform/
├── README.md                 # Setup guide (start here for first run)
├── docs/                     # ← You are here
│   ├── README.md             # This index
│   ├── ARCHITECTURE.md
│   ├── API_CONTRACT.md
│   ├── WORKFLOWS.md
│   ├── FIGMA.md
│   ├── ENVIRONMENTS.md
│   ├── SCREEN_API_MAP.md     # Screen → API mapping (mobile + admin)
│   └── projects/
│       ├── MOBILE.md
│       ├── MOBILE_UI_REFACTOR_ANALYSIS.md
│       ├── MOBILE_STEP2_LOGIN_ANALYSIS.md
│       ├── API.md
│       └── ADMIN.md
├── apps/
│   ├── mobile/tax_client/    # Flutter — FinApp
│   ├── api/                  # PHP REST API
│   └── admin/                # React admin panel
├── scripts/
└── .github/workflows/
```

---

## Documentation principles

1. **Shared docs live in `docs/`** — cross-cutting architecture, contracts, workflows.
2. **App-specific deep dives in `docs/projects/`** — routes, features, file paths, commands, refactor audits.
3. **Legacy detailed docs in `apps/*/`** — older curl guides, deployment notes; linked from project docs where relevant.
4. **When adding a new screen or API** — update `SCREEN_API_MAP.md` and `API_CONTRACT.md`.

---

## Apps at a glance

| App | Path | Stack | Primary users |
|-----|------|-------|---------------|
| Mobile | `apps/mobile/tax_client` | Flutter 3.8+, Riverpod | End users (ITR filing) |
| API | `apps/api` | PHP 7.4+, MySQL | All clients |
| Admin | `apps/admin` | React 19, Vite, MUI | Admins, CAs, accountants |

**Production API base:** `http://allindiaitr.in/api`

---

## Related files outside `docs/`

| File | Purpose |
|------|---------|
| `apps/mobile/tax_client/DEVELOPMENT.md` | Mobile architecture deep dive |
| `apps/api/API_DOCUMENTATION.md` | Full API reference with examples |
| `apps/api/LOCAL_SETUP.md` | Detailed API local setup |
| `apps/admin/API_SETUP.md` | Admin proxy & env config |
| `apps/api/ITR_API_Postman_Collection.json` | Postman collection for all APIs |
