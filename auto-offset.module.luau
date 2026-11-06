-- Solve the vertical attack-sphere intersection before accepting body clearance.
return function(input)
    local enemy,player=input.Enemy,input.Player
    local dimensions=enemy.Size
    local widest=math.max(dimensions.X,dimensions.Z)
    local reach=math.min(120,input.Reach or widest*.5+20)
    local outer=math.min(widest*.5+19,reach-(input.Margin or 2))
    if outer<=0 then return nil,"No usable attack reach"end
    local center=input.Center or enemy.Position+Vector3.new(0,(player.Size.Y-dimensions.Y)*.5,0)
    local above=input.Mode=="Above"
    local minimum,destination,radius
    if above and input.AdaptiveAbove then
        minimum=(input.PlayerBelow or 3)+1.5
        local offset=math.max(minimum,center.Y-enemy.Position.Y+outer)
        radius=offset-center.Y+enemy.Position.Y
        if radius>reach-.2 then return nil,"Above position is outside the learned hit range"end
        destination=enemy.Position+Vector3.new(0,offset,0)
    else
        local direction=above and 1 or -1
        local body=above and (input.BodyAbove or dimensions.Y*.5)or (input.BodyBelow or dimensions.Y*.5)
        local extent=above and (input.PlayerBelow or 3)or (input.PlayerAbove or 3)
        minimum=body+extent+1.5
        radius=outer;destination=center+Vector3.new(0,direction*radius,0)
        if (destination.Y-enemy.Position.Y)*direction<minimum then return nil,"No body clearance inside attack reach"end
    end
    if destination.Y<=(input.DestroyHeight or -500)+40 then return nil,"Offset crosses the map kill plane"end
    return {Destination=destination,Offset=destination.Y-enemy.Position.Y,Radius=radius,Reach=reach,
        Minimum=minimum,Center=center,Mode=above and "Above"or "Below"}
end
