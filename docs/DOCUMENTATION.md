# Remindini documentation

## What it is
An offline-first subscription tracker for Android and iOS. Users add subscriptions (price, cycle, next payment, category) and free trials, and get local reminders before money leaves their account.

## Decisions (and why)
| Decision | Reason |
|---|---|
| **No Firebase, no backend in 1.0** | You asked for Flutter + Firebase but offline first. Everything the idea needs works on the phone. No server means no accounts, no secrets, no keys to leak, nothing to hack, and a truthful privacy policy. Cloud backup/sync can be added later as its own milestone. |
| **No payments in 1.0** | Distribution is "friends group + GitHub". Apple and Google only allow in-app subscriptions through their own billing, which needs store accounts and listings. A paywall without that would be fake or bypassable, so none exists. The $1 / $2-per-3-months model needs the store route first (see below). |
| JSON file instead of a database | Few records, atomic writes, zero extra packages, easy backup. |
| Inexact alarms | Avoids the Android "exact alarm" permission; reminders fire at about the chosen time. |
| UTC carries the reminder instant | The reminder time is an absolute moment computed in local time, so no timezone database or extra plugin is needed. |
| Fonts: system fonts | No network, smallest size, and Arabic falls back to the system Arabic font. You can bundle Plus Jakarta Sans / Cairo later via `pubspec.yaml`. |
| Launch screen | Native splash is a plain background (same color as the first animated frame), then a 1-second logo reveal with a light sweep, then a Hero move of the logo into the first screen. |

### If you add payments later
Plan: Google Play Billing and Apple StoreKit through a managed layer (for example RevenueCat), store developer accounts (Google one-time fee, Apple yearly fee), store listing, data-safety forms. The app already isolates nothing about payments, so add an `Entitlement` service and gate only new premium features.

## Data model
Stored in `remindini_data.json` in the app documents folder.
- `settings`: theme, language, default currency, notifications on/off, reminder time, onboarding done, accepted legal version and time, id counter.
- `subscriptions[]`: id, nid (small number for notification ids), name (≤60), priceCents, currency (3 letters), cycle, anchor (first or next paid charge; for a trial, the day it ends), trial, category, remindDays (0–30), notes (≤300), status (active, paused, cancelled).

Money is stored as integer cents. Totals are per currency; no exchange rates are used.

## Personal data table
| Field | Why | Where | How to delete |
|---|---|---|---|
| Subscription names, prices, dates, notes | Show the list, send reminders | JSON file on the phone | Settings → Delete all my subscriptions, or uninstall |
| Settings | Appearance, reminder time | Same file | Uninstall |
| Accepted legal version and time | Ask again when texts change | Same file | Uninstall |

Nothing is sent anywhere. The release Android manifest has no INTERNET permission (Flutter adds it only for debug builds). Android auto-backup is switched off by the patch script.

## Permissions matrix
There is no server, so there are no server-side roles or rules to test. The user is the only role and owns all data on their device.
| Permission | Platform | Why |
|---|---|---|
| POST_NOTIFICATIONS | Android 13+ | Show reminders |
| RECEIVE_BOOT_COMPLETED | Android | Restore scheduled reminders after reboot |
| Notifications | iOS | Show reminders |

## Reminder logic
After every change and every app resume, all reminders are cancelled and planned again: for each active subscription, its next 2 charges; the closest 60 are kept (iOS allows 64). Free trials also get a reminder 1 day before the end. Paused and cancelled subscriptions get none.

## Design system
All tokens live in `lib/core/theme.dart`: spacing multiples of 4, radii 12/16/20/28, motion curve `cubic-bezier(0.16, 1, 0.3, 1)`, brand violet/teal/pink from your reference and logo, designed light and dark palettes, glass surfaces (blur only on the nav bar, sheets and cards that float), hairline borders, layered soft shadows, staggered entrances, press scale 0.98, haptics, reduced-motion support, touch targets of 48px or more, tabular numbers for prices. The logo was recolored from blue to the brand violet and is used for the app icon, splash, onboarding, empty state and About.

## Known limitations
- Not compiled or run by the author of this code. Expect to fix small analyzer issues on first run.
- No 3D illustrations like the reference; the depth comes from gradients, gloss and glass.
- No exchange rates: totals are shown per currency.
- Backup is manual (copy to clipboard). Manual exports are not automatic backups.
- Reminders can be delayed by battery savers on some phones.
- The signing for the APK is the debug key (fine for friends, not for stores).
