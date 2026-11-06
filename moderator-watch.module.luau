-- Account IDs from the moderator list explicitly supplied by the user.
return function(ctx)
    local ids={
        [12671]=true,
        [4402987]=true,
        [7858636]=true,
        [13444058]=true,
        [24156180]=true,
        [35311411]=true,
        [38559058]=true,
        [45035796]=true,
        [48662268]=true,
        [50879012]=true,
        [51696441]=true,
        [55715138]=true,
        [57436909]=true,
        [59341698]=true,
        [60673083]=true,
        [62240513]=true,
        [66489540]=true,
        [68210875]=true,
        [72480719]=true,
        [75043989]=true,
        [76999375]=true,
        [81113783]=true,
        [90258662]=true,
        [93988508]=true,
        [101291900]=true,
        [102706901]=true,
        [104541778]=true,
        [109105759]=true,
        [111051084]=true,
        [121104177]=true,
        [129806297]=true,
        [151751026]=true,
        [154847513]=true,
        [154876159]=true,
        [161577703]=true,
        [161949719]=true,
        [163733925]=true,
        [167655046]=true,
        [167856414]=true,
        [173116569]=true,
        [184366742]=true,
        [194755784]=true,
        [220726786]=true,
        [225179429]=true,
        [269112100]=true,
        [271388254]=true,
        [309775741]=true,
        [349854657]=true,
        [354326302]=true,
        [357870914]=true,
        [358748060]=true,
        [367879806]=true,
        [371108489]=true,
        [373676463]=true,
        [429690599]=true,
        [434696913]=true,
        [440458342]=true,
        [448343431]=true,
        [454205259]=true,
        [455293249]=true,
        [461121215]=true,
        [478848349]=true,
        [500009807]=true,
        [533787513]=true,
        [542470517]=true,
        [571218846]=true,
        [575623917]=true,
        [630696850]=true,
        [810458354]=true,
        [852819491]=true,
        [874771971]=true,
        [918971121]=true,
        [1033291447]=true,
        [1033291716]=true,
        [1058240421]=true,
        [1099119770]=true,
        [1114937945]=true,
        [1190978597]=true,
        [1266604023]=true,
        [1379309318]=true,
        [1390415574]=true,
        [1416070243]=true,
        [1584345084]=true,
        [1607227678]=true,
        [1648776562]=true,
        [1650372835]=true,
        [1666720713]=true,
        [1728535349]=true,
        [1785469599]=true,
        [1794965093]=true,
        [1801714748]=true,
        [1868318363]=true,
        [1998442044]=true,
        [2034822362]=true,
        [2216826820]=true,
        [2324028828]=true,
        [2462374233]=true,
        [2787915712]=true,
        [360470140]=true,
        [2475151189]=true,
        [3522932153]=true,
        [3772282131]=true,
        [7557087747]=true,
        [5536587740]=true,
        [3931735673]=true,
        [33903799]=true,
        [22026533]=true,
        [417576199]=true,
        [80692318]=true,
        [102583875]=true,
        [492574273]=true,
        [468344010]=true,
        [1560324163]=true,
    }
    local api={Enabled=true,Count=113}
    local lifecycle={closed=false,claimed=false}
    local function publish(message)
        api.Status=message
        ctx.State.ModeratorStatus=message
        if ctx.Notify then pcall(ctx.Notify,message)end
    end
    local function current()
        return not lifecycle.closed and ctx.State.Running~=false and not ctx.State.StopEverything
    end
    local function confirmedExit(person)
        if not current()then return end
        local ok,receipt=pcall(function()
            assert(type(ctx.Block)=="function","Native block handler is unavailable")
            return ctx.Block(person,current)
        end)
        if not current()then return end
        if not ok or receipt~=true then
            api.Failed=true
            ctx.State.ModeratorBlockError=ok and "Roblox did not confirm the moderator block"or tostring(receipt)
            publish("Moderator block failed · automation paused · "..ctx.State.ModeratorBlockError)
            return
        end
        ctx.State.ModeratorBlockConfirmed=true
        ctx.State.ModeratorBlockError=nil
        publish("Moderator blocked · disconnecting")
        if ctx.Save then pcall(ctx.Save)end
        if current()then ctx.Kick("Blocked moderator "..person.Name.." ("..person.UserId.."). Disconnected automatically.")end
    end
    local function observe(person)
        if not current()or lifecycle.claimed or person.UserId==ctx.Players.LocalPlayer.UserId or not ids[person.UserId]then return end
        lifecycle.claimed=true
        ctx.State.ModeratorDetected={Name=person.Name,UserId=person.UserId,At=os.time()}
        ctx.State.ModeratorBlocking=true
        publish("Moderator detected · blocking @"..person.Name.." before disconnect")
        if ctx.Pause then pcall(ctx.Pause,person)end
        if ctx.Save then pcall(ctx.Save)end
        task.defer(confirmedExit,person)
    end
    local subscription=ctx.Players.PlayerAdded:Connect(observe)
    local population=ctx.Players:GetPlayers()
    for index=1,#population do task.defer(observe,population[index])end
    function api.Destroy()
        if lifecycle.closed then return end
        lifecycle.closed=true;api.Enabled=false;subscription:Disconnect()
    end
    return api
end
