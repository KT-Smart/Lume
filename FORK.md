# KT-Smart fork of Lume

This repository is a fork of [bilipp/Lume](https://github.com/bilipp/Lume).
Lume is AGPL-3.0: any build we distribute must have its source published under
the same license — this public fork covers that.

## Branches

| Branch | Purpose |
|---|---|
| `main` | Exact mirror of `bilipp/Lume` `main`. Never commit here. |
| `kt-custom` | Our customizations. Build and release from this branch. |
| `feature/*` | Short-lived work, branched off and merged back into `kt-custom`. |

## Pulling in upstream changes

```bash
git remote add upstream https://github.com/bilipp/Lume.git   # once

git checkout main
git fetch upstream
git merge --ff-only upstream/main
git push origin main

git checkout kt-custom
git merge main          # resolve conflicts, build, test
git push
```

Merge, don't rebase: `kt-custom` is shared, so its history is never rewritten.

## Signing & identifiers

All team and identifier settings live in [`Config/Lume.xcconfig`](Config/Lume.xcconfig):

| Setting | Used for |
|---|---|
| `DEVELOPMENT_TEAM` | Code signing for every target |
| `LUME_BUNDLE_ID_PREFIX` | Prefix for every bundle ID |
| `LUME_APP_BUNDLE_ID` | App bundle ID; extensions append `.LumeWidgets` / `.topshelf` |
| `LUME_APP_GROUP_ID` | App Group shared by the app and its extensions |
| `LUME_ICLOUD_CONTAINER_ID` | CloudKit container for iCloud sync |

For a personal override (e.g. your own team for device builds), create
`Config/Lume.local.xcconfig` — it is gitignored and included last.

Don't pick a team or edit the bundle ID in Xcode's **Signing & Capabilities** tab:
Xcode writes the value into `project.pbxproj` as a literal, which overrides the
xcconfig. Change the xcconfig instead.

## What differs from upstream

Keep this list current — it is what to check when an upstream merge conflicts.

- **Signing via xcconfig.** `Config/Lume.xcconfig` is the base configuration of
  every project-level build configuration. In `Lume.xcodeproj/project.pbxproj`
  every `DEVELOPMENT_TEAM` line is removed and every `PRODUCT_BUNDLE_IDENTIFIER`
  uses the variables above. If upstream adds a **new target**, it arrives with
  their team and bundle ID hardcoded — delete its `DEVELOPMENT_TEAM` lines and
  switch its bundle ID to `$(LUME_APP_BUNDLE_ID).<suffix>`.
- **`ExportOptions.plist`** carries our team ID (a plist can't read the xcconfig).
- **Entitlements** (`Lume/*.entitlements`, `LumeWidgets/`, `LumeTopShelf/`) use
  `$(LUME_APP_GROUP_ID)` and `$(LUME_ICLOUD_CONTAINER_ID)`.
- **Info.plists** (`Lume/`, `LumeWidgets/`, `LumeTopShelf/`) carry
  `LumeAppGroupIdentifier` (and the app's also `LumeCloudKitContainerIdentifier`),
  which `WidgetDataStore.appGroupID` and `LumeApp.cloudKitContainerIdentifier`
  read at runtime.
- **All Pro features unlocked.** `Config/Lume.xcconfig` adds the
  `ALL_FEATURES_UNLOCKED` compilation condition; `PremiumManager.isPremium`
  returns `true` under it and StoreKit is never started. Unlike upstream's
  `SIDE_LOAD` condition it leaves iCloud sync and everything else alone.
- **No "Lume Pro" in Settings.** `SettingsCategory.isAvailableOnPlatform` hides
  the `.premium` category under `ALL_FEATURES_UNLOCKED` (iOS, macOS and tvOS).

## iCloud sync

Sync works in every build signed with our team — Debug runs from Xcode,
TestFlight and App Store. It does **not** work in the Sideload configuration
(unsigned; `SIDE_LOAD` turns CloudKit off), so test builds go through Xcode or
TestFlight, never the sideload workflow.

- **Xcode builds** use the CloudKit **Development** environment. Running one
  with our team creates the container and its schema automatically.
- **TestFlight and App Store builds** use the **Production** environment. Before
  the first TestFlight build, and after every model change that touches the
  CloudKit store, deploy the schema in the CloudKit Console (container ▸
  Schema ▸ Deploy Schema Changes). Otherwise sync fails silently for testers.
