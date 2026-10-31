-- Runs the bundled module against isolated fixtures; never moves the real character.
return function(moduleSource)
    local fixture=Instance.new("Folder")
    local signal=Instance.new("BindableEvent")
    local hazard=Instance.new("Folder",fixture); hazard.Name="ActiveLavaHazard"
    local region=Instance.new("Part",fixture); region.Position=Vector3.new(0,100,0); region.Size=Vector3.new(400,2,400)
    local origin=Instance.new("Part",fixture); origin.Position=Vector3.new(0,99,0)
    local character=Instance.new("Model",fixture)
    local root=Instance.new("Part",character); root.Name="HumanoidRootPart"; root.Position=Vector3.new(0,110,0)
    local humanoid=Instance.new("Humanoid",character)
    local entity=Instance.new("Folder",character); entity.Name="Entity"
    local hp=Instance.new("NumberValue",entity); hp.Name="Health"; hp.Value=100
    local function rock(x,y)
        local p=Instance.new("Part",hazard); p.Name="Rock"; p.Size=Vector3.new(12,8,12); p.Position=Vector3.new(x,y,0)
        return p
    end
    local first=rock(0,100)
    local second=rock(30,97.5)
    local area="Lava"
    local mobs=Instance.new("Folder",fixture); mobs.Name="Mobs"
    local chaser=Instance.new("Model",mobs); chaser.Name="FixtureThreat"
    local chaserRoot=Instance.new("Part",chaser); chaserRoot.Name="HumanoidRootPart"; chaserRoot.Anchored=true; chaserRoot.Position=Vector3.new(0,100,0)
    local chaserEntity=Instance.new("Folder",chaser); chaserEntity.Name="Entity"
    local chaserHealth=Instance.new("NumberValue",chaserEntity); chaserHealth.Name="Health"; chaserHealth.Value=100
    local floor=Instance.new("Part",fixture); floor.Anchored=true; floor.Size=Vector3.new(400,10,400); floor.Position=Vector3.new(0,95,0)
    local lowerFloor=Instance.new("Part",fixture); lowerFloor.Anchored=true; lowerFloor.Size=Vector3.new(400,40,400); lowerFloor.Position=Vector3.new(0,60,0)
    local fakeWorkspace={FallenPartsDestroyHeight=-500,DescendantAdded=signal.Event}
    function fakeWorkspace:GetAttribute(k) return ({WaveDefenseArea=area,WaveDefenseEnvironment=area,Wave=8})[k] end
    function fakeWorkspace:FindFirstChild(k)
        if k=="Mobs" then return mobs end
        if k=="ActiveLavaHazard" then return hazard end
        if k=="WaveDefenseStuff" then return {FindFirstChild=function(_,n) return n=="LavaHazardRegion" and region or n=="WaveDefenseOrigin" and origin end} end
    end
    function fakeWorkspace:QueryDescendants() return {first,second} end
    function fakeWorkspace:Raycast(point,_,params)
        if params and params.RespectCanCollide then
            if point.Y>=100 then return {Instance=floor,Position=Vector3.new(point.X,100,point.Z),Normal=Vector3.yAxis} end
            if point.Y>=80 then return {Instance=lowerFloor,Position=Vector3.new(point.X,80,point.Z),Normal=Vector3.yAxis} end
            return nil
        end
        return {Position=point-Vector3.new(0,4,0),Normal=Vector3.yAxis}
    end
    local storage={}
    local clockShift=0
    local fakeOS=setmetatable({clock=function() return os.clock()+clockShift end},{__index=os})
    local environment=setmetatable({os=fakeOS,workspace=fakeWorkspace,game={Players={LocalPlayer={Character=character,UserId=0}},JobId="fixture",GetService=function() return game:GetService("HttpService") end},getgenv=function() return storage end,isfile=function() return false end,writefile=function() end,isfolder=function() return true end},{__index=getfenv()})
    local chunk=assert(loadstring(moduleSource)); setfenv(chunk,environment)
    local state={Running=true,AutoDodge=true}
    local api=chunk()({State=state,Hold=function() end,Release=function() end,Status=function() end})
    local ok,result=pcall(function()
        api.Update(); task.wait(.3); api.Update()
        assert(api.RockStatus.Current==nil and api.LastRockSwitch.ReplacementReady,"Initial rock must be settled")
        local initial=api.RockChanges
        second.Position=Vector3.new(30,100,0); api.Update(); task.wait(.3); api.Update()
        task.wait(1.9); api.Update()
        assert(api.RockChanges==initial,"Must not rotate just because a newer rock exists")
        second.Position=Vector3.new(30,100.3,0); first.Position=Vector3.new(0,97.8,0)
        task.wait(.05); api.Update()
        assert(api.RockChanges==initial,"Must wait while replacement is still moving")
        second.Position=Vector3.new(30,100,0); task.wait(.05); api.Update()
        task.wait(.3); api.Update()
        assert(api.RockChanges==initial+1,"Must switch when current sinks and replacement settles")
        assert(api.LastRockSwitch.ReplacementReady,"Replacement must be ready at switch")
        area="Blackout"; task.wait(.05); api.Update(); api.Idle()
        assert(state.OffsetMode=="Below" and state.IdleBelowMap and state.BlackoutShelter.Y==20,"Blackout must shelter 20 studs below the lowest slab bottom, not below its top")
        assert(state.Dodging and api.LastPosition.Y==20,"Darkness must override mob-follow movement")
        area="Darkness"; task.wait(.05); api.Update()
        assert(api.Event=="Blackout" and state.Dodging,"Recognize the darkness wave alias")
        area="Floor 1"; task.wait(.05); api.Update(); api.Idle()
        assert(state.OffsetMode=="Below" and state.IdleBelowMap,"Ordinary waves must restore below mode")
        area="Bob"; task.wait(.05); api.Update()
        local refuge=api.LastPosition
        assert(state.Dodging and refuge.Y<state.BlackoutShelter.Y and math.abs(refuge.X)<200 and math.abs(refuge.Z)<200,"Bob must hold a deep refuge inside arena bounds")
        assert(api.Seen.Bob.Moves>0,"Record actual Bob dodge movement")
        chaserRoot.Position=Vector3.new(refuge.X,100,refuge.Z); task.wait(.3); api.Update()
        assert((api.LastPosition-refuge).Magnitude>30,"Relocate when an enemy approaches the refuge")
        local priorY=api.LastPosition.Y
        hp.Value=80; task.wait(.05); api.Update()
        assert(api.LastPosition.Y<priorY,"Bob damage must trigger a deeper event-specific refuge")
        area="Floor 1"; task.wait(.05); api.Update()
        assert(state.Dodging,"Keep dodging during the Bob residual-attack grace period")
        clockShift=6; api.Update()
        assert(not state.Dodging,"Resume ordinary farming after the residual grace period")
        return {Passed=true,Switches=api.RockChanges,Reason=api.LastRockSwitch.Reason,BlackoutModeSwitch=true,BobRefuge=true,BobRelocation=true,BobResidualGrace=true}
    end)
    api.Destroy(); fixture:Destroy(); signal:Destroy()
    if not ok then error(result) end
    return result
end
