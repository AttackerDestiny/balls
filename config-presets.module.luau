-- Keep imported snapshots and active per-account settings in separate files.
return function(ctx)
    local prefix=ctx.Folder.."/preset_"..ctx.UserId.."_"
    local controlPath=prefix.."index.json"
    local maxSlots=50
    local function slot(value,count)
        return type(value)=="number" and value%1==0 and value>=1 and value<=count and value or 0
    end
    local function decode(path,limit)
        local bytes=ctx.Read(path)
        assert(#bytes<=limit,"Preset file exceeds its size limit")
        return ctx.Decode(bytes)
    end
    local prefs={Version=1,Count=0,Manual=0,Outside=0,Between=0,Auto=false}
    local api={Preferences=prefs}
    local function saved(id)return prefix..id..".json"end
    local function persist(nextPrefs)
        ctx.Write(controlPath,ctx.Encode(nextPrefs))
        for key,value in pairs(nextPrefs)do prefs[key]=value end
    end
    local ok,reason=pcall(function()
        if not ctx.Available or not ctx.Exists(controlPath)then return end
        local raw=decode(controlPath,8192)
        assert(type(raw)=="table"and raw.Version==1,"Invalid preset index")
        prefs.Count=slot(raw.Count,maxSlots)
        for _,key in ipairs({"Manual","Outside","Between"})do prefs[key]=slot(raw[key],prefs.Count)end
        prefs.Auto=raw.Auto==true
    end)
    if not ok then api.Error=tostring(reason)end
    function api.Resolve(override)
        if override~=nil and (override==0 or slot(override,prefs.Count)>0)then return override end
        local selected=prefs[ctx.InBetween and "Between" or "Outside"]
        if prefs.Auto and selected>0 then return selected end
        return prefs.Manual
    end
    function api.Load(id)
        assert(ctx.Available and slot(id,prefs.Count)>0,"Preset is unavailable")
        return ctx.Validate(decode(saved(id),262144))
    end
    function api.SavePreset(package)
        assert(ctx.Available,"Preset storage is unavailable in this executor")
        assert(not api.Error,api.Error)
        local id=prefs.Count+1
        assert(id<=maxSlots,"Preset limit reached (50)")
        local bytes=ctx.Encode(package)
        assert(#bytes<=262144,"Config exceeds 256 KB")
        ctx.Write(saved(id),bytes)
        local nextPrefs=table.clone(prefs);nextPrefs.Count=id;persist(nextPrefs)
        return id
    end
    function api.Set(key,value)
        assert(ctx.Available,"Preset storage is unavailable in this executor")
        assert(not api.Error,api.Error)
        assert(key=="Auto"or key=="Manual"or key=="Outside"or key=="Between","Invalid preset setting")
        local nextPrefs=table.clone(prefs)
        if key=="Auto"then nextPrefs.Auto=value==true else nextPrefs[key]=slot(value,prefs.Count)end
        if nextPrefs[key]~=prefs[key]then persist(nextPrefs)end
    end
    function api.Activate(override)
        local id=api.Resolve(override)
        if id==0 then return end
        local loaded,problem=pcall(function()
            local path=ctx.Folder.."/settings_"..ctx.UserId.."_preset_"..id..".json"
            assert(ctx.Exists(saved(id)),"Preset file is missing")
            if not ctx.Exists(path)then api.Seed=api.Load(id)end
            api.ActiveId=id
            api.SettingsPath=path
            api.SpotPrefix="custom-spots_"..ctx.UserId.."_preset_"..id.."_"
        end)
        if not loaded then api.Error=tostring(problem)end
    end
    return api
end
