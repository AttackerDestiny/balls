return function(source)
    local function run(running,current,alive)
        local token={}
        local state={Running=running}
        local panel={Visible=false};local show={Visible=true}
        local warned=false
        local fn=assert(loadstring(source))
        setfenv(fn,setmetatable({ok=false,result="UI initialization cancelled",state=state,
            env={SB2LoadToken=current and token or {}},loadToken=token,runtimeOwner={Alive=function()return alive end},
            roots=function()end,library=nil,parent={GetChildren=function()return {}end},before={},ownedNames={},
            panel=panel,showUI=show,warn=function()warned=true end},{__index=getfenv()}))
        fn()
        return panel.Visible,warned
    end
    assert(not run(false,true,true),"A stopped runtime must not display its compatibility panel")
    assert(not run(true,false,true),"A superseded load cannot resurrect old UI")
    assert(not run(true,true,false),"A retired GUI owner cannot display fallback")
    local visible,warned=run(true,true,true)
    assert(not visible and warned,"A current live initialization failure must never display compatibility UI")
    print("PASS Modern UI only: cancelled, superseded and failed initialization never display the legacy panel")
end
