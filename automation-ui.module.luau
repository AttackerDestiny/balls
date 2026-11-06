-- Publish automation status into lightweight records consumed by modern WindUI.
return function(ctx)
    local state=ctx.State
    local defaults={SafeModeStatus="Safe Mode is off",MultiSpotStatus="Multi Spot is off",AutoJoinFriendStatus="Auto Join Friend is off"}
    local inputs={"SafeMode","SafeFloor","SafeWhitelist","MultiSpot","MultiSpotDropdown","AutoJoinFriend","JoinFriendUsername"}
    local function record(name)
        local value=ctx.Create("TextBox",{Name=name,Text=state[name]or ""},ctx.Parent)
        state.UI[name]=value
        return value
    end
    for _,name in ipairs(inputs)do record(name)end
    for name in pairs(defaults)do record(name)end
    state.UI.SafeWhitelist.Text=state.SafeWhitelistText or ""
    state.CloseAutomationMenus=function()end
    local api={}
    function api.Refresh()
        for name,fallback in pairs(defaults)do
            local text=state[name]or fallback
            if state.UI[name].Text~=text then state.UI[name].Text=text end
        end
    end
    api.Refresh()
    return api
end
