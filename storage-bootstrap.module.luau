-- Self-installation is a small journal of idempotent writes, not a reset.
return function(ctx)
    local directory="SB2Codex"
    local stable=directory.."/kill-aura.luau"
    local versioned=type(ctx.Build)=="string"and directory.."/source_"..ctx.Build:gsub("[^%w_-]","_")..".luau"or stable
    local entry=type(ctx.Source)=="string"and ctx.Prefix..ctx.Source..ctx.Suffix or nil
    local api={Ready=false,Generation=0,Created={},SourcePath=versioned}
    local installed=false
    local function write(path,text)
        ctx.Write(path,text)
        api.Generation+=1;api.Created[path]=true
    end
    local function source(path,inspect)
        local exists=ctx.IsFile(path)
        if not exists or (inspect and ctx.Read(path)~=entry)then write(path,entry)end
    end
    local function directoryReady()
        if ctx.IsFolder then
            if ctx.IsFolder(directory)then return end
            assert(type(ctx.MakeFolder)=="function","This executor cannot create SB2Codex")
            local ok,reason=pcall(ctx.MakeFolder,directory)
            assert(ok or ctx.IsFolder(directory),tostring(reason))
        elseif ctx.MakeFolder then pcall(ctx.MakeFolder,directory)end
    end
    local function newFile(path,value)
        if not ctx.IsFile(path)then write(path,ctx.Encode(value))end
    end
    local function synchronize(verify)
        for _,name in ipairs({"IsFile","Read","Write"})do
            assert(type(ctx[name])=="function","This executor does not provide file storage for automatic rejoin")
        end
        assert(entry,"Run the complete kill-aura.luau entry to install automatic rejoin")
        directoryReady()
        if not installed or not ctx.IsFile(stable)or (verify and stable==versioned)then source(stable,true);installed=true end
        if versioned~=stable then source(versioned,verify==true)end
        newFile(directory.."/settings_"..ctx.UserId..".json",{Version=1})
        newFile(directory.."/solo-search_"..ctx.UserId..".json",{Version=1,Active=false,UserId=ctx.UserId,PlaceId=ctx.PlaceId})
    end
    function api.Ensure(verify)
        local ok,reason=pcall(synchronize,verify)
        api.Ready=ok;api.Error=not ok and tostring(reason)or nil
        return api.Ready,api.Error
    end
    api.Ensure(true)
    return api
end
