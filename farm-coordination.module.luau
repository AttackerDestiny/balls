-- Lua-only coordination: shared server-time beats and common destination geometry.
-- This does not exchange state between clients or promise a network barrier.
return function(ctx)
    local api={}
    local last={}
    local step=.25
    function api.Ready(channel)
        local epoch=math.floor(ctx.Now()/step)
        local previous=last[channel]
        if previous==nil then last[channel]=epoch;return false end
        if epoch>previous then last[channel]=epoch;return true end
        return false
    end
    function api.Position(point)
        local function snap(value)return math.floor(value*2+.5)/2 end
        return ctx.Vector(snap(point.X),snap(point.Y),snap(point.Z))
    end
    local roster,rosterAt,slot,count=nil,0,1,1
    local held=setmetatable({}, {__mode="k"})
    function api.Spread(point,mob,center,reach)
        if not ctx.Members then return point end
        local now=ctx.Now()
        if not roster or now>=rosterAt then
            rosterAt=now+1
            roster=ctx.Members()
            table.sort(roster,function(a,b)return a.UserId<b.UserId end)
            slot,count=1,math.max(1,#roster)
            for i,person in ipairs(roster)do if person.UserId==ctx.UserId then slot=i;break end end
        end
        local radius=count>1 and math.min(12,4/(2*math.sin(math.pi/count)))or 0
        if center and reach then
            -- Preserve vertical body clearance. Reserve space for position snapping.
            local vertical=math.abs(point.Y-center.Y)+.5
            radius=math.min(radius,math.sqrt(math.max(0,(math.max(0,reach-1))^2-vertical^2))-.5)
            radius=math.max(0,radius)
        end
        local angle=(slot-1)*2*math.pi/count
        local result=api.Position(ctx.Vector(point.X+math.cos(angle)*radius,point.Y,point.Z+math.sin(angle)*radius))
        local previous=held[mob]
        if previous and previous.Slot==slot and previous.Count==count then
            local p=previous.Point
            local distance=(result.X-p.X)^2+(result.Y-p.Y)^2+(result.Z-p.Z)^2
            if distance<.75^2 then return p end
        end
        held[mob]={Point=result,Slot=slot,Count=count}
        api.Slot,api.Count,api.Spacing=slot,count,count>1 and 2*radius*math.sin(math.pi/count)or 0
        return result
    end
    function api.Deadline(killedAt,seconds)
        return math.ceil((killedAt+seconds)*2)/2
    end
    return api
end
