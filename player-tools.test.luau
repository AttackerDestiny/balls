return function(moduleSource)
    local create=assert(loadstring(moduleSource))()
    local holder=Instance.new("Folder")
    local function event() return Instance.new("BindableEvent",holder) end
    local joined,left,cameraChanged,ownSpawn,targetSpawn=event(),event(),event(),event(),event()
    local ownCharacter=Instance.new("Model",holder)
    local ownHumanoid=Instance.new("Humanoid",ownCharacter)
    local targetCharacter=Instance.new("Model",holder)
    local targetHumanoid=Instance.new("Humanoid",targetCharacter)
    local camera=Instance.new("Camera",holder)
    camera.CameraType=Enum.CameraType.Custom; camera.CameraSubject=ownHumanoid
    local players={PlayerAdded=joined.Event,PlayerRemoving=left.Event}
    local own={UserId=1,Name="Own",DisplayName="Own",Character=ownCharacter,CharacterAdded=ownSpawn.Event,Parent=players}
    local target={UserId=2,Name="Other",DisplayName="Visible Name",Character=targetCharacter,CharacterAdded=targetSpawn.Event,Parent=players}
    function players:GetPlayers() return {own,target} end
    function players:GetPlayerByUserId(id) return id==2 and target or id==1 and own or nil end
    local profiles=Instance.new("Folder",holder)
    local profile=Instance.new("Folder",profiles); profile.Name="Other"
    local inventory=Instance.new("Folder",profile); inventory.Name="Inventory"
    for id=1,2 do local item=Instance.new("IntValue",inventory); item.Name="Steel Longsword"; item.Value=id*1000 end
    local state={StopEverything=false}
    local teleports,updates=0,0
    local api=create({State=state,Players=players,LocalPlayer=own,Profiles=profiles,
        Workspace={CurrentCamera=camera,GetPropertyChangedSignal=function() return cameraChanged.Event end},
        Teleport=function() teleports+=1; return true end,Changed=function() end,RosterChanged=function() end,
        Inventory=function() updates+=1 end,
    })
    local ok,result=pcall(function()
        assert(#api.Choices()==1 and not api.Select(1),"Exclude self from the player selector")
        assert(api.Select(2) and state.SelectedPlayerId==2,"Select by stable UserId")
        assert(api.SetViewing(true) and camera.CameraSubject==targetHumanoid,"View selected player's humanoid")
        api.SetViewing(false)
        assert(camera.CameraSubject==ownHumanoid,"Restore the local camera")
        local rows=api.InventoryRows()
        assert(#rows==1 and rows[1].Count==2,"Group inventory items by their entries, not their numeric unique IDs")
        assert(api.SetInventoryVisible(true) and updates>0,"Render inventory without replacing native inventory data")
        assert(api.Teleport() and teleports==1,"Teleport must use the selected player")
        state.StopEverything=true
        assert(not api.Teleport() and not api.SetViewing(true) and not api.SetInventoryVisible(true),"Master pause must block every player action")
        state.StopEverything=false
        api.SetViewing(true)
        left:Fire(target); task.wait(.03)
        assert(state.SelectedPlayerId==nil and not api.Viewing and not api.InventoryVisible and camera.CameraSubject==ownHumanoid,"Leaving players must release camera/inventory state")
        camera.CameraType=Enum.CameraType.Scriptable
        api.Destroy()
        assert(camera.CameraType==Enum.CameraType.Scriptable,"Destroying an unused viewer must not overwrite the game's camera mode")
        return {Passed=true,CameraRestored=true,InventoryReadOnly=true,PauseRespected=true,DepartureHandled=true}
    end)
    api.Destroy(); holder:Destroy()
    if not ok then error(result) end
    return result
end
