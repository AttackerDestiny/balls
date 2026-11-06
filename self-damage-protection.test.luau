return function(source)
    local create=assert(loadstring(source))()
    local calls=0
    local native={DamageLocalPlayer=function(amount,label)calls+=1;return amount,label end}
    local original=native.DamageLocalPlayer
    local state={Running=true}
    local api=create({State=state,Native=native})
    assert(native.DamageLocalPlayer==original,"Default OFF does not intercept anything")
    assert(api.Set(true));assert(native.DamageLocalPlayer(10,"Wave")==nil and calls==0 and api.Blocked==1)
    state.StopEverything=true;local amount,label=native.DamageLocalPlayer(10,"Wave")
    assert(amount==10 and label=="Wave"and calls==1,"Pause forwards the original arguments and returns")
    state.StopEverything=false;api.Set(false);assert(native.DamageLocalPlayer==original)
    api.Set(true);local wrapper=native.DamageLocalPlayer
    local newer=function(...)return wrapper(...)end
    native.DamageLocalPlayer=newer;api.Destroy();api.Destroy()
    assert(native.DamageLocalPlayer==newer,"Cleanup cannot replace a newer owner's wrapper")
    native.DamageLocalPlayer(5,"Skill");assert(calls==2,"A retired wrapper becomes a forwarding function")
    assert(not api.Set(true),"Disposed protection cannot restart")
    print("PASS Self-damage protection: native-only interception, opt-in, pause, argument forwarding and ownership cleanup")
end
