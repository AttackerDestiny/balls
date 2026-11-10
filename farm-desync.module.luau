-- Follow the verified surface while the existing farm controller owns the underground body.
return function(ctx)
    local api={Active=false,Status="Off"}
    local session,root,floor,sample,nextProbe
    local function releaseCamera()
        local old=session
        session=nil;api.Active=false
        if not old then return end
        if old.Render then old.Render:Disconnect()end
        if old.Camera.Parent and old.Camera.CameraSubject==old.Proxy then
            local _,humanoid=ctx.Character()
            old.Camera.CameraSubject=old.Subject.Parent and old.Subject or humanoid
        end
        old.Proxy:Destroy()
    end
    function api.Release(reason)
        releaseCamera()
        root,floor,sample,nextProbe=nil,nil,nil,nil
        api.Status=reason or "Off"
    end
    local function distanceSquared(a,b)
        local x,z=a.X-b.X,a.Z-b.Z
        return x*x+z*z
    end
    function api.Update(now)
        if not ctx.Allowed(now)then api.Release("Waiting for farm movement");return end
        local current,humanoid=ctx.Character()
        if not current then api.Release("Waiting for character");return end
        if current~=root then api.Release();root=current end
        local point=root.Position
        if not sample or now>=nextProbe or distanceSquared(point,sample)>12*12 or math.abs(point.Y-sample.Y)>10 then
            floor=ctx.Surface(root,point);sample=point;nextProbe=now+.25
        end
        local depth=floor and floor-point.Y
        if not depth or depth<6 or depth>45 then
            releaseCamera();api.Status="Waiting for verified underground position";return
        end
        local camera=ctx.Camera()
        if session and (camera~=session.Camera or camera.CameraSubject~=session.Proxy)then releaseCamera()end
        if session then return end
        local subject=camera and camera.CameraSubject
        if subject~=humanoid and subject~=root then api.Status="Waiting for character camera";return end
        local proxy=ctx.CreateProxy()
        local active={Camera=camera,Subject=subject,Proxy=proxy}
        session=active
        local function render()
            if session~=active then return end
            if not root.Parent or ctx.Camera()~=camera or camera.CameraSubject~=proxy then releaseCamera();return end
            local at=root.Position
            local currentDepth=floor-at.Y
            if distanceSquared(at,sample)>32*32 or currentDepth<6 or currentDepth>45 then releaseCamera();return end
            ctx.MoveProxy(proxy,at,floor+ctx.CameraHeight(humanoid,root))
        end
        local ok=pcall(function()
            ctx.MoveProxy(proxy,point,floor+ctx.CameraHeight(humanoid,root))
            camera.CameraSubject=proxy
            active.Render=ctx.Render:Connect(render)
        end)
        if not ok then releaseCamera();api.Status="Character camera unavailable";return end
        api.Active=true;api.Status="Underground · surface camera"
    end
    api.Destroy=api.Release
    return api
end
