-- Source autofarm geometry: height-corrected center and an outer attack radius.
-- A position must satisfy both attack reach and body clearance; never clamp an
-- unsafe position closer just to keep hitting.
return function(input)
    local enemy,playerRoot=input.Enemy,input.Player
    local size=enemy.Size
    local reach=math.min(120,input.Reach or (math.max(size.X,size.Z)*.5+20))
    local radius=math.min(math.max(size.X,size.Z)*.5+19,reach-(input.Margin or 2))
    if radius<=0 then return nil,"No usable attack reach" end
    if input.Mode=="Above" and input.AdaptiveAbove then
        local minimum=(input.PlayerBelow or 3)+1.5
        local center=input.Center or enemy.Position+Vector3.new(0,(playerRoot.Size.Y-size.Y)*.5,0)
        local offset=math.min(200,math.max(minimum,center.Y-enemy.Position.Y+radius))
        local distance=math.abs(offset-(center.Y-enemy.Position.Y))
        if offset<minimum then return nil,"Above cap leaves no body clearance" end
        if distance>reach-.2 then return nil,"Above position is outside the learned hit range" end
        local destination=enemy.Position+Vector3.new(0,offset,0)
        if destination.Y<=(input.DestroyHeight or -500)+40 then return nil,"Offset crosses the map kill plane" end
        return {Destination=destination,Offset=offset,Radius=distance,Reach=reach,
            Minimum=minimum,Center=center,Mode="Above"}
    end
    local center=input.Center or enemy.Position+Vector3.new(0,(playerRoot.Size.Y-size.Y)*.5,0)
    local above=input.Mode=="Above"
    local direction=above and 1 or -1
    local destination=center+Vector3.new(0,direction*radius,0)
    local offset=destination.Y-enemy.Position.Y
    local limited=math.clamp(offset,-60,200)
    if limited~=offset then
        offset=limited
        destination=Vector3.new(destination.X,enemy.Position.Y+offset,destination.Z)
        radius=math.abs(destination.Y-center.Y)
        if radius>reach-(input.Margin or 2) then return nil,"Offset cap is outside attack reach" end
    end
    local body=above and (input.BodyAbove or size.Y*.5) or (input.BodyBelow or size.Y*.5)
    local playerExtent=above and (input.PlayerBelow or 3) or (input.PlayerAbove or 3)
    local minimum=body+playerExtent+1.5
    if offset*direction<minimum then return nil,"No body clearance inside attack reach" end
    if destination.Y<=(input.DestroyHeight or -500)+40 then return nil,"Offset crosses the map kill plane" end
    return {Destination=destination,Offset=offset,Radius=radius,Reach=reach,
        Minimum=minimum,Center=center,Mode=above and "Above" or "Below"}
end
