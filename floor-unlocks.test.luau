return function(unlockSource,selectionSource,uiSource)
    local F7,F8,F9=582198062,548878321,573267292
    local function signal()
        local event={Listeners={}}
        function event.Connect(fn)table.insert(event.Listeners,fn)end
        function event.Fire()for _,fn in ipairs(event.Listeners)do fn()end end
        return event
    end
    local function load(source,env)
        local fn=assert(loadstring(source))
        setfenv(fn,setmetatable(env or {},{__index=getfenv()}));return fn()
    end
    local state={UI={},MultiSpotSelected={},FloorDestinations={},SafeFloorId=F7}
    local owned={}
    local locations={ChildAdded=signal(),ChildRemoved=signal()}
    function locations:FindFirstChild(id)return owned[id]end
    local profile={FindFirstChild=function(_,name)if name=="Locations"then return locations end end}
    local game={PlaceId=F7,ReplicatedStorage={Profiles={FindFirstChild=function()return profile end},Database={Locations={}}}}
    local definitions={{PlaceId=F7,Name="Entoloma Gloomlands"},{PlaceId=F8,Name="Blooming Plateau"},
        {PlaceId=F9,Name="Va' Rok"},{PlaceId=542351431,Name="Virhst Woodlands",Unlocked=true}}
    local ctx={Bind=function(event,fn)event.Connect(fn)end,MakeCatalog=function(args)
        local catalog={Floors={},FloorById={},Spots={},SpotById={},Aliases={}}
        for _,floor in ipairs(args.Floors)do
            local item={Id=floor.PlaceId,Label=floor.Name,Unlocked=args.Unlocked(floor)}
            table.insert(catalog.Floors,item);catalog.FloorById[item.Id]=item
        end
        function catalog.AddCurrent()end;function catalog.Sort()end
        function catalog.NormalizeSelection(value)return value end
        return catalog
    end}
    local setup=load(unlockSource.."\nreturn {SetUI=function(value)ui=value end}",{
        ctx=ctx,state=state,player={Name="Me"},game=game,require=function()return {floors=definitions}end})
    local catalog=state.AutomationCatalog
    local saves,resets=0,0
    state.SaveNow=function()saves+=1 end
    local reset={Reset=function()resets+=1 end}
    load(selectionSource,{state=state,game=game,catalog=catalog,safe=reset,multi=reset,refresh=function()state.RefreshAutomationUI()end})
    assert(not state.IsAutomationFloorUnlocked(F8)and state.IsAutomationFloorUnlocked(F7))
    assert(state.IsAutomationFloorUnlocked(542351431)and not state.IsAutomationFloorUnlocked(123))
    local objects,created={},0
    local function create(class,props,parent)
        local item={Class=class,Children={},Activated=signal(),FocusLost=signal()}
        for key,value in pairs(props)do item[key]=value end
        function item:GetChildren()return table.clone(item.Children)end
        function item:IsA(kind)return kind=="GuiButton"and self.Class=="TextButton"end
        function item:Destroy()self.Dead=true end
        if parent then table.insert(parent.Children,item)end
        if item.Name then objects[item.Name]=item end
        created+=1;return item
    end
    local enum=setmetatable({},{__index=function()return setmetatable({},{__index=function(_,key)return key end})end})
    local function dimension()return {}end
    local makeUI=load(uiSource,{game=game,Enum=enum,Color3={fromRGB=dimension},UDim2={new=dimension},UDim={new=dimension}})
    local ui=makeUI({State=state,Catalog=catalog,Create=create,Parent={Children={}},Bind=ctx.Bind,
        Button=function(name,text,order,height,parent)return create("TextButton",{Name=name,Text=text},parent)end,
        Label=function(name,text)return create("TextLabel",{Name=name,Text=text})end,Corner=function()end,Reveal=function()end})
    setup.SetUI(ui)
    objects.SafeFloor.Activated.Fire()
    local button=objects.SafeFloor2
    assert(button.Text:find("locked",1,true),"F8 must initially show locked")
    local before=created
    owned[tostring(F8)]={};locations.ChildAdded.Fire()
    assert(catalog.FloorById[F8].Unlocked and not button.Text:find("locked",1,true),"An already-open list must show a new unlock")
    assert(created==before and objects.SafeFloor2==button,"Unlock events must update existing buttons without rebuilding the UI")
    button.Activated.Fire()
    assert(state.SafeFloorId==F8 and saves==1 and resets==2,"Newly unlocked F8 must be selectable without restart")
    assert(not state.SetSafeFloor(F9)and state.SafeFloorId==F8,"A genuinely locked floor remains unavailable")
    owned[tostring(F8)]=nil;locations.ChildRemoved.Fire()
    assert(not catalog.FloorById[F8].Unlocked and not state.SetSafeFloor(F8),"A cached true flag cannot bypass the native unlock data")
    owned[tostring(F8)]={}
    objects.SafeFloor.Activated.Fire()
    assert(not objects.SafeFloor2.Text:find("locked",1,true),"Opening the list rechecks native data even without an event")
    owned[tostring(F9)]={}
    assert(state.SetSafeFloor(F9),"Selection independently rechecks an unlock that arrived after the list was built")
    local oldProfile=profile
    profile={FindFirstChild=function()return {FindFirstChild=function()return nil end}end}
    assert(not state.IsAutomationFloorUnlocked(F8),"Reads must use the current account profile instead of a stale profile reference")
    profile=oldProfile
    before=created
    for _=1,100 do state.RefreshAutomationUI()end
    assert(created==before,"Normal UI refreshes must not rebuild dropdown buttons")
    print("PASS Live floor unlocks: F8 unlock, open-list labels, selection, locked floors, current floor, profile refresh and bounded UI updates")
end
