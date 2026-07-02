---
name: project-finest-mobile
description: Finest mobile Flutter app — a port of the finest-desktop Electron/React app for personal finance management, connected to Supabase
metadata:
  type: project
---

This is the Flutter mobile version of the "finest-desktop" app (GitHub: FrancescoSpinella3/finest-desktop).

**Why:** User asked to replicate the desktop app (Electron+React) in Flutter mobile, same features, same Supabase backend.

**Architecture:**
- State management: `provider` package
- Backend: Supabase (same DB as desktop)
- Charts: `fl_chart`
- Fonts: Montserrat + Poppins (must be downloaded from Google Fonts)

**Key files:**
- `lib/core/supabase/supabase_client.dart` — Supabase client config (uses --dart-define env vars)
- `lib/shared/providers/data_provider.dart` — All data models + Supabase CRUD
- `lib/features/auth/auth_provider.dart` — Auth state management
- `lib/app.dart` — App root + navigation shell (IndexedStack + BottomNavigationBar)
- `SUPABASE_SETUP.md` — Full SQL schema to run in Supabase + launch instructions

**How to apply:** Before running, user must: (1) download Montserrat+Poppins fonts into assets/fonts/, (2) run the SQL from SUPABASE_SETUP.md, (3) launch with `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

[[project-supabase-credentials]]
