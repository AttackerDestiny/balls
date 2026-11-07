return function(source)
    local state={AutoFarm=true}
    local game={PlaceId=6144637080}
    local root={};local data={Root={Position={Y=60}}}
    local player={Character={FindFirstChild=function()return root end}}
    local fn=assert(loadstring(source.."\nreturn state.ResolveAutoOffset"))
    setfenv(fn,setmetatable({state=state,game=game,player=player,getMobData=function()return data end,
        Vector3={new=function(x,y,z)return {X=x,Y=y,Z=z}end}},{__index=getfenv()}))
    local resolve=fn()
    local boss={Name="Suspended Unborn"}
    assert(resolve(boss)==10)
    local point=state.AutoOffsetDestination
    assert(point.X==-2439 and point.Y==70 and point.Z==5389 and state.FixedFarmPosition==point)
    data.Root.Position.Y=1000;resolve(boss)
    assert(state.AutoOffsetDestination.Y==70,"Boss movement must not move the requested farm position")
    resolve({Name="Radioactive Experiment"})
    assert(not state.FixedFarmPosition,"Other targets retain the default positioning path")
    game.PlaceId=78945654064532
    assert(resolve(boss)=="default" and not state.FixedFarmPosition,"The Between uses the live enemy position")
    game.PlaceId=6144637080
    state.AutoFarm=false;assert(resolve(boss)=="default","Kill Aura alone must not acquire the farming position")
    print("PASS Suspended Unborn: exact supplied XYZ plus 10 height, fixed during boss movement, normal targets and manual Kill Aura")
end
