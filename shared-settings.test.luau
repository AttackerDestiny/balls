return function(source)
    local make=assert(loadstring(source))()
    local files,values={},{}
    local writes=0
    local function encode(t)
        local function emit(v)
            if type(v)~="table"then return tostring(v)end
            local keys={};for k in pairs(v)do keys[#keys+1]=k end;table.sort(keys)
            local result="{";for _,k in ipairs(keys)do result..=tostring(k)..":"..emit(v[k])..","end;return result.."}"
        end
        local s=emit(t);values[s]=t;return s
    end
    local function context(current)
        return {Current=current,IsFile=function(p)return files[p]~=nil end,Read=function(p)return files[p]end,
            Write=function(p,v)files[p]=v;writes+=1 end,Encode=encode,Decode=function(s)return values[s]end,
            List=function()return {"SB2Codex/settings_1.json","SB2Codex/settings_2.json"}end}
    end
    files["SB2Codex/settings_1.json"]=encode({Version=1,SafeMode=true,SafeWhitelistText="Trusted",SafeWhitelistIds={['123']=true},ProgressionFloor=11,AutomationRunId="private"})
    files["SB2Codex/settings_2.json"]=encode({Version=1,SafeMode=false})
    local a=make(context({Version=1,SafeMode=false}))
    assert(a.Values.SafeMode and a.Values.SafeWhitelistText=="Trusted")
    assert(a.Values.ProgressionFloor==nil and a.Values.AutomationRunId==nil)
    local b=make(context({Version=1,SafeMode=false,ProgressionFloor=1}))
    assert(b.Values.SafeMode and b.Values.SafeWhitelistIds['123'])
    local presetCtx=context({Version=1,SafeMode=false,ProgressionFloor=8})
    presetCtx.File="SB2Codex/shared-preset_2_settings.json";presetCtx.List=nil
    local preset=make(presetCtx)
    preset.Save({Version=1,SafeMode=false,AutoFarm=true,ProgressionFloor=9})
    local fromOtherAccount=make(presetCtx)
    assert(fromOtherAccount.Values.AutoFarm and fromOtherAccount.Values.ProgressionFloor==nil
        and a.Values.SafeMode,"Share preset edits without mixing in default settings or account checkpoints")
    print("PASS Shared autosave migrates the configured account and shares preferences without account checkpoints")
    local initial=writes
    a.Save({SafeMode=true,SafeWhitelistText="Trusted",SafeWhitelistIds={['123']=true},ProgressionFloor=2})
    assert(writes==initial)
    b.Save({SafeMode=false,SafeWhitelistText="Updated"})
    a.Save({SafeMode=true,SafeWhitelistText="Trusted",SafeWhitelistIds={['123']=true},ProgressionFloor=3})
    local c=make(context({Version=1}))
    assert(c.Values.SafeMode==false and c.Values.SafeWhitelistText=="Updated")
    print("PASS Unchanged account saves do not overwrite another account's newer shared preferences")
    -- Simulate two clients loaded before either changes settings.
    files["SB2Codex/shared-settings.json"]=encode({Version=1,SafeMode=false,
        SafeWhitelistText="Old",SafeWhitelistIds={['1']=true},AutoFarm=false})
    local one=make(context({Version=1}));local two=make(context({Version=1}))
    one.Save({SafeMode=true,SafeWhitelistText="TrustedNew",SafeWhitelistIds={['99']=true},AutoFarm=false})
    two.Save({SafeMode=false,SafeWhitelistText="Old",SafeWhitelistIds={['1']=true},AutoFarm=true})
    local three=make(context({Version=1}))
    assert(three.Values.SafeMode and three.Values.SafeWhitelistText=="TrustedNew"and three.Values.SafeWhitelistIds['99'])
    assert(three.Values.AutoFarm==true)
    two.Save({SafeMode=false,SafeWhitelistText="Old",SafeWhitelistIds={['1']=true},AutoFarm=false})
    three=make(context({Version=1}));assert(three.Values.SafeMode and three.Values.AutoFarm==false)
    print("PASS Another account changing unrelated options preserves shared Safe Mode and whitelist")
    -- Changing Safe Mode intentionally still writes the new value, including OFF.
    one.Save({SafeMode=false,SafeWhitelistText="TrustedNew",SafeWhitelistIds={['99']=true},AutoFarm=false})
    three=make(context({Version=1}));assert(three.Values.SafeMode==false and three.Values.SafeWhitelistIds['99'])
    local before=writes
    one.Save({SafeMode=false,SafeWhitelistText="TrustedNew",SafeWhitelistIds={['99']=true},AutoFarm=false})
    assert(writes==before)
    files["SB2Codex/shared-settings.json"]=nil
    one.Save({SafeMode=false,SafeWhitelistText="TrustedNew",SafeWhitelistIds={['99']=true},AutoFarm=false})
    assert(files["SB2Codex/shared-settings.json"]and writes==before+1)
    print("PASS Explicit Safe Mode OFF saves, unchanged preferences skip writes, missing shared file recovers")

    files["SB2Codex/shared-settings.json"]=encode({Version=1,SafeMode=true,SafeFloorId=11,AutoFarm=false})
    local floorOne=make(context({Version=1}));local floorTwo=make(context({Version=1}))
    floorOne.Save({SafeMode=true,SafeFloorId=22,AutoFarm=false})
    assert(floorTwo.ReadSafeFloor()==22,"Other running accounts can read the latest Safe floor")
    floorTwo.Save({SafeMode=true,SafeFloorId=11,AutoFarm=true})
    assert(floorOne.ReadSafeFloor()==22,"An unrelated save cannot revert the shared floor")
    local floorThree=make(context({Version=1,SafeFloorId=33}))
    assert(floorThree.Values.SafeFloorId==22,"Shared floor overrides an account's old saved selection")
    print("PASS Shared Safe floor: cross-account load, live read and stale unrelated saves")

    local orderOne=make(context({Version=1}))
    orderOne.Save({CreditCheck=true,CreditWhitelistText="CreditFriend",BossOnly=true,MultiSpotOrder={"b","a"}})
    local orderTwo=make(context({Version=1}))
    assert(orderTwo.Values.CreditCheck and orderTwo.Values.CreditWhitelistText=="CreditFriend")
    assert(orderTwo.Values.BossOnly and orderTwo.Values.MultiSpotOrder[1]=="b"and orderTwo.Values.MultiSpotOrder[2]=="a")
    print("PASS Boss Only and ordered Multi Spot priorities share across account loads")

end
