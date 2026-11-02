-- In-memory executor filesystem only; no Roblox connection or host file mutation.
return function(source,body,entry,saveSource)
    local make=assert(loadstring(source))()
    local passed=0
    local function test(name,fn)fn();passed+=1;print("PASS "..name)end
    local prefix="local SB2_SOURCE=["..string.rep("=",12).."[\n"
    local suffix="]"..string.rep("=",12).."]\nreturn assert(loadstring(SB2_SOURCE, \"SB2\"))(SB2_SOURCE)\n"
    local function fixture(files)
        local f={Files=files or{},Dirs={},Writes=0,Makes=0,Encoded={}}
        function f.Encode(value)
            local result="fixture-json-"..tostring(#f.Encoded+1)
            f.Encoded[#f.Encoded+1]=value;f.Encoded[result]=value;return result
        end
        function f.Write(path,value)
            assert(not f.Fail,"storage denied")
            assert(f.Dirs.SB2Codex,"Parent directory is missing")
            f.Files[path]=value;f.Writes+=1
        end
        f.Ctx={Source=body,Prefix=prefix,Suffix=suffix,UserId=123,PlaceId=542351431,
            IsFile=function(path)return f.Files[path]~=nil end,
            Read=function(path)assert(f.Files[path]);return f.Files[path]end,
            Write=f.Write,Encode=f.Encode,IsFolder=function(path)return f.Dirs[path]==true end,
            MakeFolder=function(path)f.Dirs[path]=true;f.Makes+=1 end}
        function f.Start()f.Api=make(f.Ctx);return f.Api end
        return f
    end
    test("A fresh executor workspace installs the exact runnable source and all required initial files",function()
        local f=fixture();f.Start()
        assert(f.Api.Ready and f.Makes==1 and f.Writes==4)
        assert(f.Files["SB2Codex/kill-aura.luau"]==entry)
        assert(loadstring(f.Files["SB2Codex/kill-aura.luau"]),"The saved self-copy must compile")
        local ticket=f.Encoded[f.Files["SB2Codex/solo-search_123.json"]]
        assert(ticket.Active==false and ticket.UserId==123 and ticket.PlaceId==542351431)
        assert(f.Encoded[f.Files["SB2Codex/destinations_542351431.json"]].PlaceId==542351431)
    end)
    test("Fresh-device setup preserves existing settings, whitelist, active tickets and destination caches",function()
        local files={["SB2Codex/settings_123.json"]="user preferences + whitelist",
            ["SB2Codex/solo-search_123.json"]="active ticket",["SB2Codex/destinations_542351431.json"]="cached arenas"}
        local f=fixture(files);f.Start()
        assert(f.Api.Ready and f.Writes==1 and f.Files["SB2Codex/settings_123.json"]=="user preferences + whitelist")
        assert(f.Files["SB2Codex/solo-search_123.json"]=="active ticket"and f.Files["SB2Codex/destinations_542351431.json"]=="cached arenas")
    end)
    test("Repeated execution and preflight checks do not rewrite unchanged files",function()
        local f=fixture();f.Start();local writes=f.Writes
        f.Api.Ensure();f.Api.Ensure();f.Start();assert(f.Writes==writes and f.Makes==1)
    end)
    test("Deleted storage is recreated before another automation preflight",function()
        local f=fixture();f.Start();local generation=f.Api.Generation
        f.Files={};f.Dirs={};assert(f.Api.Ensure())
        assert(f.Files["SB2Codex/kill-aura.luau"]==entry and f.Api.Generation>generation and f.Makes==2)
    end)
    test("A different account receives its own files without replacing another account's data",function()
        local f=fixture();f.Start();f.Files["SB2Codex/settings_123.json"]="original user"
        f.Ctx.UserId=456;f.Start()
        assert(f.Files["SB2Codex/settings_123.json"]=="original user"and f.Files["SB2Codex/settings_456.json"])
    end)
    test("Executing an updated build refreshes the saved source without resetting preferences",function()
        local f=fixture();f.Start();f.Files["SB2Codex/settings_123.json"]="saved modes"
        f.Ctx.Source="return 42\n";f.Start()
        assert(f.Files["SB2Codex/kill-aura.luau"]==prefix.."return 42\n"..suffix)
        assert(f.Files["SB2Codex/settings_123.json"]=="saved modes")
    end)
    test("Each build retains its own rejoin source and repairs mismatched cached files",function()
        local f=fixture();f.Ctx.Build="build.1";f.Start()
        local sourcePath=f.Api.SourcePath;assert(sourcePath~="SB2Codex/kill-aura.luau"and f.Files[sourcePath]==entry)
        f.Files["SB2Codex/kill-aura.luau"]="another account's older build"
        assert(f.Api.Ensure(true)and f.Files[sourcePath]==entry)
        f.Files[sourcePath]="wrong saved script"
        assert(f.Api.Ensure(true)and f.Files[sourcePath]==entry)
        local first=sourcePath;f.Ctx.Build="build.2";f.Ctx.Source="return 2";f.Start()
        assert(f.Api.SourcePath~=first and f.Files[first]==entry)
    end)
    test("Unavailable file APIs or denied writes report an error and can recover",function()
        local f=fixture();local read=f.Ctx.Read;f.Ctx.Read=nil;f.Start();assert(not f.Api.Ready and f.Api.Error)
        f.Ctx.Read=read;f.Fail=true;f.Start();assert(not f.Api.Ready and f.Api.Error)
        f.Fail=false;assert(f.Api.Ensure()and f.Files["SB2Codex/kill-aura.luau"]==entry)
    end)
    test("Concurrent folder creation is accepted when the directory already exists",function()
        local f=fixture();f.Ctx.MakeFolder=function(path)f.Dirs[path]=true;error("already exists")end
        f.Start();assert(f.Api.Ready)
    end)
    test("Storage repair forces settings to be rewritten even when the serialized payload is unchanged",function()
        local f=fixture();f.Start()
        local state={StorageBootstrap=f.Api}
        local chunk=assert(loadstring("local lastSavedPayload,lastSavedStorageGeneration\n"..saveSource))
        setfenv(chunk,setmetatable({state=state,filePersistence=true,configFolder="SB2Codex",configPath="SB2Codex/settings_123.json",
            typeof=type,isfolder=f.Ctx.IsFolder,makefolder=f.Ctx.MakeFolder,writefile=f.Write,readfile=f.Ctx.Read,
            HttpService={JSONEncode=function()return "actual current settings"end},settingsPayload=function()return {}end},{__index=getfenv()}))
        chunk();assert(state.SaveNow()and f.Files["SB2Codex/settings_123.json"]=="actual current settings")
        f.Files={};f.Dirs={};assert(state.SaveNow())
        assert(f.Files["SB2Codex/settings_123.json"]=="actual current settings")
        -- A repeated execution may be isolated from the still-running UI's globals.
        -- Its new bootstrap repairs files; the old saver must notice the reset file.
        f.Files={};f.Dirs={};f.Start();assert(state.SaveNow())
        assert(f.Files["SB2Codex/settings_123.json"]=="actual current settings")
    end)
    print("All "..passed.." storage bootstrap scenarios passed")
end
