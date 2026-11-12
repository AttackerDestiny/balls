return function(source,cleanup,antiAfkSource,inputSource)
    local function signal()
        local s={Connected=0}
        function s:Connect(fn)
            self.Callback=fn;self.Connected+=1
            local connected=true
            return {Disconnect=function()if connected then connected=false;self.Connected-=1 end end}
        end
        return s
    end
    local idled,destroying=signal(),signal()
    local pulses=0
    local chunk=assert(loadstring(source.."\nreturn {State=menuState,Stop=function()"..cleanup.." end}"))
    setfenv(chunk,setmetatable({bootstrapFeatures={AntiAfk=assert(loadstring(antiAfkSource))(),IdleInput=assert(loadstring(inputSource))()},
        player={Idled=idled},runtimeOwner={Root={Destroying=destroying}},
        game={GetService=function(_,name)assert(name=="VirtualUser");return {
            CaptureController=function()end,ClickButton2=function()pulses+=1 end}
        end},workspace={CurrentCamera={CFrame={}}},Vector2={zero={}},task={wait=function()end}},{__index=getfenv()}))
    local menu=chunk()
    assert(pulses==0 and idled.Connected==1 and destroying.Connected==1,"Menu startup must only install idle protection")
    idled.Callback();assert(pulses==1,"The idle event remains protected while the Start menu is resting")
    destroying.Callback();assert(idled.Connected==0 and not menu.State.Running)
    idled.Callback();assert(pulses==1,"A replaced menu cannot send stale idle input")
    menu.Stop();menu.Stop();assert(destroying.Connected==0 and idled.Connected==0)
    local nextMenu=chunk();assert(idled.Connected==1 and destroying.Connected==1)
    nextMenu.Stop();assert(idled.Connected==0 and destroying.Connected==0,"Menu completion detaches both idle and lifetime listeners")
    print("PASS Menu Anti-AFK: idle-only pulse during rest, replacement cancellation, no stale input and listener cleanup")
end
