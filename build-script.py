"""Bundle modules and package the standalone self-installing executor entry."""
from pathlib import Path
import argparse

ROOT = Path(__file__).resolve().parent
BODY = ROOT / "kill-aura.body.luau"
ENTRY = ROOT / "kill-aura.luau"
PREFIX = "local SB2_SOURCE=[============[\n"
SUFFIX = ']============]\nreturn assert(loadstring(SB2_SOURCE, "SB2"))(SB2_SOURCE)\n'
MODULES = {
    "AUTO TRADE": "auto-trade.module.luau",
    "SERVER ISOLATION": "server-isolation.module.luau",
    "AUTO DISMANTLE": "auto-dismantle.module.luau",
    "SKILL VISUALS": "skill-visuals.module.luau",
    "RESTART SCRIPT": "restart-script.module.luau",
    "MODERATOR REJOIN": "moderator-rejoin.module.luau",
    "FRAME TIMING": "frame-timing.module.luau",
    "SHARED SETTINGS": "shared-settings.module.luau",
    "MODERATOR WATCH": "moderator-watch.module.luau",
    "FARM NOCLIP": "farm-noclip.module.luau",
    "BLOCK CONFIRM": "block-confirm.module.luau",
    "BLOCK INPUT": "block-input.module.luau",
    "STORAGE BOOTSTRAP": "storage-bootstrap.module.luau",
    "RUNTIME OWNER": "runtime-owner.module.luau",
    "LOBBY PLAY": "lobby-play.module.luau",
    "ENEMY HEALTH": "enemy-health.module.luau",
    "ARENA TRAVEL": "arena-travel.module.luau",
    "MULTI SPOT": "multi-spot.module.luau",
    "SERVER ISOLATION CLIENT": "server-isolation-client.module.luau",
    "AUTO JOIN FRIEND": "auto-join-friend.module.luau",
    "AUTOMATION UI": "automation-ui.module.luau",
    "FLOOR CATALOG": "floor-catalog.module.luau",
    "ATHEON DODGE": "atheon-dodge.module.luau",
    "WAVE DODGE": "wave-dodge.module.luau",
    "GROUND FOLLOW": "ground-follow.module.luau",
    "MISC SKILL": "misc-skill.module.luau",
    "SKILL BURST": "skill-burst.module.luau",
    "AUTO RANGE": "auto-range.module.luau",
    "AUTO OFFSET": "auto-offset.module.luau",
    "ARENA FLOAT": "arena-float.module.luau",
    "SAFE MODE": "safe-mode.module.luau",
    "ACCOUNT PROGRESSION": "account-progression.module.luau",
    "PROGRESSION GEAR": "progression-gear.module.luau",
    "PROGRESSION CLIENT": "progression-client.module.luau",
}


def package(body):
    assert "]============]" not in body, "Body contains the wrapper's closing delimiter"
    return PREFIX + body + SUFFIX


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    original = BODY.read_text(encoding="utf-8")
    body = original
    for marker, name in MODULES.items():
        start, end = f"-- BEGIN BUNDLED {marker}\n", f"-- END BUNDLED {marker}\n"
        assert body.count(start) == 1 and body.count(end) == 1, marker
        before, rest = body.split(start, 1)
        _, after = rest.split(end, 1)
        body = before + start + (ROOT / name).read_text(encoding="utf-8") + "\n" + end + after
    entry = package(body)
    if args.check:
        assert original == body, "Stale module bundles: run python build-script.py"
        assert ENTRY.read_text(encoding="utf-8") == entry, "Stale runnable entry: run python build-script.py"
        print("PASS Self-installing entry and module bundles")
    else:
        BODY.write_text(body, encoding="utf-8", newline="\n")
        ENTRY.write_text(entry, encoding="utf-8", newline="\n")
        print(f"Built {ENTRY.name} ({len(entry.encode('utf-8')):,} bytes)")


if __name__ == "__main__":
    main()
