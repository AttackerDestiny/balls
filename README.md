# balls

Swordburst 2 Luau script with a loader that fetches the latest published version.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/AttackerDestiny/balls/main/loader.luau"))()
```

The standalone script automatically creates `SB2Codex` in the executor's workspace and saves its own runnable source, account settings, and rejoin state. Settings and the whitelist are shared between accounts using the same executor workspace through `SB2Codex/shared-settings.json`. Existing configured profiles are migrated automatically. Current-floor context, progression checkpoints and rejoin tickets remain per-account. Re-execute the loader on each account to load shared changes. Separate devices or isolated app storage do not share local files.

Safe Mode floor unlock labels update when the account's native unlock data changes. Opening the dropdown, selecting a floor, and starting floor travel recheck the current profile, so newly unlocked floors become selectable without restarting. Unlock events update existing buttons without rebuilding the dropdown or polling every frame.

Features include Auto Farm with noclip, Kill Aura, Skill Aura, Safe Mode with an editable whitelist, Multi Spot, Atheon Dodge, and Account Progression in the **Speacial** tab. Moderator detection confirms the moderator is blocked before disconnecting. Unconfirmed blocking pauses automation without kicking.

Account Progression skips F6 (Helmfirth), travelling directly from F5 to F7 when F7 is unlocked. It coordinates farming and floor travel, selects owned usable gear, and synchronizes Safe Mode's selected floor. Multi Spot waits while progression owns travel. The latest code has offline regression coverage; executor-specific behavior also requires live validation.

## Development

- Run `kill-aura.luau`, the generated standalone entry.
- Edit `kill-aura.body.luau` and the matching `*.module.luau` files.
- Run `python build-script.py` to refresh bundles and the standalone entry.
- Run `python run-offline-tests.py` before publishing.

Offline verification requires Python 3.10+, Lua 5.1+ on `PATH`, and the official Luau CLI tools. Supply their directory with `python run-offline-tests.py --luau-tool-dir /path/to/luau-tools`.

Do not commit executor workspace files, account settings, local logs, credentials, or session notes. Each completed script update is committed and pushed so the loader serves the current version.
At steady 10Ã¢â‚¬â€œ15 FPS, combat remains active instead of repeatedly entering a lag pause. Sudden freezes still trigger a brief recovery pause. Health-bar and cosmetic refreshes are paced separately from movement and dodge checks. Low FPS still limits how quickly the client can observe hazards.

After its own confirmed moderator-block kick, the script attempts to rejoin the current place, with at most three requests eight seconds apart. It queues the public loader for the destination session when the executor supports teleport queues. This only handles the scriptâ€™s moderator kick; it does not bypass bans. Some executors stop scripts after disconnection or reject post-kick teleports, so live executor support is required. Stop Everything or runtime replacement cancels pending requests.

Auto Join Friend is in Main: enter a Roblox username and turn the toggle on. It uses the native FriendTeleport route, retries no more than once every 20 seconds, and stays once the target is in the same server. The toggle and username share the normal autosave. Account Progression takes priority; Safe Mode requires the target in its whitelist. Native restrictions (offline player, full server, locked floors or join permissions) remain enforced and appear in the status. Teleport queue support is required to resume automatically.

The Main tab's restart script button saves settings, downloads and compiles the public loader, retires the current runtime, and runs the loader again. Repeated clicks during restart are ignored. Fetch or compile failures leave the current runtime active.

Skill Aura visual suppression includes mobile-safe property fallbacks, disabled/transparent emitters, beams and trails, particle/trail clearing, and smoke/fire/sparkle/texture cleanup. New confirmed effects are suppressed immediately within a bounded work limit; overflow uses the existing queue. Unsupported property writes do not stop later effects from being processed. Rendering properties restore on cleanup; hitbox physics, damage timelines, normal swings and protected hazard/text cues remain intact. Arceus X device validation is separate from offline tests.

Auto Join Friend physically returns to the spawn/teleport pad and waits for position replication before the native request. Farming yields while the pad is held. A pad-specific rejection gets one bounded retry; other server errors are shown normally. Cancellation releases the hold unless Safe Mode or moderator protection still owns it.

Auto Equip Best Weapon is a separate Combat toggle, ON by default and autosaved across accounts. It works independently of Auto Farm, ranking owned level-usable weapons of every class by native damage, upgrades and scaling. It equips only one weapon in Right and clears an existing Left weapon before equipping. Turning it OFF prevents weapon auto-equipping, including during Account Progression; progression still manages armor and accessories. Inventory, level and equipment changes trigger reevaluation with native acknowledgments and bounded retry.

Multi Spot returns to the selected arena anchor only after five continuous seconds with no living or unknown arena enemies. Combat, spot changes and protection reset the delay. Auto Farm detection has no distance cap for client-loaded mobs; server spawning and Roblox streaming still determine which mobs are available. Infinity is kept out of the JSON settings payload.

Safe Mode uses a 0.15-second initial settle and 0.3-second solo confirmation window, with a 0.03-second active worker interval (subject to frame scheduling). The block dialog waits for stable layout, avoids redundant clicks after acknowledgment, and retains latency-aware native confirmation before hopping; the separate post-block settle timer is removed. Hidden-effect maintenance processes at most 64 entries or roughly 0.6 ms per update, progressing round-robin through larger sets. Network/server loading time and device rendering costs remain outside script control.

Utility has separate Auto Dismantle Common, Uncommon, and Rare toggles (OFF by default, shared autosave). It processes existing inventory on startup with saved toggles ON, when enabling a rarity, and newly received drops. Inventory scanning is batched; equipped items, native Locked/Favorited attributes, stacked items, and Undismantleable definitions are rechecked before sending. It preserves equipped items, detected lock/favorite/skin flags, Novice items, auras, and planned auto-equipment upgrades. Each new drop gets a short replication delay and is checked again before one native Equipment/Dismantle Event request. Requests are paced and never blindly retried; Stop Everything/protection/travel pauses processing. No live inventory was dismantled in offline verification.

Shared autosave merges only preferences changed by the saving runtime into the latest shared file. Another account saving an unrelated option no longer overwrites a newer Safe Mode toggle or whitelist with stale values. Re-execute on each account to load shared updates; this is local-workspace sharing, not cross-device synchronization. Floor/progression context remains per-account.

Safe Mode recovers from temporary native block-list/dialog errors and failed rejoins with up to three retries (2, 4, and 8 seconds). Retry attempts keep the original search clock and hop count; rejoin retries recheck the previous native block without adding another block. Missing executor capabilities, unreliable matchmaking, and search limits remain terminal and show the reason at spawn. No automatic restart bypasses those limits.

Utility groups the three dismantle rarity toggles under Auto Dismantle. Auto Trade (OFF by default) uses the Safe Mode whitelist for request acceptance and partner validation. Its inventory dropdown selects item names (all eligible copies), and Offer mode switches between Selected and Legendary+ (Legendary, Tribute, and Burst). The separate Tribute mode is removed; saved Tribute selections migrate to Legendary+. Vel is automatically set to the maximum affordable amount including the 10% tax: floor(balance * 10 / 11), capped at the native 100,000,000 offer limit. The manual Vel box is removed. Equipped, Locked/Favorited, and native trade-restricted items are excluded. Automatic final confirmation/acceptance is built in: the exact outgoing items/Vel must be replicated, the offer must remain stable for two seconds, and both native confirmations are required before acceptance. Unselected outgoing items pause automation. Trading pauses farming, auto equipment and dismantling. Modes, selections and toggle share normal autosave. No real trade was accepted or completed in verification.

Auto Trade also checks the visible native request prompt while enabled, recovering requests received before enabling or re-executing. It resolves the exact requesting username, rechecks whitelist membership, and calls the native AcceptRequest handler once per visible request. Initial RequestAccept snapshots initialize offering immediately. No live acceptance/completion was used to verify this recovery.

Auto Trade expands selected stacked items using their native Count value. It has no local item-count cap and fills all eligible selected quantities, adding at most four per batch and waiting for server acknowledgment before the next batch. Inventory dropdown quantities include stack counts. Final confirmation waits until the planned quantities are registered; server-enforced limits still apply. If additions are not acknowledged, automatic confirmation waits and the status explains the stalled batch.

During an automated trade, movement captures the current X/Z and detected ground height once, then holds at ground minus 20 studs. Farming, swing/skill actions, Multi Spot and progression yield until the trade ends; existing feature preferences are preserved. Respawning reacquires a new anchor. Safe Mode/moderator protection and active server transitions take priority. Offline checks cover hold stability and release; no live trade was completed.

Upgrade Protection Scroll and Resurrection Crystal are always included in Auto Trade in every offer mode, using their full eligible stack quantities. Equipped, Locked/Favorited and native trade-restricted instances remain excluded. Auto Trade must still be enabled and its partner whitelisted.

Rejoin sources are saved at build-specific executor paths, verified/repaired before queueing; another account running an older build cannot replace the active build’s queued source. An independent protected-population check releases stale spawn holds after a stable protected result. Resumed search failures retain their original limits instead of starting fresh. After a Safe Mode native rejoin request returns or reports Started/InProgress, the character holds 10,000 studs horizontally away at the same height while waiting; failure/cancellation clears that destination. This changes the waiting position, not Roblox teleport loading time.

Safe rejoin escape is deferred immediately after entering the native Teleport call, rather than waiting for its return or Started callback. Request failure, Stop Everything, moderator priority and replacement dispatches cancel stale escape callbacks. Active search starts run their first check immediately; dialog layout and native block confirmation checks remain. Queue setup skips redundant validation once queued for the same run, identical cached sources compile once per runtime, and unchanged panic hold coordinates are not rewritten.

Same/visited-server returns now retry within the original search instead of immediately pausing. The first retry has no added delay; repeat returns wait 0.25 and 0.5 seconds. Existing blocked outsiders are reconfirmed and reused without another block prompt. A persisted three-return counter plus the existing hop/lifetime limits prevents endless rejoin loops across executions. An already-protected return finishes normally. Missing native block confirmation still prevents rejoining.

With Safe Mode ON, a continuously present non-whitelisted player starts an eight-second timer. If the client is still in the same server at expiry, the fallback cancels normal search work, confirms the target’s native block, persists/queues recovery, then kicks. Departures, whitelist edits, disabled protection and job changes cancel the action. Rejoin recovery is armed before kicking and makes at most three attempts; temporary block/queue failures never kick and receive at most three bounded retries. Existing hop/lifetime limits remain. A low-frequency population timer and one fallback worker avoid per-frame inventory/world scans. Post-kick teleporting depends on executor support; no real kick/block test was performed.

Safe Mode same-floor matchmaking now holds the current position rather than travelling to spawn. After native block confirmation and required state/queue preparation, the rejoin is dispatched in the same search update without an extra settle tick. Its eight-second fallback also holds in place. The after-dispatch 10,000-stud move is retained. Native floor-change/friend-join pad staging and moderator protection retain their separate pad behavior.
