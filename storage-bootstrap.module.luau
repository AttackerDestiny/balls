-- Executor paths are relative to its workspace; never add a second "workspace".
-- Existing account settings/tickets are preserved. The runnable entry passes its
-- own embedded body so this can persist a complete, dependency-free loader.
return function(ctx)
    local api={Ready=false,Generation=0,Created={}}
    local folder="SB2Codex"
    local sourcePath=folder.."/kill-aura.luau"
    local cachedPath=type(ctx.Build)=="string"and (folder.."/source_"..ctx.Build:gsub("[^%w_-]","_")..".luau")or sourcePath
    api.SourcePath=cachedPath
    local saved=false
    local fullSource=type(ctx.Source)=="string"and ctx.Prefix..ctx.Source..ctx.Suffix or nil
    local function ensureFile(path,value)
        if not ctx.IsFile(path)then
            ctx.Write(path,value);api.Generation+=1;api.Created[path]=true
        end
    end
    function api.Ensure(verifySource)
        local ok,message=pcall(function()
            assert(type(ctx.IsFile)=="function"and type(ctx.Read)=="function"and type(ctx.Write)=="function",
                "This executor does not provide file storage for automatic rejoin")
            assert(fullSource,"Run the complete kill-aura.luau entry to install automatic rejoin")
            if type(ctx.IsFolder)=="function"then
                if not ctx.IsFolder(folder)then
                    assert(type(ctx.MakeFolder)=="function","This executor cannot create SB2Codex")
                    local made,reason=pcall(ctx.MakeFolder,folder)
                    assert(made or ctx.IsFolder(folder),tostring(reason))
                end
            elseif type(ctx.MakeFolder)=="function"then
                -- Executors without isfolder may report an existing folder as an error.
                pcall(ctx.MakeFolder,folder)
            end
            if (verifySource and cachedPath==sourcePath)or not saved or not ctx.IsFile(sourcePath)then
                if not ctx.IsFile(sourcePath)or ctx.Read(sourcePath)~=fullSource then
                    ctx.Write(sourcePath,fullSource);api.Generation+=1;api.Created[sourcePath]=true
                end
                saved=true
            end
            if cachedPath~=sourcePath and (verifySource or not ctx.IsFile(cachedPath))then
                if not ctx.IsFile(cachedPath)or ctx.Read(cachedPath)~=fullSource then
                    ctx.Write(cachedPath,fullSource);api.Generation+=1;api.Created[cachedPath]=true
                end
            end
            ensureFile(folder.."/settings_"..ctx.UserId..".json",ctx.Encode({Version=1}))
            ensureFile(folder.."/solo-search_"..ctx.UserId..".json",ctx.Encode({Version=1,Active=false,UserId=ctx.UserId,PlaceId=ctx.PlaceId}))
            ensureFile(folder.."/destinations_"..ctx.PlaceId..".json",ctx.Encode({Version=1,PlaceId=ctx.PlaceId,Areas={}}))
        end)
        api.Ready=ok;api.Error=not ok and tostring(message)or nil
        return ok,api.Error
    end
    api.Ensure(true)
    return api
end
