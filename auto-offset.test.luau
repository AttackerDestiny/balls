return function(moduleSource)
    local solve=assert(loadstring(moduleSource))()
    local playerRoot={Size=Vector3.new(2,2,1),Position=Vector3.zero}
    local enemy={Size=Vector3.new(8,14,8),Position=Vector3.new(0,100,0)}
    local input={Enemy=enemy,Player=playerRoot,Mode="Below",Reach=24,Margin=2,
        BodyBelow=7,BodyAbove=7,PlayerAbove=3,PlayerBelow=3,DestroyHeight=-500}
    local result=assert(solve(input))
    assert(result.Offset==-28,"Below offset must include the source -6 stud center correction")
    assert(result.Radius==22 and (result.Destination-result.Center).Magnitude<24,"Outer placement must stay inside registered attack reach")
    assert(-result.Offset>18,"Do not reuse the earlier flat 18-stud offset on a tall root")
    input.Mode="Above"
    result=assert(solve(input))
    assert(result.Offset==16 and result.Destination.Y>enemy.Position.Y,"Blackout placement must remain above the actual mob")
    input.BodyAbove=40
    local blocked=solve(input)
    assert(not blocked,"Do not move inside the body or below a Blackout mob to satisfy reach")
    input.Mode="Below"; input.BodyBelow=45
    assert(not solve(input),"Unreachable body clearance must skip the target instead of moving closer")
    input.BodyBelow=7; enemy.Position=Vector3.new(0,-450,0)
    assert(not solve(input),"Never clamp a deep offset closer across the kill plane")
    enemy.Position=Vector3.new(0,100,0); enemy.Size=Vector3.new(400,80,250)
    input.BodyBelow=40; input.Reach=120
    result=assert(solve(input))
    assert(result.Radius==118 and result.Offset==-157,"Raw offset may exceed 120 when height correction requires it; corrected attack distance cannot")
    enemy.Size=Vector3.new(8,14,8); input.BodyBelow=7; input.Reach=20
    result=assert(solve(input))
    assert(result.Radius==18 and result.Offset==-24,"Learned reach must recalculate geometry, not discard height correction")
    return {Passed=true,HeightCorrected=true,UnreachableTargetsRejected=true,KillPlaneChecked=true}
end
