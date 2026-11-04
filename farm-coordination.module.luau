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
    function api.Deadline(killedAt,seconds)
        return math.ceil((killedAt+seconds)*2)/2
    end
    return api
end
