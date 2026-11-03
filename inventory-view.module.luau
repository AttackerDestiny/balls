-- Supplied source uses profile upvalue #2 of Inventory.GetInventoryData.
-- Verify its identity first; never change replicated inventory instances.
return function(ctx)
    local fn,original,owned
    local api={}
    function api.Set(profile)
        local ok,reason=pcall(function()
            if not profile then
                if owned then
                    if ctx.Read(fn,2)==owned then ctx.Write(fn,2,original)end
                    owned=nil
                end
                return
            end
            if not fn then
                local candidate=ctx.Function()
                assert(type(candidate)=="function","Native inventory renderer unavailable")
                local profile=ctx.Read(candidate,2)
                assert(profile==ctx.OwnProfile,"Inventory renderer profile layout differs from the supplied source")
                fn,original=candidate,profile
            end
            local current=ctx.Read(fn,2)
            assert(current==original or current==owned,"Inventory renderer is controlled by another script")
            ctx.Write(fn,2,profile)
            assert(ctx.Read(fn,2)==profile,"Executor did not switch inventory profile")
            owned=profile
        end)
        return ok,not ok and tostring(reason)or nil
    end
    return api
end
