return function(source)
    local files={versioned="fixture-build",stable="different-build"}
    local queued,executed
    local me={UserId=42}
    local environment={env={SB2AutomationResumeConfigPath="SB2Codex/settings_42_shared-preset_2.json"},
        storageBootstrap={SourcePath="versioned",Ensure=function()return true end},
        isfile=function(path)return files[path]~=nil end,readfile=function(path)return files[path]end,
        queue_on_teleport=function(code)queued=code end,player=me,BUILD="fixture-build"}
    local chunk=assert(loadstring(source.."\nreturn queueLobby"))
    setfenv(chunk,setmetatable(environment,{__index=getfenv()}))
    chunk()()
    assert(queued and queued:find("versioned",1,true)and not queued:find("kill-aura.luau",1,true),
        "After a long menu rest, queue the build-specific source rather than another runtime's overwritten stable path")
    local resume={}
    local players={LocalPlayer=me}
    local gameMock={GameId=212154879,IsLoaded=function()return true end,GetService=function()return players end}
    local run=assert(loadstring(queued))
    setfenv(run,setmetatable({game=gameMock,isfile=environment.isfile,readfile=environment.readfile,
        getgenv=function()return resume end,loadstring=function(text)
            assert(text=="fixture-build");return function()executed=(executed or 0)+1 end
        end},{__index=getfenv()}))
    run()
    assert(executed==1 and resume.SB2AutomationResumeConfigPath==environment.env.SB2AutomationResumeConfigPath)
    players.LocalPlayer={UserId=99};run();assert(executed==1,"Another account cannot consume the queued menu resume")
    players.LocalPlayer=me;gameMock.GameId=1;run();assert(executed==1,"Another game cannot consume the queued resume")
    gameMock.GameId=212154879;files.versioned="wrong-build";run();assert(executed==1)
    environment.storageBootstrap.Ensure=function()return false,"Storage unavailable"end
    local rebuild=assert(loadstring(source.."\nreturn queueLobby"))
    setfenv(rebuild,setmetatable(environment,{__index=getfenv()}))
    assert(not pcall(rebuild()),"Failed resume storage must keep the Start button idle")
    print("PASS Menu resume: versioned source, build/account/game checks, saved settings path and queue preparation failure")
end
