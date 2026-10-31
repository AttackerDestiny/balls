return function(ctx)
    local api={}
    local nextUpdate=0
    local held,flags
    function api.Rotation(frame)
        local direction=frame.LookVector*Vector3.new(1,0,1)
        if direction.Magnitude<.001 then direction=Vector3.new(0,0,-1) end
        return CFrame.lookAt(Vector3.zero,direction.Unit,Vector3.yAxis)
    end
    function api.Release()
        if held and held.Parent and flags then
            for kind,enabled in pairs(flags) do held:SetStateEnabled(kind,enabled) end
        end
        held,flags=nil,nil
    end
    function api.Update(force)
        local now=os.clock()
        if not force and now<nextUpdate then return end
        nextUpdate=now+.1
        local character=ctx.Player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if not ctx.Controlled() or not root or not humanoid or humanoid.Health<=0 then api.Release(); return end
        if held~=humanoid then
            api.Release()
            held,flags=humanoid,{}
            for _,kind in ipairs({Enum.HumanoidStateType.FallingDown,Enum.HumanoidStateType.Ragdoll}) do
                flags[kind]=humanoid:GetStateEnabled(kind)
                humanoid:SetStateEnabled(kind,false)
            end
        end
        if humanoid.PlatformStand then humanoid.PlatformStand=false end
        if humanoid.Sit then humanoid.Sit=false end
        local kind=humanoid:GetState()
        if kind==Enum.HumanoidStateType.Physics or kind==Enum.HumanoidStateType.FallingDown
            or kind==Enum.HumanoidStateType.Ragdoll or kind==Enum.HumanoidStateType.Seated then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        local rotation=api.Rotation(root.CFrame)
        local align=ctx.Orientation()
        if align and align.Parent then align.CFrame=rotation; align.Enabled=true end
        if root.CFrame.UpVector.Y<.999 then
            root.CFrame=CFrame.new(root.Position)*rotation
            root.AssemblyAngularVelocity=Vector3.zero
            ctx.State.UprightCorrections=(ctx.State.UprightCorrections or 0)+1
        elseif root.AssemblyAngularVelocity.Magnitude>.1 then root.AssemblyAngularVelocity=Vector3.zero end
    end
    api.Destroy=api.Release
    return api
end
