# Security checklist

Legend: Verified = checked by reading or searching the code here. Not verified = needs a real run on your machine. N/A = does not apply.

| Item | Status | Note |
|---|---|---|
| No secrets or keys in the repo | Verified (search) | The app needs none. Scan result is in the final report |
| `.gitignore` blocks keys, signing files, Firebase configs | Verified (read) | |
| Minimum personal data | Verified (read) | Only what the user types, on the device |
| No network access in release | Not verified | Flutter release manifest has no INTERNET permission by default; confirm in the built APK (`aapt dump permissions`) |
| Server-side permission rules and tests | N/A | No server |
| Input validation | Verified (read) | Form validators; strict JSON parsing with limits and clamping on load and import |
| Corrupt or hostile backup text | Verified (read), tests written | `importJson` limits size/count, rejects non-Remindini JSON; not executed |
| Injection / XSS / CSRF | N/A | No SQL, web views or server |
| Auth and sessions | N/A | No accounts |
| Secure token storage | N/A | No tokens |
| Account deletion and data export | Verified (read) | Settings: copy backup, restore, delete all subscriptions |
| Release shrinking and obfuscation | Not verified | Command is in SETUP.md (`--obfuscate`) |
| Android auto-backup disabled | Not verified | Done by the patch script; check the manifest after running it |
| No debug backdoors or test accounts | Verified (read) | |
| Dependencies audited and minimal | Verified (read) | 5 runtime packages. Versions are ranges; run `flutter pub outdated` |
| Unit tests pass | Not verified | Written, never executed |
| Legal drafts reviewed by a lawyer | Not verified | Drafts only |
