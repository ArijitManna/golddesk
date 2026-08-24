# GoldDesk APK output folder

Place the latest Android APK here for sideload updates (outside Play Store).

## Deployment steps

1. Build the Flutter release APK.
2. Copy it here as `golddesk.apk` (or any `.apk` name — the newest file is used if no custom URL is set).
3. Insert or update a row in the `AppVersions` table:

```sql
INSERT INTO "AppVersions" ("Id", "Version", "DownloadUrl", "ForceUpdate", "ReleaseNotes", "CreatedAt")
VALUES (
  gen_random_uuid(),
  '1.0.1',
  NULL,
  false,
  'Bug fixes and improvements',
  NOW()
);
```

- `Version`: latest app version users must have (matches `version` in `pubspec.yaml`, e.g. `1.0.1`).
- `ForceUpdate`: set `true` to block the app until users install the update.
- `DownloadUrl`: leave `NULL` to auto-serve `/output/golddesk.apk` from this folder.

On Docker production, mount this folder so APK updates do not require an API rebuild.
