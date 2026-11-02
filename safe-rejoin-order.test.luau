return function(helpers,hop)
    local function fixture(fail,event)
        local state={Running=true}
        local order={}
        state.EscapeSafeRejoin=function()order[#order+1]="away"end
        local env=setmetatable({state=state,os={clock=function()return 0 end},game={PlaceId=10},player={},
            TeleportService={Teleport=function()
                order[#order+1]="request"
                if fail then error("native refusal")end
            end}},{__index=getfenv()})
        local chunk=assert(loadstring(helpers.."\nlocal ctx={"..hop.."}\nreturn ctx.Hop"));setfenv(chunk,env)
        local run=chunk();return state,order,run
    end
    local state,order,run=fixture(false);assert(pcall(run))
    assert(table.concat(order,",")=="request,away"and state.SafeRejoinRequested)
    state,order,run=fixture(true);assert(not pcall(run))
    assert(#order==1 and order[1]=="request"and not state.SafeRejoinRequested and state.SafeRejoinAway==nil)
    print("PASS Rejoin ordering: native request before away move; refusal clears request and cannot move away")
end
