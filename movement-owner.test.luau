return function(source)
    local s={Running=true,AutoFarm=true}
    local api=assert(loadstring(source))()(s)
    assert(api.CanFarm(0)and s.MovementOwner=="Farm")
    s.TravelBusy=true;assert(not api.CanFarm(1)and s.MovementOwner=="Arena travel")
    s.SafeModePanic=true;assert(api.Resolve(2)=="Safety")
    s.ModeratorBlocking=true;assert(api.Resolve(3)=="Moderator")
    s.StopEverything=true;assert(api.Resolve(4)=="Stopped")
    s.StopEverything=false;s.ModeratorBlocking=false;s.SafeModePanic=false;s.TravelBusy=false
    assert(api.Resolve(5)=="Farm","Clearing an owning state immediately releases movement without a restart")
    s.BlackoutHolding=true;assert(not api.CanFarm(5.1)and api.Owner=="Dodge","The fixed Darkness hold owns movement even while skills are active")
    s.BlackoutHolding=false;assert(api.CanFarm(5.2))
    s.FarmPauseUntil=7;assert(not api.CanFarm(6));assert(api.CanFarm(8))
    s.AutoFarm=false;assert(api.CanFarm(9)and api.Owner=="Manual","Manual ownership allows farm constraints to be released")
    print("PASS Movement ownership: safety, trade, travel, dodge and recovery priorities release without stale leases")
end
