-- Own the surface camera and, in manual mode, one reversible underground hold.
return function(ctx)
    local api={Active=false,Status="Off"}
    local session,root,floor,sample,nextProbe,hold
    local function releaseCamera()
        local old=session
        session=nil;api.Active=false
        if not old then return end
        if old.Render then old.Render:Disconnect()end
        if old.Subject.Parent and old.Subject.CameraOffset==old.Applied then old.Subject.CameraOffset=old.Base end
    end
    function api.Release(reason,restore)
        releaseCamera()
        if hold then
            local old=hold;hold=nil
            ctx.EndHold(old,restore==true)
        end
        root,floor,sample,nextProbe=nil,nil,nil,nil
        api.Status=reason or "Off"
    end
    local function distanceSquared(a,b)
        local x,z=a.X-b.X,a.Z-b.Z
        return x*x+z*z
    end
    function api.Update(now)
        local mode,reason,restore=ctx.Mode(now)
        if not mode then api.Release(reason,restore);return end
        local current,humanoid=ctx.Character()
        if not current then api.Release("Waiting for character");return end
        if current~=root then api.Release();root=current end
        if mode~="Hold" and hold then
            api.Release("Waiting for farm movement");root=current
        end
        if hold and not ctx.HoldValid(hold)then
            api.Release("Position changed · finding ground again",true);return
        end
        local point=root.Position
        if hold then
            floor=hold.Floor;sample=hold.Position
        elseif not sample or now>=nextProbe or distanceSquared(point,sample)>12*12 or math.abs(point.Y-sample.Y)>10 then
            floor=(mode=="Hold" and ctx.Ground(root,point)or nil)or ctx.Surface(root,point)
            sample=point;nextProbe=now+.25
        end
        if mode=="Hold" and not hold and floor then
            hold=ctx.BeginHold(root,humanoid,floor)
            if not hold then api.Status="Unable to hold underground";return end
            point=root.Position;sample=hold.Position
        end
        local depth=floor and floor-point.Y
        if not depth or depth<6 or depth>45 then
            releaseCamera();api.Status=mode=="Hold" and "Waiting for nearby solid ground" or "Waiting for Auto Farm to move below ground";return
        end
        local camera=ctx.Camera()
        if session and (camera~=session.Camera or camera.CameraSubject~=session.Subject)then releaseCamera()end
        if session then return end
        local subject=camera and camera.CameraSubject
        if not camera or subject~=humanoid then
            api.Active=hold~=nil
            api.Status=hold and "Holding underground · camera is viewing another subject" or "Waiting for character camera"
            return
        end
        local active={Camera=camera,Subject=humanoid,Base=humanoid.CameraOffset}
        session=active
        local function render()
            if session~=active then return end
            if not root.Parent or not humanoid.Parent or ctx.Camera()~=camera or camera.CameraSubject~=humanoid then releaseCamera();return end
            local at=root.Position
            local currentDepth=floor-at.Y
            if distanceSquared(at,sample)>32*32 or currentDepth<6 or currentDepth>45 then releaseCamera();return end
            local currentOffset=humanoid.CameraOffset
            if currentOffset~=active.Applied then active.Base=currentOffset end
            local offset=ctx.CameraOffset(root,active.Base,currentDepth)
            if offset~=currentOffset then humanoid.CameraOffset=offset end
            active.Applied=humanoid.CameraOffset
        end
        local ok=pcall(function()
            render()
            active.Render=ctx.Render:Connect(render)
        end)
        if not ok then releaseCamera();api.Status="Character camera unavailable";return end
        api.Active=true;api.Status=hold and "Holding 20 studs below ground" or "Auto Farm · surface camera active"
    end
    return api
end
