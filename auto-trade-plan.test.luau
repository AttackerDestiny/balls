return function(planSource,moduleSource)
    local worker=assert(loadstring(moduleSource))()({})
    local function item(name,id)
        local value={Name=name,Value=id,Attrs={}}
        function value:IsA(class)return class=="IntValue"end
        function value:GetAttribute(key)return self.Attrs[key]end
        return value
    end
    local scroll=item("Upgrade Protection Scroll",1)
    local crystal=item("Resurrection Crystal",2)
    local sword=item("Ordinary Sword",3)
    local inventory={GetChildren=function()return {scroll,crystal,sword}end}
    local equipped={}
    local equip={GetChildren=function()return equipped end}
    local state={TradeMode="Selected",TradeItems={}}
    local definitions={FindFirstChild=function()return {FindFirstChild=function(_,key)if key=="Rarity"then return {Value="Rare"}end end}end}
    local rs={Database={Items=definitions}}
    local profile={Stats={FindFirstChild=function()return {Value=110}end}}
    local restrictions={CanOfferTrading=function(_,value)return not value.Restricted end}
    local chunk=assert(loadstring(planSource.."\nreturn plan"))
    setfenv(chunk,setmetatable({worker=worker,state=state,inventory=inventory,equip=equip,rs=rs,profile=profile,restrictions=restrictions},{__index=getfenv()}))
    local plan=chunk()
    for _,mode in ipairs({"Selected","Legendary"})do
        state.TradeMode=mode
        local items,vel=plan();assert(#items==2 and items[1]==scroll and items[2]==crystal and vel==100)
    end
    scroll.Attrs.Locked=true;local items=plan();assert(#items==1 and items[1]==crystal)
    scroll.Attrs.Locked=nil;crystal.Attrs.Favorited=true;items=plan();assert(#items==1 and items[1]==scroll)
    crystal.Attrs.Favorited=nil;scroll.Restricted=true;items=plan();assert(#items==1 and items[1]==crystal)
    scroll.Restricted=false;equipped={{Value=2,IsA=function()return true end}}
    items=plan();assert(#items==1 and items[1]==scroll)
    assert(not worker.AlwaysInclude("Other Crystal"))
    print("PASS Always-trade consumables: both modes, rare items included, locked/favorited/equipped/restricted items preserved")
end
