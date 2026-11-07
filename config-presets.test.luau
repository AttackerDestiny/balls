return function(source,resumeSource)
    local make=assert(loadstring(source))()
    local files,encoded={},{}
    local function encode(value)
        encoded[#encoded+1]=value
        return tostring(#encoded)
    end
    local function fixture(account,inBetween)
        return make({Folder="SB2Codex",UserId=account,InBetween=inBetween,Available=true,
            Encode=encode,Decode=function(value)return encoded[tonumber(value)]end,
            Exists=function(path)return files[path]~=nil end,Read=function(path)return files[path]end,
            Write=function(path,bytes)files[path]=bytes end,Validate=function(value)
                assert(value.Format=="FeatherConfig");return value
            end})
    end
    local a=fixture("42",false)
    local outside={Format="FeatherConfig",Settings={Version=1,SafeMode=true},CustomSpots={["10"]={{Name="Outside"}}}}
    local between={Format="FeatherConfig",Settings={Version=1,AutoDodge=true},CustomSpots={["20"]={{Name="Inside"}}}}
    assert(a.SavePreset(outside)==1 and a.SavePreset(between)==2 and a.Resolve()==0,"Import numbers presets without applying them")
    a.Set("Manual",1);a.Set("Outside",1);a.Set("Between",2);a.Set("Auto",true)
    local b=fixture("42",true)
    b.Activate()
    assert(b.ActiveId==2 and b.Seed==between and b.Seed.CustomSpots["20"][1].Name=="Inside")
    assert(b.SettingsPath=="SB2Codex/settings_42_preset_2.json" and b.SpotPrefix=="custom-spots_42_preset_2_")
    files[b.SettingsPath]=encode({Version=1,AutoDodge=false})
    local resumed=fixture("42",true);resumed.Activate()
    assert(resumed.ActiveId==2 and not resumed.Seed,"Loading a preset again must preserve its edits")
    local outsideAgain=fixture("42",false);outsideAgain.Activate()
    assert(outsideAgain.ActiveId==1 and outsideAgain.Seed==outside and outsideAgain.SettingsPath~=b.SettingsPath)
    assert(b.Resolve(0)==0 and b.Resolve(1)==1,"An explicit manual load overrides the automatic choice")
    b.Set("Auto",false);assert(fixture("42",true).Resolve()==1,"Auto off loads the manual selection")
    assert(fixture("43",true).Preferences.Count==0,"Presets are isolated by account")
    files["SB2Codex/preset_42_1.json"]=nil
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
    print("PASS Config presets: numbered imports, independent account and place routes, preserved edits, saved spots and missing-file fallback")
end
