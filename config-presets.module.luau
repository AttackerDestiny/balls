-- Shared preset snapshots and routing, with account-scoped runtime checkpoints.
return function(ctx)
    local prefix=ctx.Folder.."/shared-preset_"
    local controlPath=prefix.."index.json"
    local maxSlots=200
    local function slot(value,count)
        return type(value)=="number" and value%1==0 and value>=1 and value<=count and value or 0
    end
    local function decode(path,limit)
        local bytes=ctx.Read(path)
        assert(#bytes<=limit,"Preset file exceeds its size limit")
        return ctx.Decode(bytes)
    end
    local prefs={Version=1,Count=0,Manual=0,Outside=0,Between=0,Auto=false,Migrated={}}
    local api={Preferences=prefs}
    local function saved(id)return prefix..id..".json"end
    local function persist(nextPrefs)
        ctx.Write(controlPath,ctx.Encode(nextPrefs))
        for key,value in pairs(nextPrefs)do prefs[key]=value end
    end
    local function index(path,limit)
        local raw=decode(path,8192)
        assert(type(raw)=="table"and raw.Version==1,"Invalid preset index")
        local count=slot(raw.Count,limit)
        return {Version=1,Count=count,Manual=slot(raw.Manual,count),Outside=slot(raw.Outside,count),
            Between=slot(raw.Between,count),Auto=raw.Auto==true,Migrated=type(raw.Migrated)=="table"and raw.Migrated or {}}
    end
    local function refresh()
        if not ctx.Available or not ctx.Exists(controlPath)then return end
        for key,value in pairs(index(controlPath,maxSlots))do prefs[key]=value end
    end
    function api.Refresh()
        local ok,reason=pcall(refresh)
        api.Error=not ok and tostring(reason)or nil
        return prefs
    end
    local function writePreset(id,package)
        local bytes=ctx.Encode(package)
        assert(#bytes<=262144,"Config exceeds 256 KB")
        ctx.Write(saved(id),bytes)
    end
    local function migrate()
        refresh()
        local legacy=ctx.Folder.."/preset_"..ctx.UserId.."_"
        if prefs.Migrated[ctx.UserId]or not ctx.Exists(legacy.."index.json")then return end
        local old=index(legacy.."index.json",50)
        local nextPrefs=table.clone(prefs)
        nextPrefs.Migrated=table.clone(prefs.Migrated)
        local remap={}
        local spotFiles={}
        if ctx.List then
            local listed,paths=pcall(ctx.List,ctx.Folder)
            if listed and type(paths)=="table"then
                local pattern="^custom%-spots_"..ctx.UserId.."_preset_(%d+)_(%d+)%.json$"
                for _,path in ipairs(paths)do
                    local name=path:match("[^/\\]+$")
                    if name then
                        local id,floor=name:match(pattern)
                        if id then
                            id=tonumber(id);spotFiles[id]=spotFiles[id]or {};spotFiles[id][floor]=true
                        end
                    end
                end
            end
        end
        for oldId=1,old.Count do
            local source=legacy..oldId..".json"
            if ctx.Exists(source)then
                local id=nextPrefs.Count+1
                assert(id<=maxSlots,"Shared preset limit reached (200)")
                local package=ctx.Validate(decode(source,262144))
                local settingsPath=ctx.Folder.."/settings_"..ctx.UserId.."_preset_"..oldId..".json"
                if ctx.Exists(settingsPath)then
                    local current=decode(settingsPath,32768)
                    local edited=table.clone(package);edited.Settings=current
                    if pcall(ctx.Validate,edited)then package=edited end
                end
                local spots=table.clone(package.CustomSpots)
                local prefixName="custom-spots_"..ctx.UserId.."_preset_"..oldId.."_"
                local function copySpots(floor)
                    local spotPath=ctx.Folder.."/"..prefixName..floor..".json"
                    if not ctx.Exists(spotPath)then return end
                    local stored=decode(spotPath,32768)
                    if stored.Version==1 and tostring(stored.PlaceId)==floor then spots[floor]=stored.Areas end
                end
                for floor in pairs(package.CustomSpots)do copySpots(floor)end
                for floor in pairs(spotFiles[oldId]or {})do if package.CustomSpots[floor]==nil then copySpots(floor)end end
                package=table.clone(package);package.CustomSpots=spots
                writePreset(id,ctx.Validate(package))
                remap[oldId]=id;nextPrefs.Count=id
            end
        end
        if not ctx.Exists(controlPath)then
            for _,key in ipairs({"Manual","Outside","Between"})do nextPrefs[key]=remap[old[key]]or 0 end
            nextPrefs.Auto=old.Auto
        end
        nextPrefs.Migrated[ctx.UserId]=true
        persist(nextPrefs)
    end
    if ctx.Available then
        local ok,reason=pcall(migrate)
        if not ok then api.Error=tostring(reason)end
    end
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
        refresh()
        local id=prefs.Count+1
        assert(id<=maxSlots,"Shared preset limit reached (200)")
        writePreset(id,package)
        local nextPrefs=table.clone(prefs);nextPrefs.Count=id;persist(nextPrefs)
        return id
    end
    function api.ExportLibrary(active)
        refresh()
        if prefs.Count==0 then return nil end
        local library={Items={},Active=api.ActiveId or 0,Manual=prefs.Manual,Outside=prefs.Outside,Between=prefs.Between,Auto=prefs.Auto}
        local spotFiles={}
        if ctx.List then
            for _,path in ipairs(ctx.List(ctx.Folder))do
                local name=path:match("[^/\\]+$")
                local id,floor=(name or ""):match("^custom%-spots_shared%-preset_(%d+)_(%d+)%.json$")
                if id then
                    id=tonumber(id);spotFiles[id]=spotFiles[id]or {};spotFiles[id][floor]=path
                end
            end
        end
        for id=1,prefs.Count do
            if id==library.Active then
                library.Items[id]=active
                continue
            end
            local package=table.clone(api.Load(id))
            local settings=table.clone(package.Settings)
            local accountPath=ctx.Folder.."/settings_"..ctx.UserId.."_shared-preset_"..id..".json"
            local sharedPath=prefix..id.."_settings.json"
            if ctx.Exists(accountPath)then settings=decode(accountPath,32768)end
            if ctx.Exists(sharedPath)then
                for key,value in pairs(decode(sharedPath,32768))do settings[key]=value end
            end
            local spots=table.clone(package.CustomSpots)
            local function copySpots(floor,path)
                if not ctx.Exists(path)then return end
                local stored=decode(path,32768)
                if stored.Version==1 and tostring(stored.PlaceId)==floor then spots[floor]=stored.Areas end
            end
            for floor in pairs(package.CustomSpots)do
                copySpots(floor,ctx.Folder.."/custom-spots_shared-preset_"..id.."_"..floor..".json")
            end
            for floor,path in pairs(spotFiles[id]or {})do copySpots(floor,path)end
            library.Items[id]={Settings=settings,CustomSpots=spots}
        end
        return library
    end
    function api.Import(package)
        local library=package.Presets
        if not library then return api.SavePreset(package)end
        assert(ctx.Available,"Preset storage is unavailable in this executor")
        refresh()
        local offset=prefs.Count
        local count=offset+#library.Items+(library.Active==0 and 1 or 0)
        assert(count<=maxSlots,"Shared preset limit reached (200)")
        local entries={}
        for id,item in ipairs(library.Items)do
            entries[id]={Format="FeatherConfig",Version=1,Settings=item.Settings,CustomSpots=item.CustomSpots}
        end
        if library.Active==0 then
            entries[#entries+1]={Format="FeatherConfig",Version=1,Settings=package.Settings,CustomSpots=package.CustomSpots}
        end
        for id,item in ipairs(entries)do writePreset(offset+id,item)end
        local nextPrefs=table.clone(prefs)
        nextPrefs.Count=count;nextPrefs.Auto=library.Auto
        for _,key in ipairs({"Manual","Outside","Between"})do
            local id=library[key]
            nextPrefs[key]=id>0 and offset+id or 0
        end
        persist(nextPrefs)
        return library.Active>0 and offset+library.Active or count
    end
    function api.Set(key,value)
        assert(ctx.Available,"Preset storage is unavailable in this executor")
        refresh()
        assert(key=="Auto"or key=="Manual"or key=="Outside"or key=="Between","Invalid preset setting")
        local nextPrefs=table.clone(prefs)
        if key=="Auto"then nextPrefs.Auto=value==true else nextPrefs[key]=slot(value,prefs.Count)end
        if nextPrefs[key]~=prefs[key]then persist(nextPrefs)end
    end
    function api.Activate(override)
        local id=api.Resolve(override)
        if id==0 then return end
        local loaded,problem=pcall(function()
            local path=ctx.Folder.."/settings_"..ctx.UserId.."_shared-preset_"..id..".json"
            assert(ctx.Exists(saved(id)),"Preset file is missing")
            if not ctx.Exists(path)then api.Seed=api.Load(id)end
            api.ActiveId=id
            api.SettingsPath=path
            api.SharedSettingsPath=prefix..id.."_settings.json"
            api.SpotPrefix="custom-spots_shared-preset_"..id.."_"
        end)
        if not loaded then api.Error=tostring(problem)end
    end
    return api
end
