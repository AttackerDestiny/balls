-- Own a single vertical-velocity constraint for the current character root.
return function(ctx)
    local api={}
    local owned
    local due=0
    function api.Release()
        local record=owned;owned=nil;api.Root=nil
        if not record then return end
        record.Velocity:Destroy();record.Attachment:Destroy()
    end
    function api.Attach(root)
        if (ctx.Active and not ctx.Active())then api.Release();return end
        if root.Anchored then return end
        if owned and api.Root==root and owned.Velocity.Parent then return end
        api.Release()
        local anchor=ctx.Create("Attachment",{Name="SB2ArenaFloatAttachment"},root)
        local velocity=ctx.Create("LinearVelocity",{Name="SB2ArenaFloat",Attachment0=anchor,
            RelativeTo=Enum.ActuatorRelativeTo.World,VelocityConstraintMode=Enum.VelocityConstraintMode.Line,
            LineDirection=Vector3.new(0,1,0),LineVelocity=0,ForceLimitsEnabled=false},root)
        owned={Attachment=anchor,Velocity=velocity};api.Root=root;due=0
    end
    function api.Update(now)
        if ctx.Active and not ctx.Active()then api.Release();return end
        if not owned then return end
        local root=api.Root
        if not root.Parent or root.Anchored or ctx.Root()~=root then api.Release();return end
        if now>=due then owned.Velocity.LineVelocity=0;due=now+.5 end
    end
    api.Destroy=api.Release
    return api
end
