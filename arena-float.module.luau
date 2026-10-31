-- Counter gravity after a one-shot arena trip without pinning a position.
return function(ctx)
    local api={}
    local attachment,force,nextUpdate
    function api.Release()
        if force then force:Destroy();force=nil end
        if attachment then attachment:Destroy();attachment=nil end
        api.Root=nil
    end
    function api.Attach(root)
        if root.Anchored then return end
        if api.Root==root and force and force.Parent then return end
        api.Release();api.Root=root
        attachment=ctx.Create("Attachment",{Name="SB2ArenaFloatAttachment"},root)
        force=ctx.Create("VectorForce",{Name="SB2ArenaFloat",Attachment0=attachment,
            ApplyAtCenterOfMass=true,RelativeTo=Enum.ActuatorRelativeTo.World,
            Force=Vector3.new(0,root.AssemblyMass*ctx.Workspace.Gravity,0)},root)
        nextUpdate=0
    end
    function api.Update(now)
        if not api.Root then return end
        if not api.Root.Parent or api.Root.Anchored or ctx.Root()~=api.Root then api.Release();return end
        if now<(nextUpdate or 0) then return end
        nextUpdate=now+.5
        force.Force=Vector3.new(0,api.Root.AssemblyMass*ctx.Workspace.Gravity,0)
    end
    api.Destroy=api.Release
    return api
end
