return function(source)
    local saves,resets=0,0
    local a,b,c={Id="a",PlaceId=1},{Id="b",PlaceId=1},{Id="c",PlaceId=2}
    local state={MultiSpotSelected={c=true},MultiSpotOrder={"c"},SaveNow=function()saves+=1 end,
        IsAutomationFloorUnlocked=function()return true end}
    local run=assert(loadstring(source.."\nreturn state"))
    setfenv(run,setmetatable({state=state,catalog={Aliases={oldA="a"},SpotById={a=a,b=b,c=c},Spots={a,b,c}},
        multi={Reset=function()resets+=1 end},refresh=function()end,game={PlaceId=1}},{__index=getfenv()}))
    run()
    assert(state.SetMultiSpotSelections({a=true,b=true},{"b","a"}))
    assert(state.MultiSpotOrder[1]=="c"and state.MultiSpotOrder[2]=="b"and state.MultiSpotOrder[3]=="a"and state.MultiSpotSelected.c)
    assert(saves==1 and resets==1,"A priority change uses a single save/reset")
    state.SetMultiSpotSelection("a",false);state.SetMultiSpotSelection("oldA",true)
    assert(state.MultiSpotOrder[2]=="b"and state.MultiSpotOrder[3]=="a","Reselection appends without losing another floor's priority")
    local before=saves
    assert(not state.SetMultiSpotSelections({invalid=true},{"invalid"})and saves==before)
    assert(state.MultiSpotSelected.a and state.MultiSpotSelected.b,"Invalid updates cannot partially replace the saved selection")
    print("PASS Multi Spot priority adapter: click order, cross-floor preservation, single save, deselect/reselect, alias and invalid rollback")
end
