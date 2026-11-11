# Feather · Swordburst 2

Feather is the Swordburst 2 Luau script distributed through this repository's stable loader. It combines farming and combat automation, protected-server searching, arena rotation, progression, inventory utilities, trading, and a WindUI interface.

This guide describes **v3.0.41**. Saved settings can override fresh-install defaults.

Version 3 reimplements the authored feature modules and main runtime adapters. Combat, credit, target detection, movement, dodges, safety/rejoining, progression, inventory/trade/crafting, Between/Atheon utilities, persistence, visual cleanup and modern UI all use the rewritten implementations. Public loader paths and version-1 settings remain compatible. Licensed WindUI/icon dependencies and fixed arena/moderator datasets remain dependencies/data rather than being counted as rewritten features.

For Junkie packaging, the generated `kill-aura.luau` omits WindUI's unused deprecated Junkie key-provider adapter. Feather does not enable WindUI's key system. The vendor release and licenses remain intact; the build applies this compatibility change. When using Junkie's protected loader, place the script in **Original Code** and any separate key interface in **UI Source**, following the [official Inline UI guide](https://docs.jnkie.com/roblox-sdk/inline-ui). The UI hands the entered key to the protected loader through `getgenv().SCRIPT_KEY`; protected loader authentication remains responsible for access.

The distributed entry is one standalone Luau file (Roblox's Lua). It uses the executor's Roblox/Lua capabilities only; Python, Node and MCP are development tools, not runtime dependencies.

## Contents

- [Run and update](#run-and-update)
- [Interface](#interface)
- [Main](#main)
- [Combat](#combat)
- [Waves Defense](#waves-defense)
- [Auto Skill](#auto-skill)
- [Misc and Player](#misc-and-player)
- [Utility](#utility)
- [Speacial](#speacial)
- [Dodge](#dodge)
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

Tabs: **Main · Combat · Waves Defense · Auto Skill · Misc · Player · Utility · Speacial · Dodge · Settings**.

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

Main controls load first, with remaining tabs populated in background batches. The legacy panel, navigation, drag listeners and fallback display path are removed. Controller status adapters use plain tables and allocate no hidden GUI instances or input connections. WindUI uses bundled Lucide icon data instead of downloading its icon loader and six packs during startup, and construction uses one yield budget. If initialization fails, the error is recorded and the feather button reloads the modern script. UI initialization failure does not intentionally stop farming or Safe Mode.

Diagnostics record `WindUIMainReadySeconds` and `WindUIReadySeconds` for Main controls and the remaining tabs. These measure UI construction after its library initialization begins; native game loading and the public loader's download are separate.

Runtime replacement tolerates errors from an older build's cleanup, records the error, and retires its GUI before continuing. Enemy-health cleanup handles partially constructed rows so an interrupted HUD build cannot stop the replacement from starting farming and Safe Mode.

Show/hide preserves the window's size and skips the full-window resize animation. Visible dropdown refreshes process one control per update instead of rebuilding an entire tab on the opening frame. Reopening an unchanged tab does not force a new refresh.

Runtime recovery cancels a main update that remains suspended for eight seconds before allowing another update to run. If cancellation fails, it waits and retries rather than starting duplicate workers. Script-owned skill casts have a bounded recovery deadline, and arena trips expire after 20 seconds so existing travel retries/farming can resume. Recovery respects master pause, safety, trade, and native floor-transfer ownership. Ordinary spawn and credit waits remain intentional. Diagnostics expose frame completion times and separate coordinator, skill, and travel recovery counters.

## Main

### Teleport

- **Spot:** select a destination to immediately request travel. No separate Teleport button is needed. The same spot can be selected again after its request.
- **Refresh List:** refreshes destinations on the current floor.
- Normal destination travel arrives at the source position **minus 20 studs in Y**. Automatic arena travel checks streaming and actual arrival.

At startup, the floor runtime holds the character at the current X/Z and detected ground minus 20 studs until a movement controller takes over. Walking or jumping manually releases the startup hold and returns the character above ground. It waits a bounded time for a living character and uses a standing-height estimate if ground geometry is unavailable. The native login-place Play helper runs before floor-only behavior.

### Safe Mode

**Default OFF.** Searches for a protected server on **Safe floor**. Protected means only the local account and allowed players are present; a server with whitelisted players is acceptable.

- Detects unlisted arrivals and pauses ordinary farming/movement during protection.
- Uses native block confirmation before requesting another server.
- Same-floor rejoining uses the place ID without a teleport-pad detour. Native floor changes still use their required pad staging.
- Startup still places the character 20 studs below ground once. Same-floor searches and outsider arrivals then block and dispatch rejoin from the current position, without pad staging or the old 10,000-stud escape.
- After a confirmed-block rejoin request, the fallback checks on the next scheduler turn. If Roblox has not reported teleport starting, it re-verifies blocking and queued recovery before kicking the local account and retrying rejoin. The old eight-second wait is removed. Native teleport-start events cancel the fallback; retries remain bounded and use elapsed time rather than frame counts.
- Keeps retrying temporary block and rejoin failures while Safe Mode is enabled. The **12-hop / 15-minute** windows renew automatically, with a short delay after repeated same-server returns.
- Continues monitoring after reaching a protected server. Status exposes failed/unverified operations.

**Safe floor** supports the normal floor catalog, Atheon, Atlantis, and The Between. Profile unlock changes refresh the normal floor labels. During Account Progression, Safe Mode protects the current progression floor.

Selecting **The Between** from elsewhere waits for you to enter through a room. Inside The Between, Safe Mode protects the current server. When an unlisted player is present, it confirms the block, kicks the local account, and then requests a rejoin to The Between without a teleport-pad detour.

Native block confirmations run with the recognized target's modal visuals transparent while its controls remain active. The script still requires Roblox's blocked-user acknowledgment before rejoining or moderator disconnects. Visual properties/listeners are restored after each attempt or shutdown. Unrelated or unrecognized dialogs remain visible and are never clicked.

On Delta Android, the adapter accepts the native vertical and horizontal block-button orders, checks visibility through the entire modal hierarchy, and waits for partially mounted buttons. A recognized different-target dialog causes a bounded wait and Safe Mode retries after it closes; genuinely unsupported layouts stay paused. Native Roblox UI code and isolated real-instance fixtures were checked on VanguardSlasher. No real blocks or kicks were performed to test this change; an end-to-end block/rejoin on the new version remains unverified.

If an interrupted attempt leaves a recognized block dialog for an eligible outsider, Safe Mode resumes that target before selecting a different pending outsider. A whitelisted, departed or otherwise ineligible user is never selected through this recovery path.

Title-based recognition requires an unambiguous match across all current players, including whitelisted users. If multiple users share the display name in the prompt, automation stops without clicking or cancelling it; the dialog cannot prove which user ID it belongs to. An exact unique username in the title remains usable. This avoids waiting for a blocked-user receipt on the wrong account.

Block input first verifies the raw button center in CoreGui, then adds the GuiService inset. On Delta Android, virtual input can also have an extra window offset: the inspected client placed input 24 pixels above the requested point. Mouse confirmation now measures that offset using pointer movement, verifies the correction and rechecks the button before pressing. Touch remains an independent fallback. A different active control, including Block and Report, is never accepted as the intended button; missing or obstructed hit targets stop activation. Harmless shielded buttons inside the native FoundationOverlay reproduced the offset and received the corrected input without reaching gameplay or native Block controls.

The latest Block attempt records its method, injected coordinates, measured offset and per-method exceptions separately from the authoritative block acknowledgment. Cleanup Cancel input has a separate record and cannot overwrite that evidence. Four bounded confirmation attempts are spread across the acknowledgment window so a late native handler can recover. All failed methods produce an explicit error, and partially failed presses still send a release. A visible but covered button is reported separately from a dialog that never appeared. The latest Safe Mode search failure is retained in `SB2Codex/safe-failure_<userid>.json`, with its build, server, target, phase and bounded input-error details, so a later protected server cannot erase the evidence. It remains local to the account and is not included in config exports. Storage failure does not authorize rejoining without block confirmation.

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

While Multi Spot is ON, Auto Farm targets encounters selected in Saved Spot, plus normal adds inside those selected arenas. Unselected bosses cannot interrupt, even if they have higher priority; deselecting an encounter releases its old target lock. Empty current-floor selections do not fall back to global farming. Loaded chests are the loot exception described below. Custom saved spots accept nearby enemies. Account Progression retains its own boss restriction.

Ordinary mobs observed in the current selected arena remain eligible if they chase beyond its initial 220-stud radius. Their membership is tied to that encounter and ends when it is deselected or replaced. The remaining-mob counter uses the same named-encounter policy, so nearby unselected bosses cannot keep it artificially above zero. Loading, invulnerability and temporary retry waits are shown in the counter; missing data does not prove a kill. Spawn-side movement waits identify the character, protection, combat or travel condition being awaited.

Within the selected encounters, higher-priority loaded enemies can interrupt lower-priority fights: main boss → mini-boss → regular mob. Same-rank fights remain locked. An active complete Credit Check group converges on a common eligible boss order, overriding conflicting locks to avoid split-group credit deadlocks. With Boss Only OFF, remaining arena mobs must still be cleared before normal arena rotation leaves; selected boss priority can temporarily interrupt that clearing. With Boss Only ON, ordinary adds are excluded.

After five seconds without a target, empty arenas can return to their selected anchor. Travel failures automatically retry with increasing cooldowns capped at 60 seconds; success clears the backoff. Explicit protection/controller pauses are separate from travel-retry cooldowns.

### Friend Joiner

- **Friend username:** Roblox username to join.
- **Auto Join Friend:** uses the native friend-teleport route with paced attempts and stays when the entered user appears. Accounts use deterministic positions across the pad's local surface instead of stacking at its center, with character-footprint margins and spacing. Separate positions are limited by the pad's available area.
- **Status:** `Friend Appeared` if the user is in the server, otherwise `Friend Unappeared`. This label reports presence rather than the complete teleport-error history.

Offline users, full servers, locked floors, and native join permissions can prevent travel. Protection and Account Progression can pause it. When used with Safe Mode, the friend must also be allowed by the Safe Mode whitelist.

After **two failed join attempts**, Auto Join Friend waits **10 minutes** before starting another attempt cycle. Offline/full-server replies, native join errors and uncompleted teleport requests count as failures. Protection waits, missing characters/pads, and cancelled attempts do not. Finding the friend in the current server clears the failure streak. Changing the target or toggling the feature resets its current retry cycle.

## Combat

| Feature | Behavior and fresh default |
| --- | --- |
| **Kill Aura** | Scripted normal damage against eligible nearby enemies. Damage-only: manual walking/jumping works without Auto Farm. OFF. |
| **Auto Farm** | Moves to eligible loaded enemies and manages farming noclip. Uses the default Below position with adaptive clearance. Does not automatically enable Kill Aura. OFF. |
| **Boss Only** | Restricts Auto Farm and arena-clear checks to main bosses/mini-bosses, ignoring regular mobs. OFF. |
| **Credit Check** | Coordinates the user-specified 5% boss-credit target with a separate group. OFF. |
| **Credit Whitelist** | Independent usernames/user IDs for credit coordination |
| **Credit Status** | Shows missing accounts/counters, required damage, current plan, or finishing status |
| **Auto Equip Best Gear** | Equips the best owned usable weapon, armor, and accessories. ON. |
| **Swing animation** | Normal-speed visible swings, independent of damage-request pacing. ON. |

### Target selection and movement

Target priority is **main boss = 1, mini-boss = 2, regular = 3**, with common name/world-position ordering for ties. A higher-priority enemy preempts a lower-priority lock; same-rank boss fights converge on the common selected-scope order. Active complete credit groups use the common boss order instead of retaining conflicting locks; Account Progression retains its own boss restriction. Death, exhausted hit lives, despawning, or an explicit scope/settings change can release a normal lock. Temporary invulnerability or missing streamed health is not a confirmed kill.

When any live chest is loaded, **Auto Farm finishes its current enemy first, then opens the chest before choosing another enemy**. Once collecting a chest, new bosses do not interrupt it. All chest variants are eligible, including with Boss Only or Multi Spot enabled, and boss-credit waits do not apply to chests. Account Progression delays its next floor until loaded chests are cleared without counting them as a boss kill. Native invulnerability, safety, travel, dodge and trade checks still apply. Ordinary enemy priority resumes when no eligible chest remains.

F11's **DA, RA, KA** encounter uses `5287433115/Miniboss`. Da, Ra and Ka have a name-based miniboss fallback when their native rank markers are missing; their case or name padding does not exclude them from this selected encounter.

Range is unlimited over enemies **actually loaded on the client**. The script cannot see arbitrary enemies Roblox has not streamed to that account. Bosses/minis outside a selected Multi Spot arena can be eligible after the current fight.

Farming uses common geometry and shared server-clock pacing, with separate account positions around each enemy. Slots follow the server's sorted user IDs, refreshed at most once per second. The position controller holds the slot, ignores movement under 0.75 studs, and retains it during boss jumps. Joining/leaving players can reassign slots. Update every farming account to use this behavior.

Creating a farm hold removes stale Feather position/orientation constraints and attachments on that character root, preventing abandoned controllers from pulling toward an old destination.

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

Credit belongs to each enemy separately. Qualifying on Radioactive Experiment does not qualify that account on C-618 Uriotol. With Auto Farm active, a complete group uses a common loaded boss order even if accounts previously locked different living enemies. Update every participating account and use matching whitelists; differing streamed enemies can still affect which targets each client can see. Status names the enemy whose counters are missing. All verified members reaching 5% on that same enemy releases the damage gate immediately.

Roster calculations are reused between refreshes. An unchanged roster retains pending hit acknowledgments; membership changes clear them. Damage counters are checked on every attempt, and NaN/infinite values remain unverified. Severe latency above 500 ms or script loop cost above 6 ms reduces normal requests to one per frame and 12 per second, with a three-second recovery interval. This reduces outgoing bursts; it does not change the network's underlying latency.

The planner learns normal-hit and selected-skill damage per equipped weapon/enemy type. It chooses a low-excess combination and rechecks actual contribution after each hit. With 300k remaining, observed 250k skill damage, and 50k normal hits, it can plan one skill plus one normal hit. Unknown damage requires calibration; criticals, partial skill windows, changed equipment, and replication can alter estimates. Only enabled aura modes are used.

This gates local scripted hits. It cannot undo in-flight damage, split a single lethal hit, or stop other/manual attackers. More than 20 accounts cannot each receive 5% of one unhealed HP pool. It cannot guarantee every account gets drops or Vel.

## Waves Defense

Use **Create Room** to add a numbered setup with **Host**, **Alt**, **Difficulty**, **Mode**, and **Start**. Paste up to seven Alt usernames or IDs and Feather formats them with commas and spaces. Enable the same room setup on the assigned accounts in the same server. The host creates and configures the room, then starts after every listed Alt joins. An empty Alt list starts a solo room. The game's access rules still apply. A failed start pauses that setup until you toggle **Start** again.

The native party limit is eight accounts total: one Host and seven Alts. Repeating the host in Alt is ignored when resolving the assignment. Too many alts, malformed assignments or conflicting enabled rooms show a warning under the affected **Start** toggle; the roster is never silently truncated. Correcting the setup clears its warning without restarting the script.

Each account must appear in its own active preset's room **Host** or **Alt** list. A Safe Mode whitelist, Auto Join Friend target or Regroup Users list does not assign it to a room. If Start is ON but the current username is absent, the Start toggle identifies that mismatch. The saved `AutoCreateBetween` flag is derived from a valid assignment; editing that flag alone does not enable joining. Keep the Host and Alt rosters consistent in the outside and Between presets used by every participating account.

While **Start** is ON, each Alt continuously searches for its configured Host's room and attempts to join every three seconds until native party membership is confirmed. This does not wait for a wipe, Wave 100, or the Alt's Auto Retry setting. If the host replaces the room or membership is lost, joining resumes automatically. Start OFF, Stop Everything, teleport and active Safe Mode recovery pause the loop. Update/reload the script on each Alt to use this behavior.

Use the **X** on a room header to delete its saved setup. The remaining setups are renumbered.

The Between automatically uses free revives while the server reports lives remaining. **Auto Retry** appears only for the configured host. After everyone is down with no free revives left, or after Feather observes the Wave 100 reward chest being opened, Auto Retry starts the room setup from inside The Between. It reuses the host's party if the game retained it and creates a room if the party is gone. Alts keep checking for the configured host's room after a run ends, and the host waits for the full roster before starting. A queued teleport carries the room assignment into the inside preset. **Start** must be enabled on each assigned account.

Wipe detection checks the game's combat health as well as the Humanoid. A default avatar without combat data gets a five-second loading grace period, then stops blocking an otherwise confirmed wipe. Living combatants, remaining or unknown lives, and loaded characters without defeat confirmation still prevent retry. The wipe must remain stable for another second before room setup begins.

**Completion Time** has a two-handle range for each difficulty, up to 100 minutes. Set both ends to zero to turn pacing off. Feather picks a time down to the second inside the range, shared by accounts using the same range in the same run. It spreads kills across the 100 waves and pauses automated attacks when ahead. Actual completion depends on wave timers and available damage.

**Auto Dodge** starts at `(10, -19, -5)` during other survival special waves, checks that shelter against tracked attacks, and temporarily sidesteps after confirmed damage there. During Blackout it holds at `(12, 37, 3)`. Skill Aura, when enabled, hits enemies that come into range. Auto Farm movement and ordinary Kill Aura hits pause until Blackout ends. Default ON. Below-map idle holds enforce kill-plane clearance, and floor caches reset when the wave or arena origin changes.

**Auto Regroup** defaults OFF. Enable it on every account that should leave a split run together. It checks the room's **Host + Alts** by default; **Regroup Users** can supply a separate comma-separated username or user-ID list. After a 15-second loading grace period, any listed user missing from the server for five seconds triggers one character reset and the native return-to-lobby action on that account. Listed users who are dead or respawning still count as present. Regroup pauses combat, free revives, room starts and friend joining while returning, and yields to active protection/teleports. It operates only inside The Between and does not control other clients directly. Saved settings retain the toggle and optional list; each account must run this version.

After the reset commits, Auto Regroup keeps its return step scheduled through ordinary Safe Mode or roster changes; Stop Everything and moderator protection still pause it. It waits briefly for the native revive/return state and sends the game's **Return** request even if settings-save or automatic-reload preparation fails. A preparation warning reports when automatic execution in the lobby is unavailable. Return requests are paced and limited to three, with a timeout for a teleport that starts but never completes. Regroup-only configurations are included in the queued loader's resume checks.

On Wave 100, **Auto Dodge** checks Rubricatus's locked disc paths, laser charge warnings and beams, the native 100-stud/120° lightning wave, tagged melee hitboxes, and standard ground warnings for spikes and falling stones. It checks the saved Auto Farm return position as well as the current position, cancels script-owned casts before an escape hold, and resumes farming when the warning expires.

For **Nuke**, it selects a raised, collidable pillar between the blast origin and the character, verifies the pillar with a raycast, and holds behind it until the pillars collapse. Spawn markers, underground parts and distant scenery do not count as cover. Missing or obstructed cover keeps Auto Farm paused for a bounded wait rather than sending it back toward the boss. Pillar geometry is preserved by map cleanup. The existing Auto Dodge setting controls this behavior.

The v3.0.28 dodge uses the native laser radius (80 studs) during its thin charge warning and the native disc radius (10 studs), including the path crossed between observations. Bounded warning storage supports overlapping spike rows and discs. Offline regressions and a native fixture with real Roblox parts pass; the fixture sends no damage requests. Native combo, slam, laser, disc, spike and falling-stone code was inspected, but pillar discovery and a complete Wave 100 fight on this version have **not** been verified live. Shadow Dash has no dedicated phase predictor yet. This does not guarantee every Rubricatus attack is avoided.

The local wave audit keeps the latest 32 observed health losses across ordinary waves, special waves and Wave 100, including lethal health changes, position, dodge state and recent replicated skill context. A nearby cast is context rather than proof of the damage source. Respawns reset the health baseline, and the audit marks when No Self Damage is enabled. The records stay in the executor workspace and are not included in config exports.

Extended camera zoom is applied while the runtime owns it.

## Auto Skill

Skill Aura re-resolves usable skills after weapon changes. **Summon Pistol takes automatic priority whenever it is unlocked and compatible**, ahead of saved class selections and weapon defaults. Unlocks are rechecked every two seconds without a restart. When Pistol is unavailable, the resolver uses the saved compatible skill or the weapon's default. Automatic Pistol selection preserves saved class preferences for that fallback.

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

### Atheon Unlock

The **Main → Teleport → Spot** dropdown also includes **Portal · Atheon Portal** whenever `workspace.AtheonPortal` is present as a Part or Model. Select it for manual travel using the normal teleport depth; **Refresh List** updates its availability and position.

Automatic portal travel supports Parts, Models, Attachments, and Folder-wrapped touch parts. It verifies arrival after one second and retries if the server corrected the character's position instead of treating a local movement call as confirmed arrival.

**Atheon Unlock** (OFF by default) teleports to `workspace.AtheonPortal` when enabled, only if Atheon is still locked for the current account. Accounts with Atheon unlocked, including characters already on that floor, skip the portal. It waits for the portal and a living character, retries failed moves, and makes one placement per enable, character, or replacement portal rather than holding the character there. Farming and arena travel pause briefly after arrival. Safety, trading, travel, and dodge activity take precedence. The toggle is saved and included in config export/import; native unlock requirements still apply.

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
| **Delete map** | Default OFF. Clears terrain and deletes static scenery/floors in bounded batches, including newly streamed parts. Preserves character/enemy rigs, gameplay effects, hazards, interaction objects and teleport/spawn objects. OFF stops further deletion; rejoin to restore geometry. |
| **Remove animations** | Default OFF. Stops existing and newly played local animations on characters/enemies. Disconnects hooks when OFF; subsequent native animations can play again. Native animation markers may be affected. |
| **Disable rendering** | Disables 3D rendering when its API is supported |
| **Limit FPS** | Caps hidden farming at 15 FPS; allows 60 FPS while the UI is open; restores the previous cap when released |
| **Remove everything** | Default OFF. Combines map deletion, animation removal, visual suppression and disabled 3D rendering. Keeps UI/combat controllers, releases the farming FPS limiter, and restores individual booster selections when OFF. Deleted map geometry still requires a rejoin. |

Options are explicitly selected. A lower FPS cap reduces resource use; it is not an FPS increase. Unsupported APIs report failure rather than being assumed available.

Map processing releases each consumed instance reference immediately and caps the streaming queue at 8,192 entries, with a deferred rescan after overflow. Explicit map deletion permits arena travel to confirm its configured height without a deleted floor; idle holding avoids cumulative height drift. Ordinary walking and floor-dependent dodges can still need geometry.

Ground-following discards cached floor heights while map deletion is active. This prevents a stationary enemy from remaining permanently classified as airborne above deleted geometry, which previously could leave the farming position outside attack range. Real upward velocity and supported native attack hints still pause ground following.

UI maintenance prunes disconnected signals and destroyed theme/font/localization references in bounded slices, including while hidden. Shutdown disconnects every recorded signal. Retired performance wrappers release their runtime references even when another wrapper still calls them. These address specific retention paths; engine asset caches and multiple Roblox clients also consume RAM, and short tests do not establish long-term memory stability.

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

**Reset Saved Progression**, beside the progression toggle in **Speacial**, saves a fresh Floor 1 checkpoint and clears saved boss-clear and completion flags. If progression is ON, it clears its paused controller and resumes from F1 when protection and movement permit. If progression is OFF, it stays OFF. Stop Everything remains paused, and the original farming preferences are retained for when progression is switched off. The button does not remove floor unlocks or inventory.

Streaming loss, an unrelated miniboss, or an uncredited corpse is not a completed main-boss kill. The script cannot grant a floor unlock the server has not awarded. **F12 is the endpoint**; Atheon and Atlantis are not additional progression stages.

**Anti Suspicious** starts counting Safe Mode departure attempts after the account reaches its first protected server. A rejoin and its fallback kick count as one attempt. **Rejoin Limit** and **Track (min)** default to **10 departures in 10 minutes**. Set a **Rest Time (min)** range up to **200 minutes**. At the limit, Feather saves a randomly selected deadline down to the second, kicks the local account, and attempts a rejoin when the timer ends if the executor is still running. The account's deadline is retained across reloads. If the kick stops the executor, reopen Roblox manually after the rest.

## Dodge

**Atheon Dodge** evades supported Atheon attacks and hazards, then returns to farming. OFF by default.

## Settings

| Control | Behavior |
| --- | --- |
| **Theme** | Selects a theme from bundled WindUI |
| **Config Export** | Copies portable JSON to the clipboard |
| **Config Import** | Paste an export to add its presets and restore its Auto Preset choices |
| **Load Preset** | Load the selected preset or switch back to Default |
| **Auto Preset** | Load the assigned preset on startup and supported teleports, with separate choices for inside and outside The Between |
| **Webhook** | Send new inventory items and stack increases to Discord for the selected rarities |

Paste a Discord webhook URL in **Settings → Webhook**, choose **Send Test**, then turn on **Reward Webhook**. Legendary, Tribute, and Burst are selected by default. **Hide Player Name** omits the Roblox username. The URL and alert preferences are saved in the executor workspace for accounts that use it, separately from portable config exports. Outbound HTTP support is required.

Export includes feature toggles, **both whitelists**, floor/skill/item selections, Multi Spot order, layout/theme, and **custom Save Spot entries from all available floor files**. Custom-spot transfer requires executor file access. Saved progression is account-local: the floor checkpoint, boss-clear receipt/name, completion flag and original progression mode snapshot are excluded from the exported active profile and every preset. The **Account Progression** toggle remains a portable preference.

Shared presets and older imports cannot supply another account's saved progression. A new account starts at F1; an existing account keeps its own saved checkpoint when reloading its preset. Legacy preset migration preserves the owner's checkpoint in its account-specific settings file. Previously copied checkpoints already present in an account's save can be cleared with **Speacial → Reset Saved Progression**.

Preset files, Auto Preset selections, shared preferences, and custom spots are available to every account using the same executor workspace. Each account's existing presets are added to the shared list when it next runs Feather. The first migrated account supplies the initial automatic selections if there is no shared list yet. Config Export copies the active profile, saved spots, preset library, and the Auto Preset choices for inside and outside The Between. Import adds the profiles to the destination library, updates its preset choices to point at the imported copies, and applies those choices on the next load. Default refers to the destination workspace's default profile. Loading a preset can enable the toggles in its settings. Feather validates imported JSON as data. Credentials, temporary rejoin tickets, live server observations, and damage-learning caches are outside the portable configuration.

## Built-in background features

| Feature | Behavior |
| --- | --- |
| **Anti-AFK** | Always enabled with Feather. One idle listener requests VirtualUser input, with a paired press/release fallback if ClickButton2 fails. Duplicate events are paced; no continuous movement loop. Works while farming is paused and disconnects on unload/reload. |
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
| Atlantis | Aeganatos, The Sunken Sovereign | `1500, 792, 127` | ~60s; server delays may increase it |
| Atlantis | Leviathan | `12, 1313, -823` | 45s |
| Atlantis | Kraken | `353, -319, 120` | 45s |

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
| Severe FPS drops | Explicit performance options and frame-time/memory measurements to separate script overhead from rendering/VM load; Limit FPS intentionally caps hidden farming at 15 and allows 60 while the UI is open |

## Development and verification

| Path | Role |
| --- | --- |
| [loader.luau](loader.luau) | Stable public loader |
| [kill-aura.luau](kill-aura.luau) | Generated standalone entry; do not hand-edit |
| [src/main.luau](src/main.luau) | Runtime assembly and ordered source includes |
| [src/](src/) | Bootstrap, settings/detection, presentation, movement, combat/lifecycle, scheduling, automation, utilities, UI and background adapters |
| [kill-aura.body.luau](kill-aura.body.luau) | Generated runtime body; do not hand-edit |
| `*.module.luau` | Feature/controller implementations |
| `*.test.luau`, `*.test.lua` | Offline regressions and injected engine doubles |
| [build-script.py](build-script.py) | Bundles modules and the pinned UI library |
| [run-offline-tests.py](run-offline-tests.py) | Consistency, regression, encoding and compile checks |
| [vendor/](vendor/) | Pinned WindUI, provenance and upstream license |

Enemy detection uses one registry across movement, skills, credit, HUD and arena controllers. It retains shared combat observations, notices late health/HitLives without a negative-cache delay, and disconnects the old index on streaming-folder replacement. Named tasks have independent due times, error counters and backoff; missed intervals never produce catch-up request bursts. Movement ownership is recomputed from active safety/trade/travel/dodge/farm states instead of leaving an unbounded lease behind.

Reload snapshots clone configuration fields rather than retaining the previous runtime's controller graph. Cleanup executes every registered operation even if one fails, with errors recorded in `CleanupErrors`. Diagnostics expose `EnemyRegistry.Count`, `EnemyRegistry.Revision`, `WorkScheduler.Tasks` and `MovementOwner`. These describe local script behavior; FPS and total client RAM also depend on scene, streaming, rendering, executor and device load.

Memory checks cover a 20,000-effect burst, 30,000 queue add/remove cycles, 1,000 incomplete-enemy add/remove cycles with listener counts, 300 arena spawn/remove cycles, failed skill observations, failed UI teardown, and runtime reload cleanup. Visual work queues cap retained entries at 8,192 and immediately remove streamed-out objects; maintenance uses weak references. Arena records prune removed/dead models. Skill observers disconnect before reading potentially missing counters, and UI signals are independently disconnected even if window destruction fails. These are targeted retention tests, not proof of zero memory growth in Roblox or the executor over an unlimited session.

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

Auto Farm Position has been removed. Saved Above/Below selections are ignored; ordinary farming uses Below.

Common boss choice is independent of credit-roster presence. Conflicting same-rank locks converge using the selected-scope order, and owned skill casts yield when that focus changes. Enemies must still be streamed to the client. Account Progression, selected-arena limits, native invulnerability and safety checks remain authoritative.

Aeganatos Dodge (Dodge tab, default OFF) reads native OmegaWave FireWave and OceanGyzer CreateGyzer phase events for Aeganatos, The Sunken Sovereign. It plans outside the swept wave envelope or geyser footprint, expires records and yields to safety/trade/travel. Hidden VFX do not determine whether a phase is dangerous. Live cast coverage is limited to phases replicated to that client; this does not guarantee every attack is avoided.

No Self Damage (enemy skills), in Dodge, defaults OFF. It intercepts the native EnemySkills.Base.DamageLocalPlayer reporting path used by client-side enemy-skill touch damage. It does not block unrelated requests or server-applied damage. OFF/cleanup restores the prior native handler when owned; retired wrappers forward normally.

Aeganatos avoidance holds one validated shelter while the intended farming destination remains inside a live hazard, then hands movement back to Auto Farm. Offensive scripted casts are cancelled on dodge handoff so movement skills cannot drag the character back into danger. OceanGyzer windup and active phases are observed separately; the real phase replaces its speculative footprint. The local danger margin is conservative and does not imply knowledge of server hit validation.

MCP live validation on VanguardSlasher confirmed Aeganatos health reached zero. The final recorded delayed-windup segment observed 44,909,576 → 0 boss HP in 193 seconds, zero player deaths, with NoSelfDamage OFF. This validates the observed attack cycle and Auto Farm handoff, not immunity to every server condition. Geyser onset can still cause damage.
