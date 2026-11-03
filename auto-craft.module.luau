-- One acknowledged forge request at a time; never retry a stalled spend blindly.
return function(ctx)
    local api={}
    local pending,nextTry=nil,0
    local recipes={{Output="Legendary Upgrade Crystal",Input="Rare Upgrade Crystal"},
        {Output="Rare Upgrade Crystal",Input="Uncommon Upgrade Crystal"}}
    function api.Reset()api.Paused=false;nextTry=0 end
    function api.Update(now)
        if not ctx.Active()then return end
        if pending then
            local input,output=ctx.Count(pending.Input),ctx.Count(pending.Output)
            if input<=pending.BeforeInput-pending.Required and output>=pending.BeforeOutput+1 then
                pending=nil;api.Paused=false;nextTry=now+.2;ctx.Status("Crystal crafted")
            elseif now-pending.At>=10 then
                api.Paused=true;ctx.Status("Craft not acknowledged · waiting without duplicate requests")
            end
            if pending then return end
        end
        if api.Paused or ctx.Busy()or now<nextTry then return end
        nextTry=now+.5
        for _,recipe in ipairs(recipes)do
            if ctx.Selected(recipe.Output)then
                local required=ctx.Recipe(recipe.Output,recipe.Input)
                if type(required)=="number"and required>0 and required%1==0 then
                    local input,output=ctx.Count(recipe.Input),ctx.Count(recipe.Output)
                    if input>=required then
                        pending={Input=recipe.Input,Output=recipe.Output,Required=required,BeforeInput=input,BeforeOutput=output,At=now}
                        local ok,reason=pcall(ctx.Send,recipe.Output)
                        if not ok then api.Paused=true;ctx.Status("Craft request failed · "..tostring(reason))
                        else ctx.Status("Crafting "..recipe.Output)end
                        return
                    end
                end
            end
        end
    end
    return api
end
