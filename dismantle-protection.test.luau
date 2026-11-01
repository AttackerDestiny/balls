return function(source)
    local function node(name,class,value)
        local n={Name=name,ClassName=class,Value=value,Children={},Attrs={}}
        function n:IsA(k)return k==self.ClassName or (k=="ValueBase"and (self.ClassName=="BoolValue"or self.ClassName=="IntValue"or self.ClassName=="StringValue"))end
        function n:GetAttribute(k)return self.Attrs[k]end
        function n:FindFirstChild(k)return self.Children[k]end
        function n:GetChildren()local r={};for _,v in pairs(self.Children)do table.insert(r,v)end;return r end
        return n
    end
    local inventory=node("Inventory","Folder");local equip=node("Equip","Folder");local definitions=node("Items","Folder")
    local state={};state.IsAutoEquipmentCandidate=function(item)return item.Planned end
    local chunk=assert(loadstring(source.."\nreturn protected"))
    setfenv(chunk,setmetatable({inventory=inventory,equip=equip,definitions=definitions,state=state},{__index=getfenv()}))
    local protected=chunk()
    local function item(name)
        local n=node(name or "Sword","IntValue",1);n.Parent=inventory;return n
    end
    local n=item();assert(not protected(n))
    equip.Children.Right=node("Right","IntValue",1);assert(protected(n));equip.Children={}
    for _,flag in ipairs({"Locked","Lock","Favorite","Favorited","Favourite","Favourited","Skin"})do
        n=item();n.Attrs[flag]=true;assert(protected(n),flag)
        n=item();n.Children[flag]=node(flag,"BoolValue",true);assert(protected(n),flag)
        n.Children[flag].Value=false;assert(not protected(n),flag)
    end
    n=item();n.Planned=true;assert(protected(n))
    assert(protected(item("Novice Sword"))and protected(item("Rare Aura")))
    n=item();n.Parent=nil;assert(protected(n))
    print("PASS Dismantle protections: equipped, locked/favorite attributes and values, planned equipment, Novice, aura, removed items")
end
