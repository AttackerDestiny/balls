-- Native phase envelopes: FireWave has a 3.5s swept plane; CreateGyzer is timed.
return function(ctx)
    local api={Active=false,Seen=0,Moves=0,Plans=0,Released=0}
    local hazards={}
    local connection
    local shelter
    local disposed=false
    local now=ctx.Now or os.clock
    local function receive(boss,operation,skill,phase,point,duration)
        if disposed or not ctx.State.AeganatosDodge or not ctx.IsBoss(boss)then return end
        if operation=="Initial"and skill=="OceanGyzer"and ctx.PlayerPosition then
            local predicted=ctx.PlayerPosition()
            if predicted then
                if #hazards>=32 then table.remove(hazards,1)end
                hazards[#hazards+1]={Kind=skill,Point=predicted,Radius=ctx.GyzerRadius+8,Expires=now()+18,Provisional=true,Boss=boss}
                api.Seen+=1
            end
            return
        end
        if operation~="RunPhase"or typeof(point)~="Vector3"then return end
        local record
        if skill=="OmegaWave"and phase=="FireWave"then
            local frame=ctx.Frame(boss)
            if not frame then return end
            local direction=frame.LookVector
            local travel=tonumber(duration)or 0
            record={Kind=skill,Frame=CFrame.lookAt(point,point+direction),
                Width=ctx.WaveSize.X/2+8,Height=ctx.WaveSize.Y/2+8,
                Length=ctx.WaveSize.Z+math.abs(travel)+12,Expires=now()+4.5}
        elseif skill=="OceanGyzer"and phase=="CreateGyzer"then
            for i=#hazards,1,-1 do if hazards[i].Provisional and hazards[i].Boss==boss then table.remove(hazards,i)end end
            record={Kind=skill,Point=point,Radius=ctx.GyzerRadius+8,Expires=now()+math.clamp(tonumber(duration)or 3,0,20)+1.2}
        end
        if record then
            if #hazards>=32 then table.remove(hazards,1)end
            hazards[#hazards+1]=record;api.Seen+=1
        end
    end
    if ctx.Replicate then connection=ctx.Replicate:Connect(receive)end
    local function contains(record,point)
        if record.Kind=="OceanGyzer"then return ((point-record.Point)*Vector3.new(1,0,1)).Magnitude<record.Radius end
        local localPoint=record.Frame:PointToObjectSpace(point)
        return math.abs(localPoint.X)<record.Width and math.abs(localPoint.Y)<record.Height
            and localPoint.Z<8 and localPoint.Z>-record.Length
    end
    function api.Plan(point,desired)
        api.Active=false
        if disposed then return end
        for i=#hazards,1,-1 do if now()>=hazards[i].Expires then table.remove(hazards,i)end end
        local s=ctx.State
        if not s.AeganatosDodge or s.StopEverything or s.SafeModePanic or s.ModeratorBlocking or s.TravelBusy or s.AutoTradeBusy then return end
        local danger
        for _,record in ipairs(hazards)do if contains(record,point)or contains(record,desired)then danger=record;break end end
        if not danger then
            if shelter then api.Released+=1 end
            shelter=nil
            return
        end
        api.Plans+=1
        if shelter then
            local safe=ctx.Valid(shelter.Point)
            for _,record in ipairs(hazards)do if contains(record,shelter.Point)then safe=false;break end end
            if safe then api.Active=true;return shelter.Point,shelter.Kind end
            shelter=nil
        end
        local alreadySafe=ctx.Valid(point)
        for _,record in ipairs(hazards)do if contains(record,point)then alreadySafe=false;break end end
        if alreadySafe then shelter={Point=point,Kind=danger.Kind};api.Active=true;return point,danger.Kind end
        local candidates={}
        if danger.Kind=="OmegaWave"then
            local p=danger.Frame:PointToObjectSpace(point)
            candidates={danger.Frame:PointToWorldSpace(Vector3.new(danger.Width+5,p.Y,p.Z)),
                danger.Frame:PointToWorldSpace(Vector3.new(-danger.Width-5,p.Y,p.Z)),
                Vector3.new(point.X,danger.Frame.Position.Y-danger.Height-6,point.Z)}
        else
            local radius=danger.Radius+5
            for i=0,7 do local angle=i*math.pi/4;candidates[#candidates+1]=danger.Point+Vector3.new(math.cos(angle)*radius,point.Y-danger.Point.Y,math.sin(angle)*radius)end
        end
        local best,cost
        for _,candidate in ipairs(candidates)do
            local valid=ctx.Valid(candidate)
            for _,record in ipairs(hazards)do if contains(record,candidate)then valid=false;break end end
            local distance=(candidate-point).Magnitude
            if valid and distance<=180 and(not cost or distance<cost)then best=candidate;cost=distance end
        end
        if best then shelter={Point=best,Kind=danger.Kind};api.Active=true;api.Moves+=1;return best,danger.Kind end
    end
    function api.Reset()table.clear(hazards);shelter=nil;api.Active=false end
    function api.Destroy()if disposed then return end;disposed=true;if connection then connection:Disconnect()end;api.Reset()end
    return api
end
