return function(swingSource)
    local now,plays,stops=0,0,0
    local function track()
        local value={Length=.6,IsPlaying=false}
        function value:Play(_,_,speed) assert(speed==1,"Use normal animation playback speed");self.IsPlaying=true; plays+=1 end
        function value:Stop() self.IsPlaying=false; stops+=1 end
        return value
    end
    local state={Running=true,Enabled=true,AutoSwing=true,Nearby=0,SwingStarts=0,
        WeaponSkills={Ready=true,Style="Spear"},SkillVisuals={AllowSwingTrack=function() end}}
    local environment=setmetatable({state=state,player={Character={FindFirstChildOfClass=function() return {Health=100} end}},
        Actions={animations={Spear={Swing1=track(),Swing2=track(),Swing3=track()}}},
        Combat={CalculateCombatStyle=function() return "Spear" end},requestSave=function() end,
        os={clock=function() return now end}},{__index=getfenv()})
    local chunk=assert(loadstring(swingSource.."\nreturn {Update=updateAutoSwing,Stop=stopSword}"))
    setfenv(chunk,environment)
    local api=chunk()
    api.Update(); now=.55; api.Update()
    assert(plays==1,"Do not cut off a normal swing to start the next one early")
    now=.71;api.Update()
    assert(plays==2 and state.SwordSwinging,"Keep swinging at normal cadence with zero nearby enemies")
    state.SkillCastRunning=true; now=1.42; api.Update()
    assert(plays==3,"Visual swings must continue independently of damage skill casts")
    state.Enabled=false; api.Update()
    assert(not state.SwordSwinging and stops>0,"Disable Kill Aura must stop its continuous animation")
    state.Enabled=true; state.StopEverything=true; now=2; api.Update()
    assert(plays==3,"Master pause must stop idle swings too")
    return {Passed=true,NoEnemySwing=true,NormalPlaybackSpeed=true,NoEarlyRestart=true,NoExtraDamageRequests=true,PauseRespected=true}
end
