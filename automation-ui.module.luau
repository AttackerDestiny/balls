-- Controller status bridge. Modern WindUI is the only interactive interface.
return function(ctx)
    local state=ctx.State
    local api={}
    local fields={"SafeMode","SafeFloor","SafeWhitelist","SafeModeStatus","MultiSpot","MultiSpotDropdown",
        "MultiSpotStatus","AutoJoinFriend","JoinFriendUsername","AutoJoinFriendStatus"}
    for _,name in ipairs(fields)do
        state.UI[name]=ctx.Create("TextBox",{Name=name,Text=""},ctx.Parent)
    end
    state.UI.SafeWhitelist.Text=state.SafeWhitelistText or ""
    function state.CloseAutomationMenus()end
    function api.Refresh()
        state.UI.SafeModeStatus.Text=state.SafeModeStatus or "Safe Mode is off"
        state.UI.MultiSpotStatus.Text=state.MultiSpotStatus or "Multi Spot is off"
        state.UI.AutoJoinFriendStatus.Text=state.AutoJoinFriendStatus or "Auto Join Friend is off"
    end
    api.Refresh()
    return api
end
