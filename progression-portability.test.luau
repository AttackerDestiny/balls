-- Exercise the real transfer and preset adapters together with isolated storage.
return function(transferSource,presetSource,preferenceSource)
    local transfer=assert(loadstring(transferSource))()
    local presets=assert(loadstring(presetSource))()
    local files,objects={},{}
    local function encode(value)objects[#objects+1]=value;return tostring(#objects)end
    local function decode(value)return objects[tonumber(value)]end
    local validate=transfer({}).Validate
    local function account(user)
        return presets({Folder="Fixtures",UserId=user,Available=true,InBetween=false,Validate=validate,
            Encode=encode,Decode=decode,Exists=function(path)return files[path]~=nil end,
            Read=function(path)return files[path]end,Write=function(path,bytes)files[path]=bytes end,
            List=function()local result={};for path in pairs(files)do result[#result+1]=path end;return result end})
    end
    local private={ProgressionFloor=9,ProgressionBossCleared=true,ProgressionBossClearedName="Old main boss",
        ProgressionComplete=true,ProgressionRestore={Enabled=false,AutoFarm=false}}
    local original={Version=1,AccountProgression=true,SafeMode=true}
    for key,value in pairs(private)do original[key]=value end
    local package={Format="FeatherConfig",Version=1,Settings=original,CustomSpots={}}
    local first=account("first")
    first.SavePreset(package);first.Set("Manual",1)
    local written=decode(files["Fixtures/shared-preset_1.json"])
    for key,value in pairs(private)do
        assert(written.Settings[key]==nil and original[key]==value,
            "Saving a shared preset must exclude progression without clearing the owner's runtime")
    end
    -- Old preset files must also be sanitized when loaded by a new account.
    files["Fixtures/shared-preset_1.json"]=encode(package)
    local second=account("second");second.Activate()
    for key in pairs(private)do assert(second.Seed.Settings[key]==nil,"A new account cannot inherit a legacy F9 checkpoint")end
    assert(second.Seed.Settings.AccountProgression and original.ProgressionFloor==9)
    local ownA={Version=1,AccountProgression=true,ProgressionFloor=8,ProgressionBossCleared=false}
    local ownB={Version=1,AccountProgression=true,ProgressionFloor=2,ProgressionBossCleared=true,
        ProgressionBossClearedName="Own main boss",ProgressionRestore={Enabled=true}}
    local pathA="Fixtures/settings_first_shared-preset_1.json"
    local pathB="Fixtures/settings_second_shared-preset_1.json"
    files[pathA]=encode(ownA);files[pathB]=encode(ownB)
    local savedA,savedB=files[pathA],files[pathB]
    local reloadA,reloadB=account("first"),account("second");reloadA.Activate();reloadB.Activate()
    assert(not reloadA.Seed and not reloadB.Seed and reloadA.SettingsPath~=reloadB.SettingsPath,
        "Existing account files retain their own checkpoint")
    local function loadPreferences(book,data)
        local chunk=assert(loadstring(preferenceSource.."\nreturn preference('ProgressionFloor',1),preference('AccountProgression',false)"))
        setfenv(chunk,setmetatable({presetBook=book,sharedPreferences={AccountProgression=true},
            importedConfig=book.Seed,configData=data or {}},{__index=getfenv()}))
        return chunk()
    end
    local checkpoint,on=loadPreferences(second)
    assert(checkpoint==1 and on,"First load starts at F1 while preserving the shared progression toggle")
    assert(loadPreferences(reloadA,ownA)==8 and loadPreferences(reloadB,ownB)==2,
        "Normal bootstrap keeps valid checkpoints isolated across accounts")
    first.SavePreset(package)
    files["Fixtures/settings_first_shared-preset_2.json"]=encode(ownB)
    local inactiveBytes=files["Fixtures/settings_first_shared-preset_2.json"]
    files["Fixtures/shared-preset_2_settings.json"]=encode({Version=1,AccountProgression=true,ProgressionFloor=12,ProgressionComplete=true})
    files["Fixtures/shared-preset_1_settings.json"]=encode({Version=1,AccountProgression=true,ProgressionFloor=12})
    local export=transfer({Settings=function()return ownA end,Spots=function()return {}end,
        Presets=reloadA.ExportLibrary,Encode=encode,Decode=decode,Copy=function()end})
    local exported=decode(export.Export())
    for key in pairs(private)do
        assert(exported.Settings[key]==nil)
        for _,item in ipairs(exported.Presets.Items)do
            assert(item.Settings[key]==nil,"Active/inactive account overrides and old shared settings cannot leak into library exports")
        end
    end
    assert(#exported.Presets.Items==2 and files["Fixtures/settings_first_shared-preset_2.json"]==inactiveBytes)
    assert(files[pathA]==savedA and files[pathB]==savedB,"Export cannot rewrite either account's saved progress")
    local third=account("third")
    local imported=third.Import(exported);third.Activate(imported)
    assert(third.Seed.Settings.ProgressionFloor==nil and third.Seed.Settings.AccountProgression)
    files["Fixtures/preset_legacy_index.json"]=encode({Version=1,Count=1,Manual=1,Outside=1,Between=0,Auto=false})
    files["Fixtures/preset_legacy_1.json"]=encode(package)
    local legacySettings={Version=1,AccountProgression=true,ProgressionFloor=7,ProgressionBossCleared=true,
        ProgressionBossClearedName="Own legacy boss"}
    files["Fixtures/settings_legacy_preset_1.json"]=encode(legacySettings)
    local migrated=account("legacy");local migratedId=migrated.Preferences.Count
    migrated.Activate(migratedId)
    local ownerSettings=decode(files[migrated.SettingsPath])
    assert(not migrated.Seed and ownerSettings.ProgressionFloor==7 and ownerSettings.ProgressionBossClearedName=="Own legacy boss",
        "Legacy migration preserves the migrating account's private checkpoint")
    local stranger=account("stranger");stranger.Activate(migratedId)
    for key in pairs(private)do assert(stranger.Seed.Settings[key]==nil,"Migration cannot share the owner's checkpoint")end
    print("PASS Private progression: old/new preset seeds, root/library export, account overrides and bootstrap checkpoint isolation")
end
