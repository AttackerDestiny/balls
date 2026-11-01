# balls

Swordburst 2 Luau script with a loader that fetches the latest published version.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/AttackerDestiny/balls/main/loader.luau"))()
```

The standalone script automatically creates `SB2Codex` in the executor's workspace and saves its own runnable source, account settings, and rejoin state. Settings and the whitelist are shared between accounts using the same executor workspace through `SB2Codex/shared-settings.json`. Existing configured profiles are migrated automatically. Current-floor context, progression checkpoints and rejoin tickets remain per-account. Re-execute the loader on each account to load shared changes. Separate devices or isolated app storage do not share local files.

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
