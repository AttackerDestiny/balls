return function(helpers,hop)
    local function fixture(fail,yields,inBetween)
        local state={Running=true,SoloServerSearch={Ticket={LastBlockedUserId=2}}}
        local order={}
        local env=setmetatable({state=state,os={clock=function()return 0 end},game={PlaceId=10},player={},inBetween=inBetween,
            kickFallback={Requested=function(id)assert(id==2);order[#order+1]="arm"end},
            TeleportService={Teleport=function()
                order[#order+1]="request"
                if yields then coroutine.yield()end
                if fail then error("native refusal")end
                order[#order+1]="returned"
            end}},{__index=getfenv()})
        local chunk=assert(loadstring(helpers.."\nlocal ctx={"..hop.."}\nreturn ctx.Hop"));setfenv(chunk,env)
        return state,order,chunk()
    end
    local state,order,run=fixture(false);assert(pcall(run))
    assert(table.concat(order,",")=="arm,request,returned"and state.SafeRejoinRequested)
    state,order,run=fixture(true);assert(not pcall(run))
    assert(table.concat(order,",")=="arm,request"and not state.SafeRejoinRequested)
    state,order,run=fixture(false,true)
    local thread=coroutine.create(run);assert(coroutine.resume(thread))
    assert(table.concat(order,",")=="arm,request","Fallback is ready even if native Teleport yields")
    assert(coroutine.resume(thread));assert(table.concat(order,",")=="arm,request,returned")
    state,order,run=fixture(false,false,true)
    assert(pcall(run) and table.concat(order,",")=="arm" and not state.SafeRejoinRequested and not state.AutomationTeleporting,
        "The Between sends the confirmed block to the kick worker before any teleport request")
    state.SoloServerSearch.Ticket.LastBlockedUserId=nil
    assert(not pcall(run) and #order==1,"The Between must have a confirmed block before starting the kick worker")
    print("PASS Direct rejoin: fallback armed before yielding request, confirmed target identity, refusal cleanup and no movement")
end
