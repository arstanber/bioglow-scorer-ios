# Game rules data

`game-rules.json` holds the BIOGLOW point values, the precision token table, mission element counts and the match length.
The app ships with a copy (`BIOGLOW/Secondary/Game/game-rules.json`) and downloads this file from the `main` branch
so scoring can follow Challenge Updates without an App Store release.

When a Challenge Update changes a value:

1. Edit `game-rules.json` here and **increase `revision`** (the app ignores files that aren't newer).
2. Set `source` (for example `"Challenge Update 02"`) and `published`.
3. `tokenPoints` must have 7 values (0…6 tokens left) that never decrease.
4. Run the tests — `GameRulesTests` checks that this file decodes, passes validation and matches the bundled copy.
5. Merge to `main`. Copy the file into the app bundle for the next release.

The app rejects files with an unknown `schema` or out-of-range values and keeps the rules it already has.
