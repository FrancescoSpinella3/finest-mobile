# Configurazione Supabase

## Database già esistente

Il database Supabase è già configurato e collegato all'app desktop.
L'app mobile usa **gli stessi identici nomi di colonna** dell'app desktop (camelCase).

### Schema tabelle esistenti

| Tabella | Colonne chiave |
|---------|---------------|
| `profiles` | `id`, `name`, `lastName`, `birthdate`, `gender`, `avatarUrl` |
| `categories` | `id`, `userId`, `name`, `type`, `icon` |
| `transactions` | `id`, `userId`, `type`, `description`, `amount`, `categoryId`, `date`, `autoRenewal` |
| `goals` | `id`, `userId`, `name`, `type`, `targetAmount`, `categoryId`, `period`, `manualAmount` |
| `subscriptions` | `id`, `userId`, `name`, `cost`, `categoryId`, `expiryDay`, `lastRenewal`, `lastAutoRenewal` |

---

## Avvio dell'app mobile

### Dove trovare URL e chiave Supabase

Nel progetto desktop, apri il file `.env` (o `.env.local`) — trovi:
```
VITE_SUPABASE_URL=https://tuoprogetto.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
```

### Esecuzione Flutter

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://tuoprogetto.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

### Build Android APK

```bash
flutter build apk \
  --dart-define=SUPABASE_URL=https://tuoprogetto.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

### Build iOS

```bash
flutter build ios \
  --dart-define=SUPABASE_URL=https://tuoprogetto.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

---

## Primo avvio

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

L'app mobile condivide lo stesso database dell'app desktop, quindi le transazioni,
categorie, obiettivi e abbonamenti creati su desktop saranno visibili anche su mobile.
