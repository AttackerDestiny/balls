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
    import hashlib
    assert hashlib.sha256((root / "vendor/WindUI-1.6.66.lua").read_bytes()).hexdigest() == "125b5dc3e5f02baf8008504879eef517ca29405c21255497e84da696fac51fc7", "WindUI release asset changed"
    assert script.index("-- WindUI is bundled at a fixed release") > script.index("function state.GetTradeItemChoices()"), "Initialize WindUI after all controllers and settings are ready"
    for marker, name in [
        ("WEAPON SKILLS", "weapon-skills.module.luau"),
        ("ANIMATION REMOVAL", "animation-removal.module.luau"),
        ("RUNTIME RECOVERY", "runtime-recovery.module.luau"),
        ("MAP DELETION", "map-deletion.module.luau"),
        ("PERFORMANCE BOOST", "performance-boost.module.luau"),
        ("PERFORMANCE BUDGET", "performance-budget.module.luau"),
        ("CREDIT DAMAGE PLAN", "credit-damage-plan.module.luau"),
        ("CREDIT ROSTER", "credit-roster.module.luau"),
        ("CREDIT CHECK", "credit-check.module.luau"),
        ("FARM COORDINATION", "farm-coordination.module.luau"),
        ("RESPAWN SCHEDULE", "respawn-schedule.module.luau"),
        ("STARTUP BELOW", "startup-below.module.luau"),
        ("AUTO QUEST", "auto-quest.module.luau"),
        ("AUTO CRAFT", "auto-craft.module.luau"),
        ("INVENTORY VIEW", "inventory-view.module.luau"),
        ("PLAYER TOOLS", "player-tools.module.luau"),
        ("MULTI SPOT HUD", "multi-spot-hud.module.luau"),
        ("WINDUI", "windui.module.luau"),
        ("ANTI AFK", "anti-afk.module.luau"),
        ("TARGET PRIORITY", "target-priority.module.luau"),
        ("ATTACK SCHEDULER", "attack-scheduler.module.luau"),
        ("SKILL ACTIVATION", "skill-activation.module.luau"),
        ("AURA TOUCH", "aura-touch.module.luau"),
        ("SERVER ISOLATION", "server-isolation.module.luau"),
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
    replacement_start=script.index("if previousRuntime and previousRuntime.Destroy then")
    replacement=script[replacement_start:script.index("if env.SB2FarmRecoveryUntil",replacement_start)]
    fixture += "assert(loadstring(" + quote(read("replacement-failure.test.luau")) + "))()(" + quote(replacement) + ")\n"
    fallback_start=script.index("    if not ok and state.Running and env.SB2LoadToken==loadToken")
    fallback=script[fallback_start:script.index("-- Independent status overlay",fallback_start)]
    fallback=fallback[:fallback.rfind("end")]
    fixture += "assert(loadstring(" + quote(read("cancelled-ui-fallback.test.luau")) + "))()(" + quote(fallback) + ")\n"
    fixture += "local result=assert(loadstring(" + quote(read("continuous-swing.test.luau")) + "))()(" + quote(swing) + ")\n"
    fixture += 'assert(result.Passed)\nprint("PASS Normal swing cadence")\n'
    fixed_start = script.index("function state.ResolveAutoOffset(mob)")
    fixed = script[fixed_start:script.index("    local now,mobRoot=os.clock(),data.Root", fixed_start)] + '\nreturn "default"\nend'
    fixture += "assert(loadstring(" + quote(read("unborn-position.test.luau")) + "))()(" + quote(fixed) + ")\n"
    encounter_start = script.index("function state.ReadAutomationEncounter(spot)")
    encounter = script[encounter_start:script.index("function state.RegisterAutomationDestination", encounter_start)]
    valid_start = script.index("local function validMob(mob, mobs)")
    valid = script[valid_start:script.index("local function pauseHold", valid_start)] + "\nreturn validMob"
    fixture += "assert(loadstring(" + quote(read("arena-clear.test.luau")) + "))()(" + quote(encounter) + "," + quote(valid) + ")\n"
    data_start = script.index("local function getMobData(mob)")
    data = script[data_start:script.index("function state.ReadOwnDamage", data_start)]
    farm_start = script.index("    if now>=nextAcquisition and")
    farm_selection = script[farm_start:script.index("    if not targetRoot then", farm_start)]
    # The arena fixture needs validMob returned; the selection fixture embeds its definition.
    valid_definition = valid.removesuffix("\nreturn validMob")
    fixture += "assert(loadstring(" + quote(read("farm-sync.test.luau")) + "))()(" + ",".join(quote(value) for value in (read("target-priority.module.luau"), data, valid_definition, farm_selection, read("credit-check.module.luau"))) + ")\n"
    fixture += "assert(loadstring(" + quote(read("map-deletion.test.luau")) + "))()(" + quote(read("map-deletion.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("animation-removal.test.luau")) + "))()(" + quote(read("animation-removal.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("ui-memory.test.luau")) + "))()(" + quote(read("ui-memory.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("runtime-recovery.test.luau")) + "))()(" + quote(read("runtime-recovery.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("atheon-dodge.test.luau")) + "))()(" + quote(read("atheon-dodge.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("ground-follow.test.luau")) + "))()(" + quote(read("ground-follow.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("weapon-skills.test.luau")) + "))()(" + quote(read("weapon-skills.module.luau")) + ")\n"
    fixture += "local misc=assert(loadstring(" + quote(read("misc-skill.test.luau")) + "))()(" + quote(read("misc-skill.module.luau")) + ")\nassert(misc.Passed)\nprint('PASS Combat-only Cursed Enhancement and support skills')\n"
    activity_start = script.index("function state.IsAttackingEnemy()")
    activity = script[activity_start:script.index("local function pauseHold", activity_start)]
    fixture += "assert(loadstring(" + quote(read("combat-activity.test.luau")) + "))()(" + quote(activity) + ")\n"
    fixture += "assert(loadstring(" + quote(read("skill-burst-timing.test.luau")) + "))()(" + quote(read("skill-burst.module.luau")) + ")\n"
    skill_start = script.index("local function updateSkillAura()")
    skill_update = script[skill_start:script.index("\n\ndo\n", skill_start)]
    fixture += "assert(loadstring(" + quote(read("source-combat.test.luau")) + "))()(" + ",".join(quote(value) for value in (read("attack-scheduler.module.luau"), read("skill-burst.module.luau"), read("skill-activation.module.luau"), read("skill-damage-budget.module.luau"), skill_update)) + ")\n"
    fixture += "assert(loadstring(" + quote(read("aura-touch.test.luau")) + "))()(" + quote(read("aura-touch.module.luau")) + ")\n"
    stream_start=script.index("    local pendingParts,queuedParts=")
    stream_budget=script[stream_start:script.index("    bind(workspace.DescendantRemoving",stream_start)]
    fixture += "assert(loadstring(" + quote(read("map-stream-budget.test.luau")) + "))()(" + quote(stream_budget) + ")\n"
    gate_start = script.index('    if state.FarmCoordination and not state.DodgeReturnPending')
    movement_gate = script[gate_start:script.index('    local destination = state.AutoOffsetDestination or targetRoot.Position', gate_start)]
    fixture += "assert(loadstring(" + quote(read("fps-budget.test.luau")) + "))()(" + quote(read("farm-coordination.module.luau")) + "," + quote(movement_gate) + ")\n"
    move_adapter = read("server-isolation-client.module.luau")
    can_move = move_adapter[move_adapter.index("        CanMove=function()")+len("        CanMove="):move_adapter.index("        Moving=function()")].strip().removesuffix(",")
    fixture += "assert(loadstring(" + quote(read("farm-coordination.test.luau")) + "))()(" + quote(read("farm-coordination.module.luau")) + "," + quote(can_move) + ")\n"
    fixture += "assert(loadstring(" + quote(read("performance-budget.test.luau")) + "))()(" + quote(read("performance-budget.module.luau")) + ")\n"
    cleanup_start = script.index("local function clearStaleFarmControllers(root)")
    cleanup = script[cleanup_start:script.index("local function ensureMovementController", cleanup_start)]
    fixture += "assert(loadstring(" + quote(read("farm-hold-cleanup.test.luau")) + "))()(" + quote(cleanup) + ")\n"
    fixture += "assert(loadstring(" + quote(read("respawn-schedule.test.luau")) + "))()(" + quote(read("respawn-schedule.module.luau")) + "," + quote(read("multi-spot.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("startup-below.test.luau")) + "))()(" + quote(read("startup-below.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("anti-afk.test.luau")) + "))()(" + quote(read("anti-afk.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("credit-roster.test.luau")) + "))()(" + quote(read("credit-roster.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("credit-damage-plan.test.luau")) + "))()(" + quote(read("credit-damage-plan.module.luau")) + "," + quote(read("credit-check.module.luau")) + ")\n"
    credit_send_start=script.index("                Send=function(mob,entry)")+len("                Send=")
    credit_send=script[credit_send_start:script.index("\n                end,",credit_send_start)]+"\nend"
    fixture += "assert(loadstring(" + quote(read("credit-check.test.luau")) + "))()(" + quote(read("credit-check.module.luau")) + "," + quote(read("attack-scheduler.module.luau")) + "," + quote(credit_send) + ")\n"
    fixture += "assert(loadstring(" + quote(read("config-transfer.test.luau")) + "))()(" + quote(read("config-transfer.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("windui.test.luau")) + "))()(" + quote(read("windui.module.luau")) + ")\n"
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
    order_adapter = adapter[adapter.index("    local function spotOrder("):adapter.index("    local function joinFriendAtPad(")]
    fixture += "assert(loadstring(" + quote(read("multi-order.test.luau")) + "))()(" + quote(order_adapter) + ")\n"
    preflight = adapter[adapter.index("    local function queuePreflight()"):adapter.index("    local function preflight()")]
    fixture += "assert(loadstring(" + quote(read("safe-preflight.test.luau")) + "))()(" + quote(preflight) + ")\n"
    unlock_start = adapter.index("    local ui\n")
    unlock = adapter[unlock_start:adapter.index("    local function snapshot()", unlock_start)]
    selection_start = adapter.index("    function state.SetSafeFloor(id)")
    selection = adapter[selection_start:adapter.index("    local whitelistGeneration", selection_start)]
    fixture += "assert(loadstring(" + quote(read("floor-unlocks.test.luau")) + "))()(" + ",".join(quote(value) for value in (unlock, selection, read("automation-ui.module.luau"))) + ")\n"
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
    visual = read("skill-visuals.module.luau")
    suppress = visual[visual.index("    local function write("):visual.index("    local function isSkill(")]
    fixture += "assert(loadstring(" + quote(read("mobile-skill-visuals.test.luau")) + "))()(" + quote(suppress) + ")\n"
    friend_pad = adapter[adapter.index("    local function joinFriendAtPad("):adapter.index("    local friend=ctx.MakeFriend(")]
    fixture += "assert(loadstring(" + quote(read("friend-join-pad.test.luau")) + "))()(" + quote(friend_pad) + ")\n"
    maintenance = visual[visual.index("    function api.ProcessManaged()"):visual.index("    function api.Update()")]
    fixture += "assert(loadstring(" + quote(read("visual-budget.test.luau")) + "))()(" + quote(maintenance) + ")\n"
    fixture += "assert(loadstring(" + quote(read("auto-dismantle.test.luau")) + "))()(" + quote(read("auto-dismantle.module.luau")) + ")\n"
    protection_start=script.index("    local function protected(item)")
    protection=script[protection_start:script.index("    local worker=make(",protection_start)]
    fixture += "assert(loadstring(" + quote(read("dismantle-protection.test.luau")) + "))()(" + quote(protection) + ")\n"
    fixture += "assert(loadstring(" + quote(read("auto-trade.test.luau")) + "))()(" + quote(read("auto-trade.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("trade-hold.test.luau")) + "))()(" + quote(read("trade-hold.module.luau")) + ")\n"
    plan_start=script.index("    local function plan()")
    trade_plan=script[plan_start:script.index("    local nativeTrade=",plan_start)]
    fixture += "assert(loadstring(" + quote(read("auto-trade-plan.test.luau")) + "))()(" + quote(trade_plan) + "," + quote(read("auto-trade.module.luau")) + ")\n"
    away_start=script.index("function state.EscapeSafeRejoin()")
    away=script[away_start:script.index("function state.ReleaseSafePanic()",away_start)]
    fixture += "assert(loadstring(" + quote(read("safe-rejoin-away.test.luau")) + "))()(" + quote(away) + ")\n"
    helper_start=adapter.index("    local function clearRejoinAway()")
    away_helpers=adapter[helper_start:adapter.index("    local function fail(",helper_start)]
    hop_start=adapter.index("        Hop=function()")
    hop=adapter[hop_start:adapter.index("        Notify=function",hop_start)]
    fixture += "assert(loadstring(" + quote(read("safe-rejoin-order.test.luau")) + "))()(" + quote(away_helpers) + "," + quote(hop) + ")\n"
    fixture += "assert(loadstring(" + quote(read("safe-kick-fallback.test.luau")) + "))()(" + quote(read("safe-kick-fallback.module.luau")) + ")\n"
    panic_start=script.index("function state.PanicToSpawn(")
    panic_end=script.index("\n\ndo\n",panic_start)
    fixture += "assert(loadstring(" + quote(read("safe-panic-position.test.luau")) + "))()(" + quote(script[panic_start:panic_end]) + ")\n"
    fixture += "assert(loadstring(" + quote(read("multi-spot-hud.test.luau")) + "))()(" + quote(read("multi-spot-hud.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("inventory-view.test.luau")) + "))()(" + quote(read("inventory-view.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("auto-craft.test.luau")) + "))()(" + quote(read("auto-craft.module.luau")) + ")\n"
    release_start=script.index("stopMovement = function(message, keepPosition)")
    release=script[release_start:script.index("\ndo\n",release_start)]
    fixture += "assert(loadstring(" + quote(read("movement-release.test.luau")) + "))()(" + quote(release) + ")\n"
    fixture += "assert(loadstring(" + quote(read("auto-quest.test.luau")) + "))()(" + quote(read("auto-quest.module.luau")) + ")\n"
    fixture += "assert(loadstring(" + quote(read("default-spots.test.luau")) + "))()(" + quote(read("floor-catalog.module.luau")) + ")\n"
    assert "destinations_" not in read("storage-bootstrap.module.luau")
    assert "destinationPath" not in script
    custom_start=script.index("local function saveDestinations()")
    custom_save=script[custom_start:script.index("local function rankMob",custom_start)]
    fixture += "assert(loadstring(" + quote(read("custom-spots-save.test.luau")) + "))()(" + quote(custom_save) + ")\n"
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
                    "anti-afk.module.luau",
                    "windui.module.luau", "vendor/WindUI-1.6.66.lua",
                    "attack-scheduler.module.luau", "skill-activation.module.luau", "skill-burst.module.luau", "aura-touch.module.luau",
                    "kill-aura.body.luau", "storage-bootstrap.module.luau",
                    "enemy-health.module.luau", "arena-travel.module.luau",
                    "multi-spot.module.luau", "server-isolation-client.module.luau", "runtime-owner.module.luau",
                    "atheon-dodge.module.luau", "wave-dodge.module.luau", "ground-follow.module.luau", "misc-skill.module.luau", "auto-range.module.luau", "auto-offset.module.luau", "arena-float.module.luau", "account-progression.module.luau",
                    "progression-gear.module.luau", "progression-client.module.luau"], check=True)
    print("PASS Bundled source consistency and compile")


if __name__ == "__main__":
    main()
