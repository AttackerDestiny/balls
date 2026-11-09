return function(template)
    local launch=string.format(template,"config","run","false","777","entry","build","config","resume")
    local settings={Version=1,AutoRegroup=true,AutomationRunId="run",AutomationResumeFeatures={AutoFarm=true}}
    local globals={}
    local started=0
    local player={UserId=1}
    local game={GameId=777,JobId="new-server",IsLoaded=function()return true end,GetService=function(_,name)
        if name=="Players"then return {LocalPlayer=player}end
        assert(name=="HttpService")
        return {JSONDecode=function(_,text)if text=="settings"then return settings end;return {}end}
    end}
    local chunk=assert(loadstring(launch))
    setfenv(chunk,setmetatable({game=game,getgenv=function()return globals end,
        readfile=function(path)
            if path=="config"then return "settings"end
            if path=="entry"then return "-- build"end
            assert(path=="resume");return "ticket"
        end,
        loadstring=function(source)assert(source=="-- build");return function()started+=1 end end},{__index=getfenv()}))
    chunk()
    assert(started==1 and globals.SB2AutomationResumeConfigPath=="config",
        "Auto Regroup by itself must reload after returning even with Safe Mode, Multi Spot, progression and room creation OFF")
    settings.AutoRegroup=false;chunk();assert(started==1,"Unrelated disabled automation cannot authorize queued execution")
    settings.AutoRegroup=true;game.GameId=999;chunk();assert(started==1,"Queue remains scoped to the same Roblox experience")
    print("PASS Regroup-only resume: queued loader eligibility and experience/disabled safeguards")
end
