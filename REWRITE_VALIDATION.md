# v3 rewrite validation

All 79 bundled authored feature modules and ten main runtime source sections were reviewed/reimplemented. `src/main.luau` remains the assembly manifest. The stable loader is a Lua fetch/compile entry. Vendor UI/icon code, license files, fixed arena coordinates and moderator identifiers are retained as dependencies/data; generated bundles are not counted as new implementations.

The latest upstream behavior is preserved: Atlantis encounters and timers, selected-arena admission, native Atheon portal receipts/pad slots, Between room/revive flow, hidden-but-interactive native block confirmation, direct Safe Mode rejoin/immediate fallback, fixed wave shelters, no forced map transparency, removed Farm Position setting, common boss convergence, Aeganatos Dodge and opt-in native self-damage protection.

## Verification

- Full offline regressions, generated-bundle consistency and UTF-8 checks pass.
- Optimized and `-O0` Luau compilation pass. The unoptimized check was added after Arceus X exposed its 200-register limit; UI initialization now has its own function scope.
- MCP decompilation verified the native combat event, skill compatibility/unlocks/stamina/cooldowns, credit tracker and Aeganatos phases.
- Detached native fixtures pass for visual boosters, remote-player visibility, player departure cleanup, VFX/hazard/physics preservation, and native protection ownership.
- Memory stress tests cover 20,000 queued objects, 30,000 enqueue/removal cycles, 1,000 incomplete enemies and 300 encounter churn cycles, plus failing observers/UI teardown and cyclic config snapshots.
- A live v3 teardown returned enemy index=0, visual queue=0, task registry empty, owned GUI roots=0, singleton cleared and CleanupErrors empty; the script reloaded afterward.

## Aeganatos result

VanguardSlasher's saved native health observation reached boss HP=0. The final observed delayed-windup segment recorded 44,909,576 to zero HP in 193 seconds, with zero player deaths and NoSelfDamage OFF. Auto Farm stayed enabled. The broader live test found and fixed shelter-to-farm oscillation, moving-cast conflicts, an undersized geyser margin and early-windup offensive downtime. Initial geyser damage can still occur; this does not prove immunity to all server hit checks. Safe Mode hopping remained enabled; Levi's MCP client was excluded.

## Size and timings

Compared with the current v2.0.25 entry, the generated standalone entry is 927,384 versus 970,432 bytes (4.44% smaller). A same-cap/rendering sample measured mean script loop work of 0.533 ms versus 0.571 ms. Screen frame time remained around 33 ms. Main UI construction was 0.80 s in the v3 sample versus 7.19 s in the older sample. These are observations from different live moments/server scenes, not controlled causal FPS benchmarks.

No unlimited-session RAM stability or universal executor compatibility claim is made. Lua-only describes runtime requirements: no Python, Node, MCP, or extra service is needed to execute the standalone entry.
