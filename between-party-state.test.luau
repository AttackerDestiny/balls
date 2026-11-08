return function(source,retrySource,nativeInstances)
    local owned={}
    local function character(humanoidHP,combatHP)
        if nativeInstances then
            local model=Instance.new("Model");owned[#owned+1]=model
            if humanoidHP~=nil then local h=Instance.new("Humanoid");h.Health=humanoidHP;h.Parent=model end
            if combatHP~=nil then
                local entity=Instance.new("Folder");entity.Name="Entity";entity.Parent=model
                local h=Instance.new("NumberValue");h.Name="Health";h.Value=combatHP;h.Parent=entity
            end
            return model
        end
        return {FindFirstChildOfClass=function()return humanoidHP~=nil and {Health=humanoidHP}or nil end,
            FindFirstChild=function(_,key)
                if key=="Entity"and combatHP~=nil then return {FindFirstChild=function()return {Value=combatHP}end}end
            end}
    end
    local function person(name,humanoidHP,combatHP,loaded,revive,lives)
        local attrs={ClientLoaded=loaded,ReviveState=revive,Lives=lives}
        return {Name=name,Character=character(humanoidHP,combatHP),Attrs=attrs,GetAttribute=function(_,key)return attrs[key]end}
    end
    local passed,result=pcall(function()
        local at=0
        local host=person("Host",nil,nil,true,true,0)
        local placeholder=person("Placeholder",100,nil,nil,nil,0)
        local stale=person("StaleHealth",0,640860,true,true,0)
        local roster={host,placeholder,stale}
        local state={}
        local chunk=assert(loadstring(source.."\nreturn partyDefeated"))
        setfenv(chunk,setmetatable({state=state,os={clock=function()return at end},
            Players={GetPlayers=function()return roster end}},{__index=getfenv()}))
        local defeated=chunk()
        assert(not defeated()and state.BetweenRetryBlocker:find("Placeholder",1,true),"Loading placeholders get a grace period")
        at=5
        assert(defeated()and not state.BetweenRetryBlocker,"Default Humanoid HP without combat data must not block a confirmed party wipe forever")
        local retry=assert(loadstring(retrySource))()({Wave=function()return 34,9 end,PartyDefeated=defeated,
            Chests=function()return {},9 end,IsChest=function()return false end})
        assert(not retry.Update(at),"Preserve the stable wipe confirmation after excluding an unloaded avatar")
        placeholder.Character=character(100,500);placeholder.Attrs.ClientLoaded=true
        at=5.5
        assert(not retry.Update(at)and state.BetweenRetryBlocker:find("Living combatant",1,true),"A fully loaded survivor cancels pending wipe confirmation")
        placeholder.Character=character(0,0);placeholder.Attrs.ReviveState=true;at=6
        assert(not retry.Update(at));at=7
        assert(retry.Update(at)=="Wipe","Retry after a real stable wipe, including stale positive health on a dead Humanoid")

        placeholder.Character=character(100,nil);placeholder.Attrs.ClientLoaded=true;placeholder.Attrs.ReviveState=nil
        assert(not defeated()and state.BetweenRetryBlocker:find("confirmation",1,true),"Missing health on a loaded player remains unknown, never assumed dead")
        placeholder.Character=character(100,500);placeholder.Attrs.ReviveState=true
        assert(not defeated(),"A real living combatant overrides a stale revive flag")
        placeholder.Character=character(0,0);placeholder.Attrs.Lives=1
        assert(not defeated(),"Free lives must be exhausted before retry")
        placeholder.Attrs.Lives=nil
        assert(not defeated(),"Unknown life counts cannot confirm a wipe")
        placeholder.Attrs.Lives=0/0
        assert(not defeated(),"Invalid life counts cannot confirm a wipe")
        placeholder.Attrs.Lives=0;placeholder.Character=character(nil,nil);placeholder.Attrs.ReviveState=true
        assert(defeated(),"Confirmed revive-state players remain defeated when their bodies are gone")
        roster={};assert(not defeated(),"An empty roster is not a defeated party")
        local loading=person("InitialLoad",100,nil,nil,nil,0);roster={loading};at=10
        assert(not defeated());at=20
        assert(not defeated(),"An initial room full of placeholders needs actual defeat evidence")
        roster={host,loading};assert(defeated(),"An expired placeholder wait is compatible with an observed defeated participant")
        return {Passed=true,Placeholders=true,SurvivorGuard=true,Revives=true,StableWipe=true,Native=nativeInstances==true}
    end)
    for _,object in ipairs(owned)do object:Destroy()end
    assert(passed,result)
    print("PASS Between party wipe: unloaded Humanoid, native combat health, life guards, revival cancellation and loading grace")
    return result
end
