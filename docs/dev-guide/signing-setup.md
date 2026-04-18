---
title: "Signing Setup"
sidebar_position: 0
---

# Signing Setup

Each contributor signs the app with their own Apple Developer Team without editing `project.pbxproj` or clobbering anyone else's settings. Signing values come from a personal, gitignored xcconfig.

## How it works

```
Config/
├── Base.xcconfig            # committed — shared defaults
├── Local.example.xcconfig   # committed — template
└── Local.xcconfig           # gitignored — your personal overrides
```

- `Base.xcconfig` defines default bundle IDs and an empty `APP_DEVELOPMENT_TEAM`, then ends with `#include? "Local.xcconfig"`. The include is last so your local values override the defaults.
- `project.pbxproj` references `Base.xcconfig` as the base config for every target, and wires signing through variables: `DEVELOPMENT_TEAM = $(APP_DEVELOPMENT_TEAM)` and `PRODUCT_BUNDLE_IDENTIFIER = $(APP_BUNDLE_IDENTIFIER)`. Do **not** set signing values in Xcode's Signing & Capabilities UI — that edits `project.pbxproj` and creates merge conflicts.

## First-time setup

1. Copy the template:
   ```sh
   cp Config/Local.example.xcconfig Config/Local.xcconfig
   ```
2. Open `Config/Local.xcconfig` and set:
   - `APP_BUNDLE_IDENTIFIER`, `APP_TEST_BUNDLE_IDENTIFIER`, `APP_UI_TEST_BUNDLE_IDENTIFIER` — unique reverse-DNS IDs prefixed with something of yours (e.g. `alice.dungeonCrawler`). Keeping them unique per contributor avoids "a different app with the same bundle id is already installed" errors on shared devices.
   - `APP_DEVELOPMENT_TEAM` — your 10-character Apple Team ID (see below).
3. Build. No UI signing changes needed.

### Finding your Team ID

**Paid Apple Developer Program:** Xcode → Settings → Accounts → select your team; the Team ID is displayed next to the team name.

**Free Apple ID (personal team):** Xcode doesn't surface the Team ID in the Accounts UI. After signing in to Xcode and letting it create a signing certificate at least once (open the project, pick your personal team in the Signing & Capabilities dropdown — you can revert the pbxproj edits afterward), run:

```sh
security find-identity -v -p codesigning
```

Output looks like `Apple Development: you@example.com (XXXXXXXXXX)` — the parenthesized 10-character string is your Team ID.

If you picked a team in Xcode's Signing UI to generate the cert, revert the pbxproj changes before continuing:
```sh
git checkout -- dungeonCrawler.xcodeproj/project.pbxproj
```

## Verifying your setup

```sh
xcodebuild -project dungeonCrawler.xcodeproj \
  -target dungeonCrawler -showBuildSettings -configuration Debug \
  | grep -E "DEVELOPMENT_TEAM|PRODUCT_BUNDLE_IDENTIFIER"
```

You should see your Team ID and your bundle identifier, not `com.example.dungeonCrawler`.

## Free-tier install limit

Free Apple Developer accounts can install at most **3 apps** from the same team on one device. If you hit:

> This device has reached the maximum number of installed apps using a free developer profile

delete old app installs from the device (long-press the icon → Remove App → Delete App). The `…UITests.xctrunner` app is safe to delete — Xcode reinstalls it on the next UI test run.

## Rules of the road

- Never commit `Config/Local.xcconfig`. It's gitignored in the repo root; confirm with `git check-ignore -v Config/Local.xcconfig`.
- Never edit signing in Xcode's Signing & Capabilities editor after your initial Team ID capture. Change `Config/Local.xcconfig` instead.
- If you add a new signing-related build setting, define it in `Base.xcconfig` with a safe default and reference `$(YOUR_VAR)` from `project.pbxproj`, so teammates can override it locally.
