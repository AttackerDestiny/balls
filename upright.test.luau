return function(moduleSource)
    local create=assert(loadstring(moduleSource))()
    local root=Instance.new("Part")
    root.CFrame=CFrame.new(12,30,50)*CFrame.Angles(0,.7,math.pi/2)
    local before=root.Position
    local flags={[Enum.HumanoidStateType.FallingDown]=true,[Enum.HumanoidStateType.Ragdoll]=false}
    local humanoid={Parent=true,Health=100,PlatformStand=true,Sit=true,State=Enum.HumanoidStateType.Physics}
    function humanoid:GetStateEnabled(k) return flags[k] end
    function humanoid:SetStateEnabled(k,v) flags[k]=v end
    function humanoid:GetState() return self.State end
    function humanoid:ChangeState(k) self.State=k end
    local character={FindFirstChild=function() return root end,FindFirstChildOfClass=function() return humanoid end}
    local controlled=true
    local align={Parent=true}
    local state={}
    local api=create({State=state,Player={Character=character},Controlled=function() return controlled end,Orientation=function() return align end})
    local ok,result=pcall(function()
        api.Update(true)
        assert(root.CFrame.UpVector.Y>.999 and root.Position==before,"Stand upright without changing farm position")
        assert(align.CFrame.UpVector.Y>.999 and align.Enabled,"Orientation hold must target world up")
        assert(not humanoid.PlatformStand and not humanoid.Sit and humanoid.State==Enum.HumanoidStateType.GettingUp,"Recover from the physics/seated pose")
        controlled=false; api.Update(true)
        assert(flags[Enum.HumanoidStateType.FallingDown] and not flags[Enum.HumanoidStateType.Ragdoll],"Restore original state flags when farm control ends")
        root.CFrame*=CFrame.Angles(0,0,math.pi/2)
        api.Update(true)
        assert(root.CFrame.UpVector.Y<.01,"Do not force posture after releasing control")
        return {Passed=true,PositionPreserved=true,Upright=true,StateFlagsRestored=true}
    end)
    api.Destroy(); root:Destroy()
    if not ok then error(result) end
    return result
end
