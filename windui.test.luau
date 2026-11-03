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
        for _,kind in ipairs({"Button","Toggle","Input","Dropdown","Paragraph","Section"})do
            tab[kind]=function(_,opts)return element(kind,opts)end
        end
        function tab:Select()window.CurrentTab=index end
        return tab
    end
    function window:CreateTopbarButton(name,icon,callback,order)
        assert((name=="Restart script"and icon=="rotate-cw"and order==996)or (name=="Auto-hide UI on execute"and icon=="eye-off"and order==995))
        return {Callback=callback,Topbar=true}
    end
    function window:OnOpen(fn)self.Opened=fn end
    function window:OnClose(fn)self.ClosedCallback=fn end
    function window:OnDestroy(fn)self.DestroyedCallback=fn end
    function window:Open()self.Closed=false;if self.Opened then self.Opened()end end
    function window:Close()self.Closed=true;if self.ClosedCallback then self.ClosedCallback()end end
    function window:Destroy()self.Destroyed=true;if self.DestroyedCallback then self.DestroyedCallback()end end
    local wind={GetThemes=function()return {Dark={},Light={}}end,SetTheme=function(_,name)return name=="Dark"or name=="Light"end,CreateWindow=function(_,opts)
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
    function s.SetAutoCraft(value)record("SetAutoCraft",value);s.AutoCraft=value end
    function s.SetTradeItems(value)record("SetTradeItems",value);s.TradeItems=value end
    local inventoryReads=0;local gemCount=64
    function s.GetTradeItemChoices()inventoryReads+=1;return {{Name="Gem",Count=gemCount},{Name="Scroll",Count=1}}end
    for _,name in ipairs({"SaveMultiSpot","TeleportToDestination","RefreshTeleportDestinations","SaveCurrentMiniBossArea","RestartScript","OpenGameMenu","ExportConfig","ImportConfig"})do
        s[name]=function(...)record(name,...)end
    end
    function s.SetAutoHideUI(on)record("SetAutoHideUI",on);s.AutoHideUI=on end
    function s.Destroy()record("Destroy");s.Running=false end
    s.PlayerTools={Choices=function()return {{UserId=123,Name="Friend",DisplayName="Friend"}}end,
        Select=function(id)record("SelectPlayer",id);s.SelectedPlayerId=id end,
        Teleport=function()record("TeleportPlayer")end,
        SetViewing=function(on)record("SetViewing",on);s.ViewingPlayer=on end,
        SetInventoryVisible=function(on)record("SetInventoryVisible",on);s.ViewingPlayerInventory=on end}
    local present=false
    local visible=true
    local yields=0
    local api=make({Yield=function()yields+=1 end,State=s,WindUI=wind,PlaceId=11,FriendPresent=function()return present end,Visibility=function(value)visible=value end})
    assert(yields>=40,"UI construction must offer frame-budget yield points")
    local c=api.Controls
    assert(c.AutoJoinFriendStatus.Title=="Status"and c.AutoJoinFriendStatus.Desc=="Friend Unappeared")
    present=true;api.Update(.3);assert(c.AutoJoinFriendStatus.Desc=="Friend Appeared")
    present=false;api.Update(.6);assert(c.AutoJoinFriendStatus.Desc=="Friend Unappeared")
    assert(c.RestartScript.Topbar,"Restart belongs in the window header")
    for _,key in ipairs({"MultiSpotStatus","TransparentMap","ProgressionStatus","ProgressionGear","PlayerInventory","PlayerStatus","AutoDismantleStatus","TradeStatus","TradeVelInfo","AntiAfkStatus","ModeratorStatus","SkillStatus","MiscSkillStatus","CombatStatus","TravelStatus","AutoSaveStatus","DodgeStatus","SaveMiniBossArea","HideUI","Unload"})do assert(not c[key],"Removed control: "..key)end
    assert(c.AutoTrade.Desc=="Only Accept Trade From Safe Mod Whitelist List"and c.TradeMode.Title=="Mode"and c.TradeItems.Title=="Inventory"and c.TradeItems.Desc==nil)
    assert(c.AutoDismantle.Title=="Auto Dismantle"and c.AutoDismantle.Desc==nil)
    assert(c.SafeMode.Desc==nil and c.SafeFloor.Desc==nil)
    assert(c.SafeWhitelist.Title=="Whitelist"and c.SafeWhitelist.Desc=="Input A List Of User")
    assert(c.AccountProgression.Desc==nil and c.AutoFarm.Desc==nil and c.AutoEquipBestSword.Desc==nil and c.AutoSwing.Desc==nil)
    flush();assert(tabCount==9 and #calls==0,"Loading saved ON values must not invoke setters or actions")
    for _,key in ipairs({"Enabled","AutoFarm","AutoEquipBestSword","AtheonDodge","AutoSwing","AutoDodge",
        "SkillAuraSection","SkillAura","SelectedSkill","MiscSkillSection","MiscSkillEnabled","SelectedMiscSkill","SafeModeSection","SafeMode","SafeFloor","SafeWhitelist",
        "MultiSpotSection","MultiSpot","SaveSpot","MultiSpotAreas","FriendJoinerSection","AutoJoinFriend","JoinFriendUsername","RestartScript",
        "TeleportSection","TeleportDestination","RefreshDestinations","OpenDismantle","OpenUpgrade","OpenThe Forge",
        "SelectedPlayer","TeleportPlayer","ViewingPlayer","ViewingPlayerInventory",
        "PerformanceBoosterSection","PerformanceBoosters","AutoDismantleSection","AutoDismantle","AutoCraftSection","AutoCraft","AutoTradeSection","AutoTrade","TradeMode","TradeItems","AccountProgression"})do
        assert(c[key],"Every available feature must be present: "..key)
    end
    assert(c.MultiSpotAreas.Title=="Saved Spot"and c.MultiSpotAreas.Desc==nil)
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
    c.AutoCraft:Emit({"Uncommon → Rare","Rare → Legendary"});assert(s.AutoCraft["Rare Upgrade Crystal"]and s.AutoCraft["Legendary Upgrade Crystal"])
    c.AutoDismantle:Emit({"Rare"});assert(s.AutoDismantle.Rare and not s.AutoDismantle.Common)
    c.TradeMode:Emit("Selected items");assert(s.TradeMode=="Selected")
    c.TradeItems:Emit({"Gem x64","Scroll x1"});assert(s.TradeItems.Gem and s.TradeItems.Scroll)
    c.AutoHideUI.Callback();assert(s.AutoHideUI,"Top-bar auto-hide preference is saved through the setter")
    c.SafeWhitelist:Emit("Other, 456");assert(s.SafeWhitelistText=="Other, 456")
    c.JoinFriendUsername:Emit("NewFriend");assert(s.JoinFriendUsername=="NewFriend")
    c.SelectedSkill:Emit("Beam Rush");assert(s.SelectedSkill=="Beam Rush")
    c.SelectedPlayer:Emit("Friend (@Friend)");assert(s.SelectedPlayerId==123)
    c.ViewingPlayerInventory:Emit(true);api.Update(3);flush()
    local before=#calls
    assert(not c.Teleport and c.TeleportDestination.Title=="Spot"and c.RefreshDestinations.Title=="Refresh List")
    c.TeleportDestination:Emit("Boss · Arena (2)")
    assert(#calls==before+1 and calls[#calls].Name=="TeleportToDestination"and calls[#calls].Args[1]=="B","Selecting a destination teleports exactly once")
    api.Update(3.5);flush()
    local repeated=#calls;c.TeleportDestination:Emit("Boss · Arena (2)")
    assert(#calls==repeated+1 and calls[#calls].Name=="TeleportToDestination","The same spot can be clicked again after its request")
    s.StopEverything=true;c.AtheonDodge:Emit(true)
    assert(c.AtheonDodge.Value==false,"Rejected toggles must return to their actual value")
    s.StopEverything=false
    local idleReads=inventoryReads
    api.Update(4);flush();assert(inventoryReads==idleReads,"Main tab must not rebuild inventory dropdowns")
    api.Tabs.Utility:Select();api.Update(4.3);flush();before=#calls
    gemCount=80;api.Update(5.4);flush()
    assert(#calls==before,"Inventory quantity refreshes cannot change trade selections or invoke actions")
    assert(c.TradeItems.Value[1]=="Gem x80"and s.TradeItems.Gem)
    for i=1,20 do api.Update(5.4+i*.01)end
    local reads=inventoryReads;api.SetVisible(false)
    assert(not visible and s.UIHidden and s.HealthVisible,"Hiding WindUI must leave the health HUD visible")
    api.Update(10);flush();assert(inventoryReads==reads,"A hidden UI must not scan inventory choices")
    api.SetVisible(true);assert(visible and not s.UIHidden)
    api.Destroy();api.Destroy();before=#calls
    c.AutoTrade:Emit(false);c.RestartScript.Callback();flush()
    assert(#calls==before and window.Destroyed,"Old callbacks are inert after runtime cleanup")
    s.Running=true;window.Destroyed=false;tabCount=0;s.UI.ActiveTab="Main"
    local deferred
    local staged=make({State=s,WindUI=wind,PlaceId=11,Defer=function(fn)deferred=fn end,Visibility=function()end})
    assert(staged.Controls.SafeMode and not staged.Controls.Enabled,"Main controls become available before background tabs")
    deferred();flush()
    assert(staged.Controls.Enabled and staged.Controls.AutoTrade,"Background build must finish every feature")
    assert(staged.Tabs.Settings and staged.Controls.Theme and staged.Controls.ConfigImport and staged.Controls.ConfigExport)
    staged.Controls.Theme:Emit("Light");assert(s.Theme=="Light")
    staged.Controls.ConfigExport.Callback();assert(calls[#calls].Name=="ExportConfig")
    staged.Controls.ConfigImport:Emit("config-text");assert(calls[#calls].Name=="ImportConfig"and calls[#calls].Args[1]=="config-text")
    staged.Destroy();s.Running=true;tabCount=0
    local cancelled=make({State=s,WindUI=wind,PlaceId=11,Defer=function(fn)deferred=fn end,Visibility=function()end})
    cancelled.Destroy();deferred()
    assert(not cancelled.Controls.Enabled,"Destroyed runtimes must not build more controls")
    print("PASS WindUI: all features, saved defaults without side effects, native callbacks, locked floors, current-floor arenas, batch save, inventory refresh, pause rejection, HUD-safe hide, bounded refresh and cleanup")
end
