return function(source)
    local factory=assert(loadstring("return function(state,ctx,readfile,isfile,loadstring,typeof,queue_on_teleport) local writefile=function()end;local queue,savedSource,validatedSource,validatedPath,validatedGeneration\n"..source.."\nreturn queuePreflight end"))()
    local reads,compiles=0,0
    local files={one="build -- BEGIN BUNDLED SERVER ISOLATION",two="build -- BEGIN BUNDLED SERVER ISOLATION"}
    local storage={Generation=0,Ensure=function()return true end}
    local state={SavedScriptPath="one",Build="build",StorageBootstrap=storage}
    local check=factory(state,{},function(path)reads+=1;return files[path]end,function(path)return files[path]~=nil end,
        function(text)compiles+=1;if text:find("invalid",1,true)then return nil end;return function()end end,type,function()end)
    check();assert(reads==1 and compiles==1)
    for _=1,10 do check()end
    assert(reads==1 and compiles==1,"Repeated rejoin preflight must reuse validated source")
    storage.Generation=1;check();assert(reads==2 and compiles==1,"Storage rewrites invalidate the read cache")
    state.SavedScriptPath="two";check();assert(reads==3)
    files.two=nil;assert(not pcall(check),"A missing cached file must still fail closed")
    files.two="wrong build source";storage.Generation=2;assert(not pcall(check),"Changed storage must revalidate the build")
    files.two="build invalid -- BEGIN BUNDLED SERVER ISOLATION";assert(not pcall(check),"Invalid source cannot authorize rejoin")
    print("PASS Safe Mode preflight: cached read/compile, storage/path invalidation and missing/wrong/invalid source guards")
end
