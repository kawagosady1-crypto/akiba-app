# Akiba – Savings Tracker (Android)

Akiba turns one big saving goal into a daily target. Every shilling saved above the target goes to an Extra pot, and missed days are spread over the remaining days instead of counting as failure.

## Features (version 2)

- **Goals** with a target, deadline, starting amount, photo and optional 24-hour withdrawal lock
- **Daily, weekly or monthly targets**, automatic or your own fixed amount
- **Time vs money pace** ("Day 12 of 90") and projected finish date
- **Log** savings, spending, withdrawals and income, up to 7 days back
- **Withdrawals** with reason, impact preview, "borrow from myself" pay-back plans and emergency override for locked goals
- **Extra pot** to the main goal or an emergency buffer; **shortfall recovery**
- **Income** with a "save first" suggestion (percentage set in Settings)
- **Spending limits** per category with warnings
- **Balances per location** (M-Pesa, bank, cash and your own)
- **Challenges** (52-week, no-spend days, 30-day streak) and **badges**
- **Monthly PDF report** to share
- **Daily reminder**, **PIN and fingerprint lock**
- Kiswahili and English, light and dark mode, backup and restore

## Get the APK on your phone

The project builds itself on GitHub for free.

1. Create a free account at github.com.
2. Create a new repository, e.g. `akiba`.
3. Upload all the files in this folder, keeping the folders (`lib`, `.github/workflows`).
4. Open the **Actions** tab. The "Build Android APK" job starts by itself and takes about 5–10 minutes.
5. When it shows a green tick, open **Releases** on the repository page and download **Akiba.apk** on your phone.
6. Open the file and allow "Install unknown apps" for your browser when Android asks.

To build again later, open **Actions → Build Android APK → Run workflow**.

## Build on a computer instead

With Flutter installed:

```
flutter create --org com.akiba --project-name akiba --platforms android .
flutter pub get
flutter build apk --release
```

The APK is at `build/app/outputs/flutter-apk/app-release.apk`.

## Project layout

| File | What it holds |
| --- | --- |
| `lib/main.dart` | App start, theme and lock |
| `lib/state.dart` | Data model, saving logic, daily target and extra calculations, storage |
| `lib/screens.dart` | Onboarding, Home, Goals, History |
| `lib/insights.dart` | Insights and Rewards |
| `lib/settings.dart` | Settings and lock screen |
| `lib/services.dart` | Reminders, fingerprint, photos, PDF report |
| `tool/patch_android.py` | Android permissions and settings used by the build |
| `assets/icon/` | App icon |
| `lib/sheets.dart` | Log saving/spending and goal forms |
| `lib/widgets.dart` | Shared cards and list items |
| `lib/i18n.dart` | Kiswahili and English text |
| `lib/format.dart` | Money and date formatting |

Every transaction has a `source` field (`manual` for now), so mobile money or SMS entries can be added later without changing the rest of the app.
