-- Borrow the native inventory profile slot only while its identity is ours.
return function(ctx)
    local slot=nil
    local function resolve()
        if slot then return slot end
        local renderer=ctx.Function()
        assert(type(renderer)=="function","Native inventory renderer unavailable")
        local original=ctx.Read(renderer,2)
        assert(original==ctx.OwnProfile,"Inventory renderer profile layout differs from the supplied source")
        slot={Renderer=renderer,Original=original}
        return slot
    end
    local api={}
    function api.Set(profile)
        local success,reason=pcall(function()
            if profile==nil then
                if slot and slot.Borrowed then
                    if ctx.Read(slot.Renderer,2)==slot.Borrowed then ctx.Write(slot.Renderer,2,slot.Original)end
                    slot.Borrowed=nil
                end
                return
            end
            local current=resolve()
            local actual=ctx.Read(current.Renderer,2)
            assert(actual==current.Original or actual==current.Borrowed,"Inventory renderer is controlled by another script")
            ctx.Write(current.Renderer,2,profile)
            assert(ctx.Read(current.Renderer,2)==profile,"Executor did not switch inventory profile")
            current.Borrowed=profile
        end)
        if success then return true,nil end
        return false,tostring(reason)
    end
    return api
end
