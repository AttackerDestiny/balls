-- Fetch the current standalone entry; it installs its own rejoin source locally.
local url="https://raw.githubusercontent.com/AttackerDestiny/balls/main/kill-aura.luau"
local source=game:HttpGet(url.."?t="..tostring(os.time()))
local run,reason=loadstring(source,"balls")
assert(run,reason)
return run()
