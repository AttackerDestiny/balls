-- Runs the current public controls, then restores their original selections.
return function()
    assert(string.find(tostring(identifyexecutor()),"Potassium",1,true),"Potassium is not the active executor")
    local state=getgenv().SB2KillAura
    assert(state and state.Running,"Run the latest source before this test")
    local report={Version=state.Version,Executor=identifyexecutor(),Started=os.clock(),Done=false,Phases={},BlueHidden=0,BlueVisible=0,Events={}}
    getgenv().SB2PotassiumTest=report
    local saved={Skill=state.SelectedSkill,Style=state.WeaponSkills.Style,Revision=state.WeaponSkills.Version,
        Preference=state.SkillPerWeapon[state.WeaponSkills.Style],Kill=state.Enabled,Farm=state.AutoFarm,Aura=state.SkillAura,
        Dodge=state.AutoDodge,SaveSuspended=state.AutoSaveSuspended}
    local activeSkill
    state.AutoSaveSuspended=true
    local connection=workspace.ChildAdded:Connect(function(part)
        if part:IsA("Part") and part.Name=="Part" then task.delay(.12,function()
            if part.Parent and activeSkill=="Summon Rifle" and part.Material==Enum.Material.Neon and part.BrickColor==BrickColor.new("Bright blue") then
                if part.LocalTransparencyModifier==1 then report.BlueHidden+=1 else report.BlueVisible+=1 end
            end
        end) end
    end)
    task.spawn(function()
        local ok,message=pcall(function()
            state.SetEnabled(true); state.SetAutoFarm(true); state.SetSkillAura(true); state.SetAutoDodge(true)
            for _,name in ipairs({"Summon Pistol","Summon Rifle"}) do
                report.CurrentPhase=name
                assert(state.SetSelectedSkill(name),"Skill is not compatible: "..name)
                activeSkill=name
                local phase={Skill=name,NormalDamage=0,NormalBursts=0,Casts={},Warnings=0}
                report.Phases[#report.Phases+1]=phase
                local seen,castSeen={},{}
                local start,hits=os.clock(),state.HitsSent
                repeat
                    task.wait(.08)
                    if getgenv().SB2KillAura~=state or state.WeaponSkills.Version~=saved.Revision or state.SelectedSkill~=name
                        or not state.SkillAura or not state.AutoFarm or not state.Enabled then report.Interrupted=true; break end
                    phase.Warnings=math.max(phase.Warnings,state.BossThreatCount or 0)
                    local event=state.WaveDodge.Event
                    if event then report.Events[event]=true end
                    local character=game.Players.LocalPlayer.Character
                    local entity=character and character:FindFirstChild("Entity")
                    local health=entity and entity:FindFirstChild("Health")
                    if health then
                        phase.StartHealth=phase.StartHealth or health.Value
                        phase.MinHealth=math.min(phase.MinHealth or health.Value,health.Value)
                        phase.EndHealth=health.Value
                        if event=="Blackout" then
                            report.DarknessSamples=(report.DarknessSamples or 0)+1
                            report.DarknessStartHP=report.DarknessStartHP or health.Value
                            report.DarknessMinHP=math.min(report.DarknessMinHP or health.Value,health.Value)
                        end
                    end
                    for _,burst in ipairs(state.AttackBurstHistory) do
                        if not seen[burst] and (burst.FinishedAt or 0)>start then
                            seen[burst]=true; phase.NormalBursts+=1; phase.NormalDamage+=(burst.Damage or 0)
                        end
                    end
                    local burst=state.LastSkillBurst
                    if burst and burst.Skill==name and burst.ObservationFinished and not castSeen[burst] and (burst.ActivationAt or 0)>start then
                        castSeen[burst]=true
                        phase.Casts[#phase.Casts+1]={Ack=burst.ActivationAcknowledged,Damage=burst.Damage,Requests=burst.TotalRequests,Status=burst.Status}
                    end
                until os.clock()-start>(name=="Summon Pistol" and 12 or 18)
                phase.BasicRequests=state.HitsSent-hits
                if report.Interrupted then break end
            end
        end)
        connection:Disconnect()
        if getgenv().SB2KillAura==state then
            if state.WeaponSkills.Version==saved.Revision and state.SelectedSkill==activeSkill then
                state.SetSelectedSkill(saved.Skill); state.SkillPerWeapon[saved.Style]=saved.Preference; report.Restored=saved.Skill
            end
            if not report.Interrupted then
                state.SetAutoFarm(saved.Farm); state.SetEnabled(saved.Kill); state.SetSkillAura(saved.Aura); state.SetAutoDodge(saved.Dodge)
            end
            state.AutoSaveSuspended=saved.SaveSuspended; state.SaveNow()
            report.VersionLabel=state.UI.Panel.Version.Text
            report.SkillError=state.LastSkillError; report.VisualError=state.LastVisualError; report.DodgeError=state.LastDodgeError
        end
        report.OK=ok; report.Error=not ok and tostring(message) or nil
        report.Ended=os.clock(); report.Done=true; report.CurrentPhase="Complete"
        pcall(function() writefile("SB2Codex/latest_test_"..game.Players.LocalPlayer.UserId..".json",game:GetService("HttpService"):JSONEncode(report)) end)
    end)
    return report
end
