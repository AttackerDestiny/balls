# Feather · Swordburst 2

Feather is the Swordburst 2 Luau script distributed through this repository's stable loader. It combines farming and combat automation, protected-server searching, arena rotation, progression, inventory utilities, trading, and a WindUI interface.

This guide describes **v1.12.50**. Saved settings can override fresh-install defaults.

## Contents

- [Run and update](#run-and-update)
- [Interface](#interface)
- [Main](#main)
- [Combat](#combat)
- [Challenge Floors](#challenge-floors)
- [Auto Skill](#auto-skill)
- [Misc and Player](#misc-and-player)
- [Utility](#utility)
- [Speacial](#speacial)
- [Settings](#settings)
- [Built-in background features](#built-in-background-features)
- [Default Multi Spot arenas](#default-multi-spot-arenas)
- [Feature interactions](#feature-interactions)
- [Multiple accounts and devices](#multiple-accounts-and-devices)
- [Local files and persistence](#local-files-and-persistence)
- [Performance and compatibility](#performance-and-compatibility)
- [Troubleshooting](#troubleshooting)
- [Development and verification](#development-and-verification)

## Run and update

Execute:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/AttackerDestiny/balls/main/loader.luau"))()
```

The loader fetches the current [kill-aura.luau](kill-aura.luau). Both paths remain stable between releases. You can also execute the complete standalone entry directly.

| Capability | Used for |
| --- | --- |
| Luau execution, `loadstring`, HTTP fetch | Public loader |
| Executor file access | Saved settings, custom spots, shared preferences, cached recovery |
| Teleport queue support | Running again after automated rejoining/floor travel |
| Native block-dialog/input access | Safe Mode and moderator block confirmation |
| Clipboard support | Config Export |
| Optional FPS/rendering APIs | Limit FPS and Disable rendering |
| Compatible native inventory/debug access | View player inventory |

Required `SB2Codex` folders/files are created automatically. No manual workspace setup is needed.

Use the header's **Restart script** icon or re-execute the loader to update. Update each account: existing runtimes do not continuously download new commits. Repeated execution of the same active build is deduplicated; a newer build replaces the older runtime.

## Interface

Tabs: **Main · Combat · Challenge Floors · Auto Skill · Misc · Player · Utility · Speacial · Settings**.

`Speacial` and `Perfromance Booster` retain their current UI spelling. The interface uses bundled **WindUI 1.6.66**, searchable dropdowns, and multi-select controls.

| Control | Behavior |
| --- | --- |
| Floating circular feather button | Shows/hides the main window; initially near the top center |
| Right Shift | Shows/hides the window when text input is not focused |
| Header restart icon | Saves preferences and re-executes the loader |
| Header eye icon | Saves whether to auto-hide the UI on execution |
| Header window controls | Minimize/resize/close; closing disposes owned automation and UI |
| Enemy health HUD | Theme-matched bars for attacked enemies; remains visible when the main window is hidden |
| Multi Spot HUD | Separate centered, draggable status panel while Multi Spot is enabled; independent of main-window visibility |

Main controls load first, with remaining tabs populated in background batches. If WindUI initialization fails, the older compatibility window appears and the error is recorded. This alternate layout is a fallback, not another script version.

## Main

### Teleport

- **Spot:** select a destination to immediately request travel. No separate Teleport button is needed. The same spot can be selected again after its request.
- **Refresh List:** refreshes destinations on the current floor.
- Normal destination travel arrives at the source position **minus 20 studs in Y**. Automatic arena travel checks streaming and actual arrival.

At startup, the floor runtime makes a one-time placement at the current character's X/Z and detected ground minus 20 studs, then lets the normal controllers take over. It waits a bounded time for a living character and uses a standing-height estimate if ground geometry is unavailable. The native login-place Play helper runs before floor-only behavior.

### Safe Mode

**Default OFF.** Searches for a protected server on **Safe floor**. Protected means only the local account and allowed players are present; a server with whitelisted players is acceptable.

- Detects unlisted arrivals and pauses ordinary farming/movement during protection.
- Uses native block confirmation before requesting another server.
- Same-floor rejoining uses the place ID without a teleport-pad detour. Native floor changes still use their required pad staging.
- After dispatching the rejoin, moves the waiting character 10,000 studs horizontally away at the same height. This changes the waiting position, not Roblox's loading time.
- If an outsider remains and the search has not rejoined after eight seconds, the fallback confirms blocking, prepares recovery, then kicks and attempts rejoining. It does not intentionally kick through this fallback without confirmed blocking.
- Uses bounded transient retries, **12-hop / 15-minute** search limits, and bounded same-server return recovery.
- Continues monitoring after reaching a protected server. Status exposes failed/unverified operations.

**Safe floor** supports the normal floor catalog, Atheon, and Atlantis, subject to native unlocks. Profile unlock changes refresh the available labels. During Account Progression, Safe Mode protects the current progression floor instead of travelling back to the manually selected floor.

**Whitelist** accepts usernames or user IDs separated by spaces, commas, or lines. Entries are normalized and deduplicated. Use usernames, not display names. **Auto Trade uses this same whitelist.**

The inline **X** clears only the editor. The old active/saved list remains until a new non-empty replacement is submitted. Native blocks can remain on the account afterward; the script does not automatically unblock every searched player.

### Multi Spot

**Default OFF. Auto Farm must be ON for automatic arena movement.**

| Control | Behavior |
| --- | --- |
| **Saved Spot** | Multi-selects arenas for the currently joined floor only |
| Selection order | First click = priority 1, second = priority 2, etc.; numbers appear in the dropdown |
| Deselect/reselect | Moves a selected spot to the end of its priority order |
| **Save Spot** | Adds a custom arena using current X/Z and detected surface height, up to 20 custom spots per floor |

Rotation uses the supplied **90s/45s respawn times** for the timed built-in arenas below:

1. Observe a living boss becoming dead and start its timer.
2. Finish remaining arena mobs, unless Boss Only excludes them.
3. Visit other ready/unvisited selected spots while that arena cools down.
4. Return to ready spots according to selected priority; show a countdown if all known timed arenas are cooling down.

Timers begin at the observed boss death, not at arrival or after clearing adds. Actual living spawns override predictions. An already-dead body or streaming disappearance does not fabricate a new kill. Timers belong to the current runtime/server; a rejoin does not import another server's spawn predictions. Untimed/custom spots receive periodic spawn checks instead of an invented timer.

The current living enemy is finished before changing target or spot, including when a higher-priority spot becomes ready. With Boss Only OFF, remaining arena mobs must also be cleared before normal rotation leaves. With Boss Only ON, ordinary adds are excluded. Outside-arena bosses can be selected after the current fight; rotation resumes afterward.

After five seconds without a target, empty arenas can return to their selected anchor. Travel failures automatically retry with increasing cooldowns capped at 60 seconds; success clears the backoff. Explicit protection/controller pauses are separate from travel-retry cooldowns.

### Friend Joiner

- **Friend username:** Roblox username to join.
- **Auto Join Friend:** uses the native friend-teleport route with paced attempts and stays when the entered user appears.
- **Status:** `Friend Appeared` if the user is in the server, otherwise `Friend Unappeared`. This label reports presence rather than the complete teleport-error history.

Offline users, full servers, locked floors, and native join permissions can prevent travel. Protection and Account Progression can pause it. When used with Safe Mode, the friend must also be allowed by the Safe Mode whitelist.

## Combat

| Feature | Behavior and fresh default |
| --- | --- |
| **Kill Aura** | Scripted normal damage against eligible nearby enemies. Damage-only: manual walking/jumping works without Auto Farm. OFF. |
| **Auto Farm** | Moves to eligible loaded enemies and manages farming noclip. Does not automatically enable Kill Aura. OFF. |
| **Boss Only** | Restricts Auto Farm and arena-clear checks to main bosses/mini-bosses, ignoring regular mobs. OFF. |
| **Credit Check** | Coordinates the user-specified 5% boss-credit target with a separate group. OFF. |
| **Credit Whitelist** | Independent usernames/user IDs for credit coordination |
| **Credit Status** | Shows missing accounts/counters, required damage, current plan, or finishing status |
| **Auto Equip Best Gear** | Equips the best owned usable weapon, armor, and accessories. ON. |
| **Atheon Dodge** | Bounded evasions based on supported native Atheon attack/hazard state, followed by returning to farm. OFF. |
| **Swing animation** | Normal-speed visible swings, independent of damage-request pacing. ON. |

### Target selection and movement

Next-target order is **main boss = 1, mini-boss = 2, regular = 3**, with common name/world-position ordering for ties. The current living target stays locked even if something higher priority spawns. Death, exhausted hit lives, despawning, or an explicit scope/settings change can release it. Temporary invulnerability or missing streamed health is not a confirmed kill.

Range is unlimited over enemies **actually loaded on the client**. The script cannot see arbitrary enemies Roblox has not streamed to that account. Bosses/minis outside a selected Multi Spot arena can be eligible after the current fight.

Farming uses common geometry and shared server-clock pacing, with separate account positions around each enemy. Slots follow the server's sorted user IDs, refreshed at most once per second. The position controller holds the slot, ignores movement under 0.75 studs, and retains it during boss jumps. Joining/leaving players can reassign slots. Update every farming account to use this behavior.

Normal target spacing stays inside the calculated attack sphere and preserves vertical body clearance; tight reach or very large groups can reduce separation. **Suspended Unborn is an exception:** slots surround the fixed **(-2439, 70, 5389)** arena anchor at the supplied +10 height, with a horizontal radius capped at 12 studs, instead of following its moving body. This fixed override does not infer attack range from the boss position.

Auto Farm OFF releases its movement, collision, and arena-float ownership. Independently active safety, trade, or native travel can still own movement.

### Best gear

Ranks weapons by effective damage across supported classes, armor by effective defense, and accessories by the planner's damage/defense/utility score. Upgrades, level scaling, and usable-level requirements are considered. It uses owned items only and excludes cosmetic accessory skins from ranking.

The weapon goes in the right slot and the left weapon slot is cleared: **no dual wielding**. Armor and up to two accessories are also considered outside Account Progression. The internal saved toggle key stays compatible with older Auto Equip Best Weapon settings.

### Credit Check

Applies only to **main bosses and mini-bosses**, targeting **5% of maximum HP**. This threshold was supplied for this feature; the script does not independently guarantee the game's reward rules.

1. Enter the participating usernames/user IDs in **Credit Whitelist** on every account.
2. Enable Credit Check and join the same Roblox server.
3. Checking activates only while **all configured accounts are present**. If anyone is missing, ordinary scripted damage continues without credit holds, damage planning, or acknowledgment pacing. Checking reactivates automatically when the full group returns.
4. Each account attacks until its replicated contribution reaches the requirement, then stops further scripted hits against that enemy while its group qualifies.
5. Once everyone qualifies, unrestricted scripted damage resumes.

The local account is always included; username/user-ID aliases are deduplicated. A solo/empty credit group needs no shared-credit hold. A present player without a visible contribution counter is unverified, not qualified. Safe Mode and Credit Check use **different whitelists**.

Roster calculations are reused between refreshes. An unchanged roster retains pending hit acknowledgments; membership changes clear them. Damage counters are checked on every attempt, and NaN/infinite values remain unverified. Severe latency above 500 ms or script loop cost above 6 ms reduces normal requests to one per frame and 12 per second, with a three-second recovery interval. This reduces outgoing bursts; it does not change the network's underlying latency.

The planner learns normal-hit and selected-skill damage per equipped weapon/enemy type. It chooses a low-excess combination and rechecks actual contribution after each hit. With 300k remaining, observed 250k skill damage, and 50k normal hits, it can plan one skill plus one normal hit. Unknown damage requires calibration; criticals, partial skill windows, changed equipment, and replication can alter estimates. Only enabled aura modes are used.

This gates local scripted hits. It cannot undo in-flight damage, split a single lethal hit, or stop other/manual attackers. More than 20 accounts cannot each receive 5% of one unhealed HP pool. It cannot guarantee every account gets drops or Vel.

## Challenge Floors

**Auto Dodge** reads supported native challenge-floor hazards and temporarily takes movement priority. Default ON, relevant only where supported hazards exist. It does not guarantee immunity, especially when low FPS delays observations.

**Transparent map** runs by default; its former toggle is removed. Characters, mobs, and identified hazards/effects are excluded from ordinary map treatment. Extended camera zoom is also applied while the runtime owns it.

## Auto Skill

- **Skill Aura + Skill:** selects an offensive skill compatible with the current weapon and uses its supported native activation route. Default OFF.
- **Misc Skill + Skill:** selects an available support skill. Default OFF.

Offensive skills respect weapon compatibility, stamina, cooldowns, skill windows, target registration, and protection/travel pauses. Normal and skill requests share per-target pacing. Overkill reservations reduce redundant hits while HP replicates; active Credit Check gates both paths.

| Support skill | Use condition |
| --- | --- |
| Cursed Enhancement | Actively attacking a living enemy and the buff is not already active |
| Heal / Mending Spirit | Health at or below 66% |
| Summon Tree | Stamina at or below the supported threshold of 66 |

Choices are filtered from usable native skills. Skill-effect suppression retains supported hit/animation timelines while reducing local visuals and aims to preserve health text and important hazard cues. Game/executor changes can affect support.

## Misc and Player

**Misc** provides **Dismantle**, **Upgrade**, and **The Forge** buttons to open the native menus. Opening a menu does not itself enable its automatic Utility feature.

**Player** provides:

| Control | Behavior |
| --- | --- |
| **Select player** | Selects an available player |
| **TP to player** | Requests movement to that player |
| **View player** | Uses the selected player as the viewing target |
| **View player inventory** | Uses that player's replicated profile through the guarded native inventory getter; open your normal Inventory menu to view it |

Inventory viewing does not transfer items or ownership. It requires compatible native/debug access and replicated profile data. Turning it off, losing the player, or cleanup restores the original reference when the runtime still owns the change.

## Utility

### Perfromance Booster

Multi-select from these eight saved options:

| Option | Effect |
| --- | --- |
| **No damage text** | Suppresses damage-number presentation |
| **No damage particles** | Suppresses supported hit particles, beams, and trails |
| **Delete dead mobs** | Suppresses/removes supported local dead-mob presentation |
| **No vel obtained in chat** | Hides Vel-obtained notifications |
| **Hide players** | Hides supported other-player visuals locally |
| **Hide effects** | Hides supported effects through the visual controller |
| **Disable rendering** | Disables 3D rendering when its API is supported |
| **Limit FPS** | Caps FPS at 15 when supported and restores the previous cap when released |

Options are explicitly selected. A lower FPS cap reduces resource use; it is not an FPS increase. Unsupported APIs report failure rather than being assumed available.

### Auto Dismantle

Multi-select **Common**, **Uncommon**, and/or **Rare**. Handles eligible existing inventory and new drops. Equipped, locked, favorited, and native-restricted items are preserved. Each rarity is opt-in; none is selected on a fresh configuration.

### Auto Craft

Select either or both:

- **Uncommon → Rare:** five Uncommon Upgrade Crystals make one Rare Upgrade Crystal.
- **Rare → Legendary:** five Rare Upgrade Crystals make one Legendary Upgrade Crystal.

With both selected, available rare crystals can become legendary while uncommon crystals replenish rare crystals. Recipes are checked against native data. One request is sent at a time and inventory acknowledgment is required. An unacknowledged craft pauses further spending rather than blindly duplicating it. Protection, travel, and trading can pause crafting.

### Auto Trade

**Default OFF.** Accepts incoming requests only from the **Safe Mode whitelist**, which also validates the partner during a trade. Credit Whitelist does not authorize trades.

| Control | Meaning |
| --- | --- |
| **Mode: Selected items** | Offers selected eligible inventory item names |
| **Mode: Legendary+** | Offers eligible Legendary, Tribute, and Burst items |
| **Inventory** | Selects item names from the local inventory, including displayed quantities |

Offers all eligible copies/stacks, paced to native acknowledgment and trade limits. There is no old script-imposed 128-item cutoff. **Upgrade Protection Scroll** and **Resurrection Crystal** are always included when eligible, even if not selected. Equipped, locked/favorited, and native-restricted items are excluded.

Vel is offered automatically at the maximum affordable amount after the sender's **10% tax**, capped at a 100,000,000 Vel offer. This is equivalent to `floor(balance / 1.10)`, subject to the cap. A 660,000 balance permits a 600,000 offer plus 60,000 tax. There is no manual Vel box.

**Final acceptance is automatic.** The intended offer must replicate and remain stable before native confirmation/acceptance stages. Unexpected outgoing quantities pause automation. There is no extra final-accept toggle.

Trading pauses conflicting farming, attacks, gear changes, and crafting/dismantling. Movement holds at current X/Z and detected ground minus 20 studs. Higher-priority protection can interrupt. Native restrictions/server acceptance determine success.

## Speacial

**Account Progression** automates normal floor progression toward F12:

- Finds the current floor's main boss and coordinates farming/combat.
- Checks a real credited boss defeat, then waits for native floor-unlock confirmation.
- Uses the native teleport pad/floor route.
- Selects owned usable gear through the equipment planner.
- Skips F6/Helmfirth: F5 travels to F7 when F7 is unlocked.
- Saves per-account checkpoints for resuming after a rejoin.
- Makes Safe Mode protect the current progression floor; Multi Spot yields.
- Restores saved farming preferences when progression is switched off.

Streaming loss, an unrelated miniboss, or an uncredited corpse is not a completed main-boss kill. The script cannot grant a floor unlock the server has not awarded. **F12 is the endpoint**; Atheon and Atlantis are not additional progression stages.

## Settings

| Control | Behavior |
| --- | --- |
| **Theme** | Selects a theme from bundled WindUI |
| **Config Export** | Copies portable JSON to the clipboard |
| **Config Import** | Paste an export and submit/leave the field to validate and reload with those settings |

Export includes every field from the autosave snapshot: feature toggles, **both whitelists**, floor/skill/item selections, Multi Spot order, layout/theme, relevant saved preferences/checkpoints, and **custom Save Spot entries from all available floor files**. Custom-spot transfer requires executor file access.

Import replaces preferences and can enable the toggles in the export. Text is parsed as validated JSON, not executed as Lua. Credentials, temporary rejoin tickets, live server observations, and damage-learning caches are not portable configuration. Feather uses its own settings system rather than WindUI's separate config manager.

## Built-in background features

| Feature | Behavior |
| --- | --- |
| **Anti-AFK** | One idle listener requests supported VirtualUser input with duplicate-event pacing; no continuous movement loop |
| **Completed quest claiming** | Reads native completion state and requests rewards for completed owned quest instances, with paced/bounded retries |
| **Moderator protection** | Matches the script's moderator list, confirms native blocking before disconnecting, and arms bounded recovery |
| **Rejoin recovery** | Queues installed source/loader where supported; build-specific caches avoid mixing different account builds |
| **Startup Play helper** | Handles native login-place Play before waiting for a combat profile |
| **Runtime ownership/cleanup** | Deduplicates execution and releases owned UI, connections, movement, and supported visual changes when closed/replaced |

Post-kick rejoining depends on executor support: some executors stop scripts or reject teleports after disconnection. This is not a ban bypass. Blocks, kicks, trades, crafting spends, and floor progression are not exercised as destructive unit tests.

## Default Multi Spot arenas

These are embedded **source positions**, before the normal Multi Spot **Y − 20** arrival adjustment.

| Floor | Spot | Source X, Y, Z | Respawn |
| --- | --- | --- | --- |
| F1 | Rahjin the Thief King | `-2939, -234, 1216` | 90s |
| F2 | Borik the BeeKeeper | `-2010, 443, -8956` | 90s |
| F3 | Ra'thae the Ice King | `-393, 4168, -369` | 90s |
| F4 | Irath The Lion | `-2319, 2073, 95` | 90s |
| F5 | Sa'jun the Centurian Chieftain | `2182, 1236, -717` | 90s |
| F7 | Smashroom the Mushroom Behemoth | `3329, 730, -475` | 90s |
| F8 | Formaug the Jungle Giant | `1550, 4081, 7720` | 90s |
| F8 | Hippogriff | `3772, 5743, -9686` | 45s |
| F9 | Mortis the Flaming Sear | `12392, 429, -3415` | 90s |
| F9 | Polyserpant | `1926, 2889, -11348` | 45s |
| F9 | Gargoyle Reaper | `-3613, 2905, -7708` | 45s |
| F10 | Grim the Overseer | `104, 931, 23842` | 90s |
| F10 | Baal, The Tormentor | `50, 261, 18107` | 45s |
| F11 | Duality Reaper | `6154, 846, -4251` | 45s |
| F11 | Za, the Eldest | `1753, 921, -6389` | 45s |
| F11 | DA, RA, KA | `5129, 1614, 2104` | 45s per member |
| F11 | Saurus, the All-Seeing | `5187, 2343, 6239` | 90s |
| F12 | Limor the Devourer | `450, -337, 7912` | 45s |
| F12 | Radioactive Experiment | `-3754, 167, 3570` | 90s |
| F12 | Suspended Unborn | `-2439, 60, 5389` | 90s |
| F12 | C-618 Uriotol, The Forgotten Hunter | `1685, 288, 3749` | 45s |
| F12 | Warlord | `1031, 108, 5474` | 45s |
| Atheon | Atheon arena | `840, 798, 336` | No supplied timer |
| Atlantis | Leviathan | `15.89453125, 1320.01953125, -797.10546875` | No supplied timer |

DA/RA/KA share one selected arena but track observed member death clocks; the arena can become due at the earliest member respawn. Suspended Unborn's separate **farming** exception is `-2439, 70, 5389`. Custom spots do not automatically receive a guessed respawn duration.

## Feature interactions

| Situation | Result |
| --- | --- |
| Auto Farm ON, both damage auras OFF | Farming movement without enabling either damage aura |
| Kill Aura ON, Auto Farm OFF | Damage automation with manual movement |
| Multi Spot ON, Auto Farm OFF | Selections stay saved; automatic arena movement waits |
| Higher-priority enemy/spot becomes ready | Current living enemy is finished before switching |
| Boss Only ON | Regular enemies/adds do not block farming/arena-clear checks |
| Account Progression ON | Progression owns floor travel; Multi Spot yields; Safe Mode follows the progression floor |
| Safe Mode handles an outsider | Protection interrupts ordinary farming/travel |
| Auto Trade active | Conflicting attacks, farming, gear and inventory automation yield |
| Credit Check ON, complete list present | Credit gate/planner applies to bosses/minis |
| Credit Check ON, someone missing | Credit checking becomes inactive and ordinary damage continues |
| Main window hidden | Automation, health HUD and enabled Multi Spot HUD continue |

Dodge, recovery, native skill state, character readiness and server corrections can also temporarily own movement. Conflicting features do not run simultaneously merely because every toggle is ON.

## Multiple accounts and devices

Three distinct mechanisms are involved:

1. **Shared files:** supported preferences are shared by accounts using the same executor workspace. Independent devices/isolated app storage do not share these files.
2. **Common farming decisions:** accounts in one server use shared server-clock pacing, common target order/position geometry, and selected spot priority. No relay/backend is required.
3. **Credit observation:** clients read replicated contribution counters for their configured group. This needs presence/readable counters; it is not a separate communication service.

Use the same build, **same Roblox server**, same spots/order, same relevant toggles, and same Credit Whitelist on every device. Export/import can copy settings between devices.

**Exact same-frame teleports and identical targets are not guaranteed.** Streaming, replication delay, FPS, readiness, corrections, and existing target locks can differ. An account finishing a fight does not abandon it to match another account. Counter visibility observed on one connected client does not establish successful coordination on every device/server.

## Local files and persistence

Paths are relative to the executor's workspace; do not add a second `workspace` directory manually.

| File/folder | Purpose |
| --- | --- |
| `SB2Codex/settings_<userid>.json` | Account-local snapshot/checkpoints |
| `SB2Codex/shared-settings.json` | Supported shared preferences within that exact workspace |
| `SB2Codex/custom-spots_<placeid>.json` | Custom Save Spot positions only, per floor |
| `SB2Codex/solo-search_<userid>.json` | Bounded Safe Mode resume state |
| `SB2Codex/kill-aura.luau` | Installed standalone source for recovery |
| `SB2Codex/source_<build>.luau` | Build-specific cached recovery source |
| `SB2Codex/WindUI/`, possibly `WindUI/` | UI library support folders |

Built-in teleport coordinates stay in source. Old `destinations_<placeid>.json` files are no longer created or loaded; existing ones are ignored and left untouched. Custom positions deliberately use their own files.

Most shared changes are loaded on execution. Safe floor also has a lightweight live shared-file check, while progression retains current-floor protection context. Separate devices must import/copy settings; local shared files are not cloud synchronization. Live observations, damage estimates and resume tickets are not portable synchronization data.

## Performance and compatibility

Current overhead reductions include:

- Shared mob tracking and timestamp-based damage pacing rather than per-hit delayed-task bursts.
- Frame/request budgets and no catch-up spam after low-FPS frames.
- UI/status work restricted to visible tabs and paced independently of combat.
- Startup UI/map work and streaming transparency spread across small batches.
- Reusable effect-maintenance buffers and per-update time/count budgets.
- Health changes coalesced into at most one redraw per 0.12 seconds per enemy row.
- Deduplicated equipment listeners, disconnected on removal/cleanup.
- Cached respawn-name matching and bounded runtime damage-estimate caches.

These reduce script work; they do not guarantee zero lag, a minimum FPS, or eight-account cloud-phone capacity. Native rendering/effects, executor behavior, server updates, and VM/device resources also matter. A 1–2 FPS drop or slowdown after 30 seconds is not by itself proof of a memory leak.

Potassium, Arceus X and other executors expose different capabilities. Compatibility paths exist, but optional APIs and every executor/device combination are not universally verified.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Old compatibility window appears | WindUI failed to initialize. Update/restart and inspect the recorded error; the alternate layout alone does not identify the cause. |
| Multi Spot starts but does not move | Auto Farm, current-floor selections, Safe Mode/progression/trade/dodge ownership, living character and travel state |
| Travel timed out | Automatic cooldown/retry state, valid destination and streamed collision; explicit pauses can have another cause |
| Credit Check does not wait | Boss/mini scope, complete whitelist presence, Credit Status and the separate Credit Whitelist |
| Credit Check waits despite presence | Username/user ID, replicated contribution, max HP and actual 5% progress; a missing counter is not credit |
| Boss dies before everyone qualifies | Other/manual attackers, single lethal hits and in-flight damage cannot be controlled by the local gate |
| Accounts have different settings | Whether executor storage is truly shared; export/import on separate devices and restart every account |
| Accounts target different mobs | Same server, loaded enemies, selection order, settings and existing fights; coordination is best-effort |
| Safe Mode cannot block/rejoin | Native input/dialog, readable block list, installed source, file access, teleport queue support, limits and teleport errors |
| Unexpected gear selection | Effective upgrades/scaling, level requirement, accessory utility score, cosmetic skin exclusion and native acknowledgment |
| Inventory view unavailable | Native inventory/debug compatibility and replicated target profile |
| Severe FPS drops | Explicit performance options and frame-time/memory measurements to separate script overhead from rendering/VM load; Limit FPS intentionally caps at 15 |

## Development and verification

| Path | Role |
| --- | --- |
| [loader.luau](loader.luau) | Stable public loader |
| [kill-aura.luau](kill-aura.luau) | Generated standalone entry; do not hand-edit |
| [kill-aura.body.luau](kill-aura.body.luau) | Runtime body and bundle integration |
| `*.module.luau` | Feature/controller implementations |
| `*.test.luau`, `*.test.lua` | Offline regressions and injected engine doubles |
| [build-script.py](build-script.py) | Bundles modules and the pinned UI library |
| [run-offline-tests.py](run-offline-tests.py) | Consistency, regression, encoding and compile checks |
| [vendor/](vendor/) | Pinned WindUI, provenance and upstream license |

Build and verify:

```powershell
python build-script.py
python run-offline-tests.py
```

Requires Python 3.10+, Lua 5.1+ on `PATH`, and the official Luau CLI tools. To specify the Luau directory:

```powershell
python run-offline-tests.py --luau-tool-dir C:/path/to/luau-tools
```

Coverage includes block confirmation/recovery, arena clearing/respawns/priorities, target locks, movement release, gear planning, trading/crafting gates, credit counters/planning, config transfer, mobile HUD ownership, and long-running queue/listener stress cases. Engine doubles do not replace live-device validation. Live checks have observed contribution counters, UI construction and selected native data paths; full multi-device combat, eight-account cloud-phone FPS/RAM stability and every executor remain unverified.

Never use real account blocks, kicks, trades, crafting spends or floor progression as unit tests. Respect the current live-test scope. Runtime changes require a build/version bump, regenerated entry, relevant checks and a normal commit/push. Do not publish executor workspaces, settings, logs, credentials or private session notes.

### UI attribution

WindUI comes from [Footagesus/WindUI](https://github.com/Footagesus/WindUI). Release **1.6.66** is bundled so queued recovery does not download a separate UI library. Its embedded banner differs from the release tag; provenance/checksum are in [vendor/README.md](vendor/README.md). See [vendor/WindUI-LICENSE.txt](vendor/WindUI-LICENSE.txt) for its MIT license. The library may still fetch normal visual assets.
