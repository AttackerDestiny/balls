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
    print("PASS Shared autosave migrates the configured account and shares preferences without account checkpoints")
    local initial=writes
    a.Save({SafeMode=true,SafeWhitelistText="Trusted",SafeWhitelistIds={['123']=true},ProgressionFloor=2})
    assert(writes==initial)
    b.Save({SafeMode=false,SafeWhitelistText="Updated"})
    a.Save({SafeMode=true,SafeWhitelistText="Trusted",SafeWhitelistIds={['123']=true},ProgressionFloor=3})
    local c=make(context({Version=1}))
    assert(c.Values.SafeMode==false and c.Values.SafeWhitelistText=="Updated")
    print("PASS Unchanged account saves do not overwrite another account's newer shared preferences")
end
