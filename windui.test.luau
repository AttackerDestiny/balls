-- Native-style WindUI doubles deliberately replay asynchronous refresh callbacks.
-- No game, remote, input, block, trade, dismantle or teleport is used.
return function(source)
    local make=assert(loadstring(source))()
    local queue,calls={},{}
    local window={CurrentTab=1,Closed=false}
    local function later(control)queue[#queue+1]=function()control.Callback(control.Value)end end
    local function flush()
        local count=0
        while #queue>0 do count+=1;assert(count<200,"UI callbacks cannot loop");table.remove(queue,1)()end
    end
    local function element(kind,opts)
        local item={Kind=kind,Title=opts.Title,Desc=opts.Desc,Value=opts.Value,Values=opts.Values,Callback=opts.Callback}
        function item:Set(value,fire)
            self.Value=value
            if fire~=false and self.Callback then later(self)end
        end
        function item:Select(value)self.Value=value;if self.Callback then later(self)end end
        function item:Refresh(values)self.Values=values;if self.Callback then later(self)end end
        function item:SetDesc(value)self.Desc=value end
        function item:Emit(value)self.Value=value;self.Callback(value)end
        if kind=="Dropdown"then later(item)end
        return item
    end
    local tabCount=0
    function window:Tab(opts)
        tabCount+=1;local index=tabCount
        local tab={Title=opts.Title}
        for _,kind in ipairs({"Button","Toggle","Input","Dropdown","Paragraph"})do
            tab[kind]=function(_,opts)return element(kind,opts)end
        end
        function tab:Select()window.CurrentTab=index end
        return tab
    end
    function window:OnOpen(fn)self.Opened=fn end
    function window:OnClose(fn)self.ClosedCallback=fn end
    function window:OnDestroy(fn)self.DestroyedCallback=fn end
    function window:Open()self.Closed=false;if self.Opened then self.Opened()end end
    function window:Close()self.Closed=true;if self.ClosedCallback then self.ClosedCallback()end end
    function window:Destroy()self.Destroyed=true;if self.DestroyedCallback then self.DestroyedCallback()end end
    local wind={CreateWindow=function(_,opts)
        assert(opts.Acrylic==false and opts.Folder=="SB2Codex/WindUI","Use the existing workspace and avoid mobile acrylic overhead")
        assert(not opts.KeySystem,"No new key system")
        return window
    end}
    local s={Running=true,Version="test",UI={ActiveTab="Main"},Enabled=true,AutoFarm=true,AutoSwing=true,
        SafeMode=true,SafeFloorId=11,SafeWhitelistText="Friend, 123",MultiSpot=true,
        MultiSpotSelected={["11/Boss"]=true,["22/Boss"]=true},AutoTrade=true,TradeMode="Legendary",TradeItems={Gem=true},
        AutoDismantle={Common=true},PerformanceBoosters={["Hide effects"]=true},
        AutoEquipBestSword=true,SelectedSkill="Summon Pistol",SkillChoices={"Summon Pistol","Beam Rush"},
        SelectedMiscSkill="Heal",MiscSkillChoices={{Name="Heal",Usable=true},{Name="Locked skill",Usable=false}},
        JoinFriendUsername="Friend",AutoJoinFriend=true,HealthVisible=true,
        FloorDestinations={A={Id="A",Kind="Boss",Name="Arena"},B={Id="B",Kind="Boss",Name="Arena"}},
        PlayerInventoryRows={{Name="Sword",Upgrade=3,Count=2}}}
    local catalog={Floors={{Id=11,Label="F1",Unlocked=true},{Id=22,Label="F2",Unlocked=false}},
        Spots={{Id="11/Boss",PlaceId=11,Name="Boss arena",Kind="Boss"},{Id="11/Mini",PlaceId=11,Name="Mini arena",Kind="Mini boss"},
            {Id="22/Boss",PlaceId=22,Name="Foreign arena",Kind="Boss"}},AddCurrent=function()end,Sort=function()end}
    s.AutomationCatalog=catalog
    local function record(name,...)calls[#calls+1]={Name=name,Args={...}}end
    for key,method in pairs({Enabled="SetEnabled",AutoFarm="SetAutoFarm",SkillAura="SetSkillAura",MiscSkillEnabled="SetMiscSkillEnabled",
        AutoSwing="SetAutoSwing",AtheonDodge="SetAtheonDodge",AutoDodge="SetAutoDodge",TransparentMap="SetTransparentMap",
        AutoEquipBestSword="SetAutoEquipBestSword",SafeMode="SetSafeMode",MultiSpot="SetMultiSpot",AutoJoinFriend="SetAutoJoinFriend",
        AccountProgression="SetAccountProgression",AutoTrade="SetAutoTrade"})do
        s[method]=function(value)record(method,value);if not s.StopEverything then s[key]=value end end
    end
    for key,method in pairs({SafeWhitelistText="SetSafeWhitelist",JoinFriendUsername="SetJoinFriendUsername",
        SelectedSkill="SetSelectedSkill",SelectedMiscSkill="SetMiscSkill",TradeMode="SetTradeMode"})do
        s[method]=function(value)record(method,value);s[key]=value end
    end
    function s.IsAutomationFloorUnlocked(id)return id==11 or catalog.Floors[2].Unlocked end
    function s.SetSafeFloor(id)record("SetSafeFloor",id);if s.IsAutomationFloorUnlocked(id)then s.SafeFloorId=id end end
    function s.SetMultiSpotSelections(value)
        record("SetMultiSpotSelections",value)
        s.MultiSpotSelected={["22/Boss"]=true};for id,on in pairs(value)do s.MultiSpotSelected[id]=on end
    end
    function s.SetAutoDismantle(name,on)record("SetAutoDismantle",name,on);s.AutoDismantle[name]=on end
    function s.SetPerformanceBoost(name,on)record("SetPerformanceBoost",name,on);s.PerformanceBoosters[name]=on end
    function s.SetTradeItems(value)record("SetTradeItems",value);s.TradeItems=value end
    local inventoryReads=0;local gemCount=64
    function s.GetTradeItemChoices()inventoryReads+=1;return {{Name="Gem",Count=gemCount},{Name="Scroll",Count=1}}end
    for _,name in ipairs({"TeleportToDestination","RefreshTeleportDestinations","SaveCurrentMiniBossArea","RestartScript","OpenGameMenu"})do
        s[name]=function(...)record(name,...)end
    end
    function s.Destroy()record("Destroy");s.Running=false end
    s.PlayerTools={Choices=function()return {{UserId=123,Name="Friend",DisplayName="Friend"}}end,
        Select=function(id)record("SelectPlayer",id);s.SelectedPlayerId=id end,
        Teleport=function()record("TeleportPlayer")end,
        SetViewing=function(on)record("SetViewing",on);s.ViewingPlayer=on end,
        SetInventoryVisible=function(on)record("SetInventoryVisible",on);s.ViewingPlayerInventory=on end}
    local visible=true
    local api=make({State=s,WindUI=wind,PlaceId=11,Visibility=function(value)visible=value end})
    local c=api.Controls
    flush();assert(tabCount==8 and #calls==0,"Loading saved ON values must not invoke setters or actions")
    for _,key in ipairs({"Enabled","AutoFarm","AutoEquipBestSword","AtheonDodge","AutoSwing","AutoDodge","TransparentMap",
        "SkillAura","SelectedSkill","MiscSkillEnabled","SelectedMiscSkill","SafeMode","SafeFloor","SafeWhitelist",
        "MultiSpot","MultiSpotAreas","AutoJoinFriend","JoinFriendUsername","RestartScript","HideUI","Unload",
        "TeleportDestination","Teleport","RefreshDestinations","SaveMiniBossArea","OpenDismantle","OpenUpgrade","OpenThe Forge",
        "SelectedPlayer","TeleportPlayer","ViewingPlayer","ViewingPlayerInventory","PlayerInventory",
        "PerformanceBoosters","AutoDismantle","AutoTrade","TradeMode","TradeItems","AccountProgression","AntiAfkStatus","ModeratorStatus"})do
        assert(c[key],"Every available feature must be present: "..key)
    end
    assert(#c.MultiSpotAreas.Values==2,"Arena dropdown contains only the current floor")
    assert(#c.SelectedMiscSkill.Values==1,"Locked support skills cannot be selected")
    c.SafeFloor:Emit("F2 · locked");assert(s.SafeFloorId==11)
    api.Update(1);flush();assert(c.SafeFloor.Value=="F1","Rejected choices must roll back to actual state")
    catalog.Floors[2].Unlocked=true;api.Update(2);flush()
    c.SafeFloor:Emit("F2");assert(s.SafeFloorId==22)
    c.MultiSpotAreas:Emit({"Mini boss · Mini arena"})
    assert(s.MultiSpotSelected["11/Mini"]and not s.MultiSpotSelected["11/Boss"]and s.MultiSpotSelected["22/Boss"])
    assert(calls[#calls].Name=="SetMultiSpotSelections","Arena changes use one batch save")
    c.PerformanceBoosters:Emit({"No damage particles"})
    assert(s.PerformanceBoosters["No damage particles"]and not s.PerformanceBoosters["Hide effects"])
    c.AutoDismantle:Emit({"Rare"});assert(s.AutoDismantle.Rare and not s.AutoDismantle.Common)
    c.TradeMode:Emit("Selected items");assert(s.TradeMode=="Selected")
    c.TradeItems:Emit({"Gem x64","Scroll x1"});assert(s.TradeItems.Gem and s.TradeItems.Scroll)
    c.SafeWhitelist:Emit("Other, 456");assert(s.SafeWhitelistText=="Other, 456")
    c.JoinFriendUsername:Emit("NewFriend");assert(s.JoinFriendUsername=="NewFriend")
    c.SelectedSkill:Emit("Beam Rush");assert(s.SelectedSkill=="Beam Rush")
    c.SelectedPlayer:Emit("Friend (@Friend)");assert(s.SelectedPlayerId==123)
    c.ViewingPlayerInventory:Emit(true);api.Update(3);flush()
    assert(c.PlayerInventory.Desc:find("Sword +3 x2",1,true))
    c.TeleportDestination:Emit("Boss · Arena (2)")
    local before=#calls;c.Teleport.Callback();assert(#calls==before+1 and calls[#calls].Args[1]=="B","Selecting a destination never teleports until the button is pressed")
    s.StopEverything=true;c.AtheonDodge:Emit(true)
    assert(c.AtheonDodge.Value==false,"Rejected toggles must return to their actual value")
    s.StopEverything=false
    api.Update(4);flush();before=#calls
    gemCount=80;api.Update(5);flush()
    assert(#calls==before,"Inventory quantity refreshes cannot change trade selections or invoke actions")
    assert(c.TradeItems.Value[1]=="Gem x80"and s.TradeItems.Gem)
    for i=1,20 do api.Update(5+i*.01)end
    local reads=inventoryReads;c.HideUI.Callback()
    assert(not visible and s.UIHidden and s.HealthVisible,"Hiding WindUI must leave the health HUD visible")
    api.Update(10);flush();assert(inventoryReads==reads,"A hidden UI must not scan inventory choices")
    api.SetVisible(true);assert(visible and not s.UIHidden)
    api.Destroy();api.Destroy();before=#calls
    c.AutoTrade:Emit(false);c.RestartScript.Callback();flush()
    assert(#calls==before and window.Destroyed,"Old callbacks are inert after runtime cleanup")
    print("PASS WindUI: all features, saved defaults without side effects, native callbacks, locked floors, current-floor arenas, batch save, inventory refresh, pause rejection, HUD-safe hide, bounded refresh and cleanup")
end
