-- Server-clock beats and roster-indexed formation slots require no external service.
return function(ctx)
    local api={}
    local beats={}
    local formation={Due=0,Index=1,Count=1}
    local holds=setmetatable({}, {__mode="k"})
    function api.Ready(channel)
        local beat=math.floor(ctx.Now()*4)
        local seen=beats[channel]
        if seen==nil then beats[channel]=beat;return false end
        if beat<=seen then return false end
        beats[channel]=beat;return true
    end
    local function quantize(value)return math.floor(value*2+.5)/2 end
    function api.Position(point)return ctx.Vector(quantize(point.X),quantize(point.Y),quantize(point.Z))end
    local function refreshRoster(now)
        if formation.Roster and now<formation.Due then return end
        local roster=ctx.Members()
        table.sort(roster,function(a,b)return a.UserId<b.UserId end)
        formation.Roster=roster;formation.Due=now+1;formation.Count=math.max(1,#roster);formation.Index=1
        for index,person in ipairs(roster)do if person.UserId==ctx.UserId then formation.Index=index;break end end
    end
    function api.Spread(point,target,center,reach)
        if not ctx.Members then return point end
        refreshRoster(ctx.Now())
        local count,index=formation.Count,formation.Index
        local sine=count>1 and math.sin(math.pi/count)or 0
        local radius=count>1 and math.min(12,2/sine)or 0
        if center and reach then
            local vertical=math.abs(point.Y-center.Y)+.5
            local usable=math.max(0,reach-1)
            radius=math.max(0,math.min(radius,math.sqrt(math.max(0,usable*usable-vertical*vertical))-.5))
        end
        local angle=(index-1)*2*math.pi/count
        local proposed=api.Position(ctx.Vector(point.X+math.cos(angle)*radius,point.Y,point.Z+math.sin(angle)*radius))
        local old=holds[target]
        if old and old.Index==index and old.Count==count then
            local delta=(proposed.X-old.Point.X)^2+(proposed.Y-old.Point.Y)^2+(proposed.Z-old.Point.Z)^2
            if delta<.5625 then return old.Point end
        end
        holds[target]={Point=proposed,Index=index,Count=count}
        api.Slot=index;api.Count=count;api.Spacing=2*radius*sine
        return proposed
    end
    function api.Deadline(killedAt,seconds)return math.ceil((killedAt+seconds)*2)/2 end
    return api
end
