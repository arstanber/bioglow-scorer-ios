# 🌿 iOS BIOGLOW™ Scorer

An unofficial robot game scorer for the 2026–2027 *FIRST*® LEGO® League Challenge BIOGLOW™ season, based on the Robot Game Rulebook.

One team per table, a 2:30 autonomous match: the app times the match, scores all 15 missions, equipment inspection and precision tokens, records Gracious Professionalism, and ranks teams by their best official score.

## Features

- **Score Match** — 2:30 timer with a 3-second countdown, start/end sounds and haptics; all 15 missions; undo and a match log stamped with the match clock.
- **Calculator** — the same scorer without a timer.
- **Timer** — a full-screen 2:30 clock.
- **History & Rankings** — saved matches with team number and round (Practice, Round 1–3), score details, and rankings.
- iPhone (portrait and landscape) and iPad; the mission list uses two columns on wide screens.

## Scoring implemented

| Item | Points |
|---|---|
| Equipment inspection (all equipment fits in one launch area, ≤ 305 mm) | 20 |
| Precision tokens left, 0…6 | 0 / 10 / 15 / 25 / 35 / 50 / 50 |
| M01 Drone Survey | drone off mat 20, +10 LiDAR map flipped |
| M02 Exploding Seeds | 10 per seed off the stalk (3) |
| M03 Flip the Rock | flag down 20, +10 rock returned |
| M04 Lucky Leaves | one leaf 10, +20 second leaf; no bonus if the katydid leaves the leaf habitat during the match, 0 if it is outside at the end |
| M05 Reaching Roots | partial 10 or complete 20 |
| M06 Leafcutter Frenzy | ant touching nest: 10 per fragment in the nest (4) |
| M07 Humongous Fungus | mycelium extended 20, +10 connected to the opposing team's root (needs an opposing team) |
| M08 Tangled | 30 |
| M09 Research Platform | 10 / 10 / 10 |
| M10 Fragile Microhabitats | 10 / 10 |
| M11 Window to the Past | 20 |
| M12 Forest Elder | 20 / 10 |
| M13 Keystone Species | 30 |
| M14 Seeds of Renewal | 5 per seed in the station, +5 if also touching the mat (3) |
| M15 Biocentric Architecture | 10 / 10 / 10, +10 for the dock's action (mine → canopy, city → skylight, farm → hatch) |
| Gracious Professionalism | 2 / 3 / 4, not part of the robot game score |

The maximum robot game score is 510. A bonus never scores without its base condition, and clearing a base clears its bonus. M01, M04, M05, M07 and M15 carry a "no equipment constraint" reminder.

M04 follows Challenge Update 01 (September 2nd, 2026). The element counts in parentheses come from the rulebook pictures and should be confirmed against the official scoring calculator. Point values, token table, counts and match length live in [`config/game-rules.json`](config/game-rules.json) so Challenge Updates can be applied without an App Store release.

## Rankings

Teams rank by their best score from Rounds 1–3, then their second-best, then their third. Practice matches and matches without a team number are ignored. If a round is saved twice for a team, the latest match counts and the ranking shows a warning.

## Development

Requires Xcode 26 or later. Copy `ExampleConfig.xcconfig` to the ignored `Config.xcconfig` and fill in `DEVELOPMENT_TEAM` and `PRODUCT_BUNDLE_IDENTIFIER`; both targets read them through `$(inherited)`, so no signing identity lives in the project file, and the identifier has to be registered as an App ID before an upload to App Store Connect. Copy `ExampleEnv.swift` to the ignored `Env.swift`; Aptabase may be left blank.

Data collection is declared in [`BIOGLOW/PrivacyInfo.xcprivacy`](BIOGLOW/PrivacyInfo.xcprivacy) and described in [`PRIVACY.md`](PRIVACY.md). Both need updating if the app starts collecting anything else.

Signing-free command-line build:

```sh
xcodebuild -project BIOGLOW.xcodeproj -scheme BIOGLOW -destination 'generic/platform=iOS' -derivedDataPath /tmp/bioglow-derived CODE_SIGNING_ALLOWED=NO build
```

Tests (Swift Testing) cover scoring, rules validation and rankings:

```sh
xcodebuild test -project BIOGLOW.xcodeproj -scheme BIOGLOW -destination 'platform=iOS Simulator,name=iPhone 16' -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

## Rules source

[BIOGLOW Game & Season](https://www.firstinspires.org/programs/fll/game-and-season) — Robot Game Rulebook and Challenge Updates. Challenge Updates override the rulebook.

## Legal

*FIRST*® LEGO® League and BIOGLOW™ are jointly held trademarks of *FIRST*® and the LEGO Group. This is an independent project, not affiliated with, sponsored or endorsed by either. No rulebook images are used.

Made by kita 39112 and contributors under the MIT License.
