return function(source)
    local files,values={},{}
    local writes=0
    local function encode(value)values[#values+1]=value;return tostring(#values)end
    local function fixture(user)
        local state={Build="test",StorageBootstrap={Ensure=function()return true end}}
        local chunk=assert(loadstring(source.."\nreturn recordFailure"))
        local scope={state=state,player={UserId=user},game={JobId="job",PlaceId=11},
            HttpService={JSONEncode=function(_,value)return encode(value)end,JSONDecode=function(_,bytes)return values[tonumber(bytes)]end},
            isfile=function(path)return files[path]~=nil end,readfile=function(path)return files[path]end,
            writefile=function(path,bytes)writes+=1;files[path]=bytes end}
        setfenv(chunk,setmetatable(scope,{__index=getfenv()}))
        return {State=state,Scope=scope,Record=chunk()}
    end
    local f=fixture(10)
    assert(not f.State.LastSafeFailure and writes==0,"Reading diagnostics cannot create input or settings writes")
    f.State.LastBlockInput={Method="Mouse",Dispatched=true,Attempt=2,X=120,Y=240,Errors={string.rep("x",1000),"Denied","Third","Extra"}}
    f.Record({At=123,Phase="Waiting",Reason=string.rep("r",3000),TargetUserId=20,TargetName="Target"})
    local stored=f.State.LastSafeFailure
    assert(stored.UserId==10 and stored.TargetUserId==20 and #stored.Reason==1500
        and #stored.Input.Errors==3 and #stored.Input.Errors[1]==400 and stored.Input.Method=="Mouse",
        "Only bounded useful block-failure fields are persisted")
    assert(writes==1 and not f.State.SafeFailureSaveError)
    local reload=fixture(10)
    assert(reload.State.LastSafeFailure.TargetUserId==20,"The previous failure survives runtime reloads and server changes")
    local other=fixture(11)
    assert(not other.State.LastSafeFailure,"An account cannot inherit another account's diagnostics")
    files["SB2Codex/safe-failure_11.json"]=files["SB2Codex/safe-failure_10.json"]
    assert(not fixture(11).State.LastSafeFailure,"Even copied files require matching account identity")
    f.Scope.writefile=function()error("No filesystem")end
    f.Record({At=124,Phase="Preparing",Reason="Queue unavailable"})
    assert(f.State.LastSafeFailure.Reason=="Queue unavailable"and not f.State.LastSafeFailure.Input
        and f.State.SafeFailureSaveError,"A disk error preserves the useful runtime observation without retaining stale input")
    files["SB2Codex/safe-failure_10.json"]=string.rep("x",8193)
    assert(not fixture(10).State.LastSafeFailure,"Oversized diagnostic files cannot be loaded")
    print("PASS Safe failure records: bounded details, account isolation, reload persistence, missing storage and stale-input guards")
end
