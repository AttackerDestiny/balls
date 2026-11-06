-- Posture control has an explicit humanoid-state restoration ledger.
return function(ctx)
    local api={}
    local owner,states
    local due=0
    function api.Rotation(frame)
        local flat=frame.LookVector*Vector3.new(1,0,1)
        local forward=flat.Magnitude>=.001 and flat.Unit or Vector3.new(0,0,-1)
        return CFrame.lookAt(Vector3.zero,forward,Vector3.yAxis)
    end
    function api.Release()
        local humanoid,ledger=owner,states
        owner,states=nil,nil
        if humanoid and humanoid.Parent and ledger then
            for state,wasEnabled in pairs(ledger)do humanoid:SetStateEnabled(state,wasEnabled)end
        end
    end
    local function acquire(humanoid)
        if owner==humanoid then return end
        api.Release();owner=humanoid;states={}
        for _,state in ipairs({Enum.HumanoidStateType.FallingDown,Enum.HumanoidStateType.Ragdoll})do
            states[state]=humanoid:GetStateEnabled(state);humanoid:SetStateEnabled(state,false)
        end
    end
    function api.Update(force)
        local now=os.clock()
        if not force and now<due then return end
        due=now+.1
        local character=ctx.Player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if not ctx.Controlled()or not root or not humanoid or humanoid.Health<=0 then api.Release();return end
        acquire(humanoid)
        humanoid.PlatformStand=false;humanoid.Sit=false
        local current=humanoid:GetState()
        for _,bad in ipairs({Enum.HumanoidStateType.Physics,Enum.HumanoidStateType.FallingDown,Enum.HumanoidStateType.Ragdoll,Enum.HumanoidStateType.Seated})do
            if current==bad then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp);break end
        end
        local rotation=api.Rotation(root.CFrame)
        local align=ctx.Orientation()
        if align and align.Parent then align.CFrame=rotation;align.Enabled=true end
        if root.CFrame.UpVector.Y<.999 then
            root.CFrame=CFrame.new(root.Position)*rotation
            ctx.State.UprightCorrections=(ctx.State.UprightCorrections or 0)+1
            root.AssemblyAngularVelocity=Vector3.zero
        elseif root.AssemblyAngularVelocity.Magnitude>.1 then root.AssemblyAngularVelocity=Vector3.zero end
    end
    api.Destroy=api.Release
    return api
end
