"""Bundle modules and package the standalone self-installing executor entry."""
from pathlib import Path
import argparse
import re

ROOT = Path(__file__).resolve().parent
BODY = ROOT / "kill-aura.body.luau"
ENTRY = ROOT / "kill-aura.luau"
SOURCE = ROOT / "src/main.luau"
PREFIX = "local SB2_SOURCE=[============[\n"
SUFFIX = ']============]\nreturn assert(loadstring(SB2_SOURCE, "SB2"))(SB2_SOURCE)\n'
MODULES = {
    "AEGANATOS DODGE": "aeganatos-dodge.module.luau",
    "SELF DAMAGE PROTECTION": "self-damage-protection.module.luau",
    "SELECTED FARM SPOTS": "selected-farm-spots.module.luau",
    "PAD SLOT": "pad-slot.module.luau",
    "BLOCK UI MASK": "block-ui-mask.module.luau",
    "BETWEEN ROOM": "between-room.module.luau",
    "BETWEEN RETRY": "between-retry.module.luau",
    "ANTI SUSPICIOUS": "anti-suspicious.module.luau",
    "BETWEEN PACE": "between-pace.module.luau",
    "ATHEON UNLOCK": "atheon-unlock.module.luau",
    "INSTANCE QUEUE": "instance-queue.module.luau",
    "SETTINGS SNAPSHOT": "settings-snapshot.module.luau",
    "SKILL DAMAGE BUDGET": "skill-damage-budget.module.luau",
    "UPRIGHT": "upright.module.luau",
    "BOSS DODGE": "boss-dodge.module.luau",
    "HIDE PLAYERS": "hide-players.module.luau",
    "MOVEMENT OWNER": "movement-owner.module.luau",
    "ENEMY REGISTRY": "enemy-registry.module.luau",
    "WORK SCHEDULER": "work-scheduler.module.luau",
    "RUNTIME SCOPE": "runtime-scope.module.luau",
    "CONTROLLER VIEW": "controller-view.module.luau",
    "WEAPON SKILLS": "weapon-skills.module.luau",
    "ANIMATION REMOVAL": "animation-removal.module.luau",
    "UI MEMORY": "ui-memory.module.luau",
    "RUNTIME RECOVERY": "runtime-recovery.module.luau",
    "MAP DELETION": "map-deletion.module.luau",
    "PERFORMANCE BOOST": "performance-boost.module.luau",
    "PERFORMANCE BUDGET": "performance-budget.module.luau",
    "CREDIT DAMAGE PLAN": "credit-damage-plan.module.luau",
    "CREDIT ROSTER": "credit-roster.module.luau",
    "CREDIT CHECK": "credit-check.module.luau",
    "FARM COORDINATION": "farm-coordination.module.luau",
    "RESPAWN SCHEDULE": "respawn-schedule.module.luau",
    "STARTUP BELOW": "startup-below.module.luau",
    "CONFIG TRANSFER": "config-transfer.module.luau",
    "AUTO QUEST": "auto-quest.module.luau",
    "AUTO CRAFT": "auto-craft.module.luau",
    "PLAYER TOOLS": "player-tools.module.luau",
    "INVENTORY VIEW": "inventory-view.module.luau",
    "MULTI SPOT HUD": "multi-spot-hud.module.luau",
    "WINDUI": "windui.module.luau",
    "ANTI AFK": "anti-afk.module.luau",
    "TARGET PRIORITY": "target-priority.module.luau",
    "AURA TOUCH": "aura-touch.module.luau",
    "ATTACK SCHEDULER": "attack-scheduler.module.luau",
    "SKILL ACTIVATION": "skill-activation.module.luau",
    "SAFE KICK FALLBACK": "safe-kick-fallback.module.luau",
    "TRADE HOLD": "trade-hold.module.luau",
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


def expand_source(path, parents=()):
    path = path.resolve()
    source_root = (ROOT / "src").resolve()
    assert path.is_relative_to(source_root), "Source include leaves src/"
    assert path not in parents, "Cyclic source include"
    source = path.read_text(encoding="utf-8")
    return re.sub(r"(?m)^-- @include (.+)\n", lambda match: expand_source(
        path.parent / match[1], (*parents, path)), source)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    original = BODY.read_text(encoding="utf-8")
    body = expand_source(SOURCE)
    markers = set(re.findall(r"(?m)^-- BEGIN BUNDLED (.+)$", body))
    assert markers == set(MODULES) | {"WINDUI SOURCE"}, "Unknown or missing bundled module"
    for marker, name in MODULES.items():
        start, end = f"-- BEGIN BUNDLED {marker}\n", f"-- END BUNDLED {marker}\n"
        assert body.count(start) == 1 and body.count(end) == 1, marker
        before, rest = body.split(start, 1)
        _, after = rest.split(end, 1)
        body = before + start + (ROOT / name).read_text(encoding="utf-8") + "\n" + end + after
    start, end = "-- BEGIN BUNDLED WINDUI SOURCE\n", "-- END BUNDLED WINDUI SOURCE\n"
    assert body.count(start) == 1 and body.count(end) == 1
    before, rest = body.split(start, 1)
    _, after = rest.split(end, 1)
    library = (ROOT / "vendor/WindUI-1.6.66.lua").read_text(encoding="utf-8")
    # Use WindUI's own icon adapter with bundled Lucide data. The upstream
    # desktop path otherwise downloads Main-v2 and six icon packs on every load.
    icon_data = (ROOT / "vendor/Lucide-icons.lua").read_text(encoding="utf-8")
    icon_license = (ROOT / "vendor/Icons-LICENSE.txt").read_text(encoding="utf-8")
    icon_remote = 'local d=b(game:GetService"ReplicatedStorage":WaitForChild("GetIcons",99999):InvokeServer())'
    assert library.count(icon_remote) == 1
    library = library.replace(icon_remote, 'local d={Icons={lucide=(function()\n--[[\n' + icon_license + '\n]]\n' + icon_data + '\nend)()}}')
    remote_start = library.index('local m\nif d:IsStudio()or not writefile then')
    remote_end = library.index('m.SetIconsType"lucide"', remote_start)
    library = library[:remote_start] + "local m=a.load'b'\n\n" + library[remote_end:]
    license_text = (ROOT / "vendor/WindUI-LICENSE.txt").read_text(encoding="utf-8")
    library = "--[[\n" + license_text + "\n]]\n" + library
    library = "\n".join(line.rstrip() for line in library.splitlines()) + "\n"
    assert "]==========]" not in library
    body = (before + start + "return [==========[\n" + library + "]==========]\n\n" + end + after).rstrip() + "\n"
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
