return function(source,resumeSource)
    local make=assert(loadstring(source))()
    local files,encoded={},{}
    local function encode(value)
        encoded[#encoded+1]=value
        return tostring(#encoded)
    end
    local function fixture(account,inBetween,folder)
        return make({Folder=folder or "SB2Codex",UserId=account,InBetween=inBetween,Available=true,
            Encode=encode,Decode=function(value)return encoded[tonumber(value)]end,
            Exists=function(path)return files[path]~=nil end,Read=function(path)return files[path]end,
            List=function()
                local paths={};for path in pairs(files)do paths[#paths+1]=path end;return paths
            end,
            Write=function(path,bytes)files[path]=bytes end,Validate=function(value)
                assert(value.Format=="FeatherConfig");return value
            end})
    end
    local a=fixture("42",false)
    local outside={Format="FeatherConfig",Settings={Version=1,SafeMode=true},CustomSpots={["10"]={{Name="Outside"}}}}
    local between={Format="FeatherConfig",Settings={Version=1,AutoDodge=true},CustomSpots={["20"]={{Name="Inside"}}}}
    assert(a.SavePreset(outside)==1 and a.SavePreset(between)==2 and a.Resolve()==0,"Import numbers presets without applying them")
    a.Set("Manual",1);a.Set("Outside",1);a.Set("Between",2);a.Set("Auto",true)
    local b=fixture("43",true)
    b.Activate()
    assert(b.ActiveId==2 and b.Seed==between and b.Seed.CustomSpots["20"][1].Name=="Inside")
    assert(b.SettingsPath=="SB2Codex/settings_43_shared-preset_2.json" and b.SpotPrefix=="custom-spots_shared-preset_2_")
    assert(b.SharedSettingsPath=="SB2Codex/shared-preset_2_settings.json")
    files[b.SettingsPath]=encode({Version=1,AutoDodge=false})
    local resumed=fixture("43",true);resumed.Activate()
    assert(resumed.ActiveId==2 and not resumed.Seed,"Loading a preset again must preserve its edits")
    local outsideAgain=fixture("42",false);outsideAgain.Activate()
    assert(outsideAgain.ActiveId==1 and outsideAgain.Seed==outside and outsideAgain.SettingsPath~=b.SettingsPath)
    assert(b.Resolve(0)==0 and b.Resolve(1)==1,"An explicit manual load overrides the automatic choice")
    b.Set("Auto",false);assert(fixture("42",true).Resolve()==1,"Auto off loads the manual selection")
    assert(fixture("44",true).Preferences.Count==2,"The entire library is visible across accounts")
    a.Set("Outside",2)
    b.Set("Between",1)
    assert(b.Preferences.Outside==2,"Route edits read the newest index before saving")
    assert(a.SavePreset(outside)==3 and b.Refresh().Count==3)
    b.Set("Outside",3);b.Set("Between",2);b.Set("Auto",true)
    assert(fixture("42",false).Resolve()==3,"An alt can save the shared outside preset")
    assert(fixture("44",true).Resolve()==2,"An alt can save the shared inside preset")
    files["SB2Codex/shared-preset_3_settings.json"]=encode({Version=1,SafeMode=false})
    files["SB2Codex/custom-spots_shared-preset_3_30.json"]=encode({Version=1,PlaceId=30,Areas={{Name="Shared saved spot"}}})
    local active={Settings=between.Settings,CustomSpots=between.CustomSpots}
    local exported=b.ExportLibrary(active)
    assert(exported.Active==2 and exported.Items[2]==active)
    assert(exported.Items[3].Settings.SafeMode==false and exported.Items[3].CustomSpots["30"][1].Name=="Shared saved spot")
    local destination=fixture("46",false,"OtherWorkspace")
    assert(destination.Import(outside)==1,"Single-profile imports still make one preset")
    assert(destination.Import({Settings=active.Settings,CustomSpots=active.CustomSpots,Presets=exported})==3)
    assert(destination.Load(1).Settings.SafeMode==true,"Import retains existing slots")
    local importedOutside=fixture("47",false,"OtherWorkspace");importedOutside.Activate()
    local importedBetween=fixture("48",true,"OtherWorkspace");importedBetween.Activate()
    assert(importedOutside.ActiveId==4 and importedOutside.Seed.Settings.SafeMode==false)
    assert(importedBetween.ActiveId==3 and importedBetween.Seed.Settings.AutoDodge)
    local baseExport=a.ExportLibrary({Settings=outside.Settings,CustomSpots=outside.CustomSpots})
    assert(baseExport.Active==0)
    assert(destination.Import({Settings=outside.Settings,CustomSpots=outside.CustomSpots,Presets=baseExport})==8)
    assert(destination.Load(8).Settings.SafeMode and destination.Preferences.Outside==7)
    a.Set("Outside",2);a.Set("Auto",false)

    files["SB2Codex/preset_45_index.json"]=encode({Version=1,Count=1,Manual=1,Outside=1,Auto=true})
    files["SB2Codex/preset_45_1.json"]=encode(outside)
    files["SB2Codex/settings_45_preset_1.json"]=encode({Version=1,SafeMode=false})
    files["SB2Codex/custom-spots_45_preset_1_30.json"]=encode({Version=1,PlaceId=30,Areas={{Name="Migrated spot"}}})
    local migrated=fixture("45",false)
    local package=migrated.Load(4)
    assert(migrated.Preferences.Count==4 and migrated.Preferences.Outside==2 and not migrated.Preferences.Auto)
    assert(package.Settings.SafeMode==false and package.CustomSpots["30"][1].Name=="Migrated spot")
    assert(fixture("45",false).Preferences.Count==4,"Migration is idempotent")
    files["SB2Codex/shared-preset_1.json"]=nil
    local missing=fixture("42",false);missing.Activate()
    assert(not missing.ActiveId and missing.Error,"A missing preset falls back to the base settings")
    local function resume(path)
        local env={SB2AutomationResumeConfigPath="outside",SB2AutomationResumeFeatures={AutoFarm=true},SB2SoloResumeTicket={Active=true}}
        local chunk=assert(loadstring(resumeSource))
        setfenv(chunk,{env=env,configPath=path});chunk()
        assert(env.SB2AutomationResumeConfigPath==nil)
        return env
    end
    local switched=resume("inside")
    assert(not switched.SB2AutomationResumeFeatures and not switched.SB2SoloResumeTicket,"A teleport cannot override a different preset's settings")
    local same=resume("outside")
    assert(same.SB2AutomationResumeFeatures and same.SB2SoloResumeTicket,"Same-preset teleports keep normal resume data")
    print("PASS Config presets: cross-account route edits, portable library remapping, legacy migration, checkpoints and saved spots")
end
