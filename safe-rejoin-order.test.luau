return function(helpers,hop)
    local function fixture(fail,yields)
        local state={Running=true}
        local order,queue={},{}
        state.EscapeSafeRejoin=function()order[#order+1]="away";state.SafeRejoinAway={}end
        local env=setmetatable({state=state,os={clock=function()return 0 end},game={PlaceId=10},player={},
            task={defer=function(fn)queue[#queue+1]=fn end},
            TeleportService={Teleport=function()
                order[#order+1]="request"
                if yields then coroutine.yield()end
                if fail then error("native refusal")end
                order[#order+1]="returned"
            end}},{__index=getfenv()})
        local chunk=assert(loadstring(helpers.."\nlocal ctx={"..hop.."}\nreturn ctx.Hop"));setfenv(chunk,env)
        local run=chunk()
        local function flush()for _,fn in ipairs(queue)do fn()end;table.clear(queue)end
        return state,order,run,flush
    end
    local state,order,run,flush=fixture(false);assert(pcall(run));flush()
    assert(table.concat(order,",")=="request,returned,away"and state.SafeRejoinRequested)
    state,order,run,flush=fixture(true);assert(not pcall(run));flush()
    assert(#order==1 and order[1]=="request"and not state.SafeRejoinRequested and state.SafeRejoinAway==nil)
    state,order,run,flush=fixture(false,true)
    local thread=coroutine.create(run);assert(coroutine.resume(thread));assert(#order==1)
    flush();assert(table.concat(order,",")=="request,away","Move on first scheduler turn even while native Teleport is yielding")
    assert(coroutine.resume(thread));assert(table.concat(order,",")=="request,away,returned")
    state,order,run,flush=fixture(false,true);thread=coroutine.create(run);assert(coroutine.resume(thread))
    state.SafeRejoinDispatch={};flush();assert(#order==1,"Stale dispatch cannot move the character")
    print("PASS Rejoin dispatch: request-before-move, escape during yield, no duplicate move, refusal cleanup, stale callback rejection")
end
