# balls

Swordburst 2 Luau script with a loader that fetches the latest published version.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/AttackerDestiny/balls/main/loader.luau"))()
```

The standalone script automatically creates `SB2Codex` in the executor's workspace and saves its own runnable source, account settings, and rejoin state. Existing settings are preserved.

Features include Auto Farm with noclip, Kill Aura, Skill Aura, Safe Mode with an editable whitelist, Multi Spot, Atheon Dodge, and Account Progression in the **Speacial** tab. Moderator detection confirms the moderator is blocked before disconnecting. Unconfirmed blocking pauses automation without kicking.

Account Progression coordinates farming and floor travel, selects owned usable gear, and synchronizes Safe Mode's selected floor. Multi Spot waits while progression owns travel. The latest code has offline regression coverage; executor-specific behavior also requires live validation.

## Development

- Run `kill-aura.luau`, the generated standalone entry.
- Edit `kill-aura.body.luau` and the matching `*.module.luau` files.
- Run `python build-script.py` to refresh bundles and the standalone entry.
- Run `python run-offline-tests.py` before publishing.

Offline verification requires Python 3.10+, Lua 5.1+ on `PATH`, and the official Luau CLI tools. Supply their directory with `python run-offline-tests.py --luau-tool-dir /path/to/luau-tools`.

Do not commit executor workspace files, account settings, local logs, credentials, or session notes. Each completed script update is committed and pushed so the loader serves the current version.
