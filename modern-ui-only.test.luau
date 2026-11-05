return function(source)
    local state={Running=true}
    local panel={Visible=true};local show={Visible=false}
    local restarts=0
    state.RestartScript=function()restarts+=1 end
    local fn=assert(loadstring(source))
    setfenv(fn,setmetatable({state=state,panel=panel,showUI=show},{__index=getfenv()}));fn()
    state.SetUIVisible(true)
    assert(not panel.Visible and show.Visible and state.UIHidden and restarts==0,"A loading modern UI cannot reveal legacy controls")
    state.WindUIError="Initialization failed";state.SetUIVisible(true)
    assert(not panel.Visible and restarts==1,"The feather button retries the modern runtime without old UI")
    state.Running=false;state.SetUIVisible(true)
    assert(not panel.Visible and not show.Visible and restarts==1,"A stopped runtime cannot show or restart UI")
    print("PASS Legacy visibility path remains hidden during loading, errors, reload and shutdown")
end
