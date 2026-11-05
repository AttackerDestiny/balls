# Repository workflow

The user explicitly requested a public repository named `balls` and asked that every future script update/change be committed and pushed here.

- Keep `kill-aura.luau` and `loader.luau` at stable paths so existing loaders continue working.
- Edit `src/main.luau`, its included runtime sources, and standalone modules; generate `kill-aura.body.luau` and the runnable entry with `python build-script.py`. Do not hand-edit generated files.
- Bump the build/version in `src/bootstrap.luau` when changing runtime behavior so the singleton replaces an older runtime.
- Run `python run-offline-tests.py` for relevant changes. Never use real account kicks, blocks, or floor progression as unit tests.
- Follow the user's current live-testing limits; do not infer permission to resume an interrupted game test.
- After each completed requested update, commit the relevant source/tests/docs and push the commit to this repository. Preserve unrelated local changes and avoid force pushes.
- Verify publication and mention the commit when reporting a published update.
- Exclude `WORK-NOTES.md`, executor workspaces, account settings, logs, and credentials from public commits.
