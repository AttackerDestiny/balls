# Repository workflow

The user explicitly requested a public repository named `balls` and asked that every future script update/change be committed and pushed here.

- Keep `kill-aura.luau` and `loader.luau` at stable paths so existing loaders continue working.
- Edit `kill-aura.body.luau` and standalone modules; generate the runnable entry with `python build-script.py`.
- Bump the body's build/version when changing runtime behavior so the singleton replaces an older runtime.
- Run `python run-offline-tests.py` for relevant changes. Never use real account kicks, blocks, or floor progression as unit tests.
- Follow the user's current live-testing limits; do not infer permission to resume an interrupted game test.
- After each completed requested update, commit the relevant source/tests/docs and push the commit to this repository. Preserve unrelated local changes and avoid force pushes.
- Verify publication and mention the commit when reporting a published update.
- Exclude `WORK-NOTES.md`, executor workspaces, account settings, logs, and credentials from public commits.
