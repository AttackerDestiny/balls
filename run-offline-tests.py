"""Run SB2 regressions without Roblox/MCP: python run-offline-tests.py."""
from pathlib import Path
import argparse
import os
import shutil
import subprocess
import sys
import tempfile


def quote(source):
    delimiter = "============"
    while "]" + delimiter + "]" in source:
        delimiter += "="
    return "[" + delimiter + "[\n" + source + "]" + delimiter + "]"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--luau-tool-dir", type=Path,
                        default=Path(tempfile.gettempdir()) / "codex-luau-tools")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent
    os.chdir(root)
    suffix = ".exe" if os.name == "nt" else ""

    def tool(name):
        candidate = args.luau_tool_dir / (name + suffix)
        result = str(candidate) if candidate.is_file() else shutil.which(name)
        if not result:
            raise SystemExit(f"Missing {name}; supply --luau-tool-dir with the official Luau tools")
        return result

    def read(name):
        return (root / name).read_text(encoding="utf-8")

    subprocess.run([sys.executable, str(root / "build-script.py"), "--check"], check=True)
    # Detect UTF-8 text accidentally decoded as Windows-1252 before publication.
    import re
    for source_file in [root / "kill-aura.body.luau", *root.glob("*.module.luau")]:
        text = source_file.read_text(encoding="utf-8")
        assert not re.search(r"[\u00c3\u00c2][^\x00-\x7f]|\u00e2[\u2000-\u2122]|\ufffd", text), f"Corrupt UI encoding: {source_file.name}"
    print("PASS UI source UTF-8 encoding")
    script = read("kill-aura.body.luau")
    for marker, name in [
        ("SHARED SETTINGS", "shared-settings.module.luau"),
        ("MODERATOR WATCH", "moderator-watch.module.luau"),
        ("ENEMY HEALTH", "enemy-health.module.luau"),
        ("ARENA TRAVEL", "arena-travel.module.luau"),
        ("MULTI SPOT", "multi-spot.module.luau"),
        ("SERVER ISOLATION CLIENT", "server-isolation-client.module.luau"),
        ("RUNTIME OWNER", "runtime-owner.module.luau"),
        ("AUTOMATION UI", "automation-ui.module.luau"),
        ("FLOOR CATALOG", "floor-catalog.module.luau"),
        ("ATHEON DODGE", "atheon-dodge.module.luau"),
        ("WAVE DODGE", "wave-dodge.module.luau"),
        ("GROUND FOLLOW", "ground-follow.module.luau"),
        ("MISC SKILL", "misc-skill.module.luau"),
        ("SKILL BURST", "skill-burst.module.luau"),
        ("AUTO RANGE", "auto-range.module.luau"),
        ("AUTO OFFSET", "auto-offset.module.luau"),
        ("ARENA FLOAT", "arena-float.module.luau"),
        ("LOBBY PLAY", "lobby-play.module.luau"),
        ("SAFE MODE", "safe-mode.module.luau"),
        ("ACCOUNT PROGRESSION", "account-progression.module.luau"),
        ("PROGRESSION GEAR", "progression-gear.module.luau"),
        ("PROGRESSION CLIENT", "progression-client.module.luau"),
        ("FARM NOCLIP", "farm-noclip.module.luau"),
        ("BLOCK CONFIRM", "block-confirm.module.luau"),
        ("BLOCK INPUT", "block-input.module.luau"),
        ("STORAGE BOOTSTRAP", "storage-bootstrap.module.luau"),
    ]:
        actual = script.split(f"-- BEGIN BUNDLED {marker}\n", 1)[1].split(
            f"-- END BUNDLED {marker}", 1)[0]
        assert actual == read(name) + "\n", f"Stale bundle: {name}"

    destroy_start = script.index("function state.Destroy(replacing, teleportCleanup)")
    destroy = script[destroy_start:script.index("bind(toggle.Activated,", destroy_start)]
    swing = script[script.index("local swingThread\n"):script.index(
        "\ndo\n    local create=(function()\n-- BEGIN BUNDLED SKILL ACTIVATION")]
    sources = {"HUD": read("enemy-health.module.luau"), "Travel": read("arena-travel.module.luau"),
               "Destroy": destroy, "Adapter": read("server-isolation-client.module.luau"),
               "Friend": read("auto-join-friend.module.luau"), "Owner": read("runtime-owner.module.luau")}
    wave = read("wave-dodge.module.luau")
    idle_start = wave.index("    function api.Idle(anchor)")
    sources["Idle"] = wave[idle_start:wave.index("    function api.Destroy()", idle_start)]
    fixture = "local sources={" + ",".join(k + "=" + quote(v) for k, v in sources.items()) + "}\n"
    fixture += "assert(loadstring(" + quote(read("mobile-regression.test.luau")) + "))()(sources)\n"
    fixture += "local result=assert(loadstring(" + quote(read("continuous-swing.test.luau")) + "))()(" + quote(swing) + ")\n"
    fixture += 'assert(result.Passed)\nprint("PASS Normal swing cadence")\n'
    encounter_start = script.index("function state.ReadAutomationEncounter(spot)")
    encounter = script[encounter_start:script.index("function state.RegisterAutomationDestination", encounter_start)]
    valid_start = script.index("local function validMob(mob, mobs)")
    valid = script[valid_start:script.index("local function pauseHold", valid_start)] + "\nreturn validMob"
    fixture += "assert(loadstring(" + quote(read("arena-clear.test.luau")) + "))()(" + quote(encounter) + "," + quote(valid) + ")\n"
    fixture += "assert(loadstring(" + quote(read("atheon-dodge.test.luau")) + "))()(" + quote(read("atheon-dodge.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("ground-follow.test.luau")) + "))()(" + quote(read("ground-follow.module.luau")) + ")\n"
    fixture += "local misc=assert(loadstring(" + quote(read("misc-skill.test.luau")) + "))()(" + quote(read("misc-skill.module.luau")) + ")\nassert(misc.Passed)\nprint('PASS Combat-only Cursed Enhancement and support skills')\n"
    activity_start = script.index("function state.IsAttackingEnemy()")
    activity = script[activity_start:script.index("local function pauseHold", activity_start)]
    fixture += "assert(loadstring(" + quote(read("combat-activity.test.luau")) + "))()(" + quote(activity) + ")\n"
    fixture += "assert(loadstring(" + quote(read("skill-burst-timing.test.luau")) + "))()(" + quote(read("skill-burst.module.luau")) + ")\n"
    payload_start = script.index("local function settingsPayload()")
    payload = script[payload_start:script.index("function state.SaveNow()", payload_start)]
    fixture += "assert(loadstring(" + quote(read("above-below.test.luau")) + "))()(" + ",".join(quote(v) for v in (read("auto-range.module.luau"), read("auto-offset.module.luau"), script, payload)) + ")\n"
    arrival_start = script.index("function state.FinishMultiSpotArrival()")
    arrival = script[arrival_start:script.index("function state.TeleportToDestination", arrival_start)]
    fixture += "assert(loadstring(" + quote(read("arena-float.test.luau")) + "))()(" + quote(read("arena-float.module.luau")) + "," + quote(arrival) + ")\n"
    fixture += "assert(loadstring(" + quote(read("lobby-play.test.luau")) + "))()(" + quote(read("lobby-play.module.luau")) + ")\n"
    for name in ("account-progression", "progression-gear"):
        fixture += "assert(loadstring(" + quote(read(name + ".test.luau")) + "))()(" + quote(read(name + ".module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("progression-client.test.luau")) + "))()(" + ",".join(quote(read(name)) for name in ("progression-client.module.luau", "account-progression.module.luau", "progression-gear.module.luau")) + "," + quote(payload) + ")\n"
    save_start = script.index("function state.SaveNow()")
    save = script[save_start:script.index("requestSave = function()", save_start)]
    fixture += "assert(loadstring(" + quote(read("storage-bootstrap.test.luau")) + "))()(" + ",".join(quote(value) for value in (read("storage-bootstrap.module.luau"), script, read("kill-aura.luau"), save)) + ")\n"
    fixture += "assert(loadstring(" + quote(read("block-input.test.luau")) + "))()(" + quote(read("block-input.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("block-confirm.test.luau")) + "))()(" + quote(read("block-confirm.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("farm-noclip.test.luau")) + "))()(" + quote(read("farm-noclip.module.luau")) + ")\n"
    adapter = read("server-isolation-client.module.luau")
    floor_start = adapter.index("    function state.ChangeAutomationFloor(placeId)")
    floor = adapter[floor_start:adapter.index("    local api=ctx.Make({", floor_start)]
    fixture += "assert(loadstring(" + quote(read("floor-transition.test.luau")) + "))()(" + quote(floor) + ")\n"
    destination_start = script.index("function state.RegisterAutomationDestination(spot)")
    destination = script[destination_start:script.index("travelHeading.Text", destination_start)]
    fixture += "assert(loadstring(" + quote(read("progression-destination.test.luau")) + "))()(" + quote(destination) + ")\n"
    fixture += "assert(loadstring(" + quote(read("moderator-watch.test.luau")) + "))()(" + quote(read("moderator-watch.module.luau")) + ")\n"
    native_start = adapter.index("    local blockBusy=false")
    native = adapter[native_start:adapter.index("    local queuedToken", native_start)]
    fixture += "assert(loadstring(" + quote(read("native-block.test.luau")) + "))()(" + quote(native) + ")\n"
    ownership = script[script.index("local previousRuntime="):script.index("local BUILD=")]
    fixture += "assert(loadstring(" + quote(read("account-settings.test.luau")) + "))()(" + quote(ownership) + ")\n"
    fixture += "assert(loadstring(" + quote(read("shared-settings.test.luau")) + "))()(" + quote(read("shared-settings.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("frame-timing.test.luau")) + "))()(" + quote(read("frame-timing.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("moderator-rejoin.test.luau")) + "))()(" + quote(read("moderator-rejoin.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("auto-join-friend.test.luau")) + "))()(" + quote(read("auto-join-friend.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("restart-script.test.luau")) + "))()(" + quote(read("restart-script.module.luau")) + ")\n"
    lua = shutil.which("lua")
    if not lua:
        raise SystemExit("Lua 5.1+ is required for the automation/isolation fixtures")
    for name in ("automation.test.lua", "server-isolation.test.lua"):
        subprocess.run([lua, name], check=True)
    with tempfile.TemporaryDirectory(prefix="sb2-offline-") as temp:
        fixture_file = Path(temp) / "regressions.luau"
        fixture_file.write_text(fixture, encoding="utf-8")
        subprocess.run([tool("luau"), str(fixture_file)], check=True)
    subprocess.run([tool("luau-compile"), "--null", "kill-aura.luau",
                    "kill-aura.body.luau", "storage-bootstrap.module.luau",
                    "enemy-health.module.luau", "arena-travel.module.luau",
                    "multi-spot.module.luau", "server-isolation-client.module.luau", "runtime-owner.module.luau",
                    "atheon-dodge.module.luau", "wave-dodge.module.luau", "ground-follow.module.luau", "misc-skill.module.luau", "auto-range.module.luau", "auto-offset.module.luau", "arena-float.module.luau", "account-progression.module.luau",
                    "progression-gear.module.luau", "progression-client.module.luau"], check=True)
    print("PASS Bundled source consistency and compile")


if __name__ == "__main__":
    main()
