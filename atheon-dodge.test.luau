return function(source)
    local count=0
    local function test(name,fn)fn();count+=1;print("PASS "..name)end
    local mt={}
    local function vec(x,y,z)return setmetatable({X=x,Y=y,Z=z},mt)end
    mt.__add=function(a,b)return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
    mt.__sub=function(a,b)return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
    mt.__mul=function(a,b)if type(b)=="number"then return vec(a.X*b,a.Y*b,a.Z*b)end;return vec(a.X*b.X,a.Y*b.Y,a.Z*b.Z)end
    mt.__index=function(a,k)
        if k=="Magnitude"then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)end
        if k=="Dot"then return function(a,b)return a.X*b.X+a.Y*b.Y+a.Z*b.Z end end
    end
    local function fixture()
        local time=0
        local position=vec(0,0,0)
        local boss={}
        local skills={}
        local points={}
        local state={Running=true,AtheonDodge=true,AutoDodge=false,PingMs=50}
        local load=assert(loadstring(source))
        setfenv(load,setmetatable({Vector3={new=vec}},{__index=getfenv()}))
        local ctx={State=state,Native={RiggedEnemies={[boss]={ActiveSkills=skills}}},Now=function()return time end,
            Position=function()return position end,
            Bosses=function()return {boss}end,Collection={GetTagged=function()return points end},Valid=function(p)return p.Y>-400 end}
        local f={State=state,Skills=skills,Points=points,API=load()(ctx)}
        function f.Time(t)time=t end
        function f.Position(p)position=p end
        function f.Grounded(value)ctx.Grounded=function()return value end end
        function f.FireAssets(assets)ctx.FireAssets=function()return assets end end
        function f.Dash(a,b,width)
            skills.FireDash={SurfacePosition=a or vec(0,0,0),FocusPosition=b or vec(100,0,0),Width=width or 50}
        end
        return f
    end
    test("Atheon dash escapes the full native corridor independently of Auto Dodge",function()
        local f=fixture();f.Dash()
        local point,reason=f.API.Plan(vec(50,-20,0))
        assert(point and math.abs(point.Z)>43 and reason=="FireDash" and f.API.Seen.FireDash==1)
        assert(not f.State.AutoDodge)
        f.Skills.FireDash=nil;f.Time(4)
        assert(not f.API.Plan(point),"Resume after flames expire")
    end)
    test("Atheon zero-length dash remains finite and evades",function()
        local f=fixture();f.Dash(vec(0,0,0),vec(0,0,0))
        local p=f.API.Plan(vec(0,-20,0));assert(p and p.Magnitude<200 and p.Magnitude>43)
    end)
    test("Atheon blocks farm re-entry into an active dash",function()
        local f=fixture();f.Dash()
        local current=vec(50,-20,55)
        assert(f.API.Plan(current,vec(50,-20,0))==current)
    end)
    test("Atheon smash leaves the impact center while staying near its ground anchor",function()
        local f=fixture();f.Skills.LavaSmash={Lifetime=3,SurfacePosition=vec(0,0,0)}
        local p,reason=f.API.Plan(vec(0,0,0),nil,function()return 0 end)
        assert(p and p.Y==-20 and (p*vec(1,0,1)).Magnitude>98 and p.Magnitude<=128 and reason=="LavaSmash")
        f.Skills.LavaSmash=nil;f.Time(.5);assert(f.API.Plan(p,vec(0,-20,0),function()return 0 end))
        f.Time(6);assert(not f.API.Plan(p,nil,function()return 0 end))
    end)
    test("Atheon geyser geometry and removal tail prevent early return",function()
        local f=fixture();local marker={Parent=true,Position=vec(0,0,0),Size=vec(40,1,40),IsA=function()return true end}
        f.Points[1]=marker
        local p,reason=f.API.Plan(vec(0,-20,0));assert(p and reason=="LavaGyzer" and p.Magnitude>28)
        f.Points[1]=nil;f.Time(.5);assert(f.API.Plan(vec(0,-20,0)))
        f.Time(2);assert(not f.API.Plan(vec(0,-20,0)))
    end)
    test("Atheon yields to panic travel recovery disable and disposal",function()
        for _,key in ipairs({"SafeModePanic","TravelBusy","Recovering"})do
            local f=fixture();f.Dash();f.State[key]=true
            assert(not f.API.Plan(vec(0,0,0)) and f.API.ThreatCount==0)
        end
        local f=fixture();f.Dash();f.State.AtheonDodge=false;assert(not f.API.Plan(vec(0,0,0)))
        f.State.AtheonDodge=true;f.API.Destroy();assert(not f.API.Plan(vec(0,0,0)))
    end)
    test("unrelated native skills do not trigger Atheon Dodge",function()
        local f=fixture();f.Skills.GasSmoke={}
        assert(not f.API.Plan(vec(0,0,0)) and f.API.ThreatCount==0)
    end)
    test("Atheon refuses deep shelters and keeps every dodge near the boss",function()
        local f=fixture();f.Skills.LavaSmash={Lifetime=3}
        local deep=f.API.Plan(vec(0,0,0),nil,function()return -500 end)
        assert(not deep or deep.Y>=-40)
        local g=fixture();g.Dash()
        for _,point in ipairs({vec(0,-20,0),vec(50,-20,0),vec(90,-20,0),vec(200,-20,0)})do
            local escape=g.API.Plan(point,nil,function()return 0 end)
            if escape then
                assert((escape-point).Magnitude<=112 and escape.Magnitude<=128)
            end
            g.Time(1)
        end
    end)
    test("Atheon stays outside impact after registry removal while the boss is airborne",function()
        local f=fixture()
        f.Skills.LavaSmash={Lifetime=3,SurfacePosition=vec(0,0,0),LastCFrame={Position=vec(0,10,0)}}
        local p=f.API.Plan(vec(0,-20,0),nil,function()return 0 end);assert(p)
        f.Position(vec(0,150,0));f.Time(5);f.Skills.LavaSmash=nil
        assert(f.API.Plan(p,vec(0,-20,0),function()return 0 end))
        assert(f.API.Anchor.Y==0,"Anchor to impact ground rather than the airborne root")
        f.Position(vec(0,10,0));f.Time(6)
        assert(f.API.Plan(p,vec(0,-20,0),function()return 0 end))
        f.Time(6.1);assert(f.API.Plan(p,vec(0,-20,0),function()return 0 end))
        f.Time(6.3);assert(not f.API.Plan(p,nil,function()return 0 end))
    end)
    test("confirmed native completion returns quickly after landing",function()
        local f=fixture()
        local skill={Lifetime=3,SurfacePosition=vec(0,0,0),LastCFrame={Position=vec(0,10,0)}}
        f.Skills.LavaSmash=skill
        local p=f.API.Plan(vec(0,-20,0),nil,function()return 0 end);assert(p)
        f.Position(vec(0,150,0));f.Time(.5)
        assert(f.API.Plan(p,vec(0,-20,0),function()return 0 end))
        skill.Destroyed=true;f.Skills.LavaSmash=nil;f.Time(1)
        assert(f.API.Plan(p,vec(0,-20,0),function()return 0 end),"Destroy alone cannot release an airborne boss")
        f.Position(vec(0,10,0));f.Time(1.1)
        assert(f.API.Plan(p,vec(0,-20,0),function()return 0 end))
        f.Time(1.2);assert(f.API.Plan(p,vec(0,-20,0),function()return 0 end))
        f.Time(1.27);assert(not f.API.Plan(p,vec(0,-20,0),function()return 0 end))
        assert(f.API.LastReturnMargin>=.15 and f.API.LastReturnMargin<.2)
    end)
    test("high-ping completion margin stays bounded and missing completion keeps fallback",function()
        local f=fixture();f.State.PingMs=600
        local skill={Lifetime=3,SurfacePosition=vec(0,0,0),LastCFrame={Position=vec(0,10,0)}}
        f.Skills.LavaSmash=skill
        local p=f.API.Plan(vec(0,-20,0),nil,function()return 0 end)
        f.Time(1)
        assert(f.API.Plan(p,vec(0,-20,0),function()return 0 end),"No early release from an unconfirmed cast")
        skill.Destroyed=true;f.Skills.LavaSmash=nil;f.Position(vec(0,10,0));f.Time(1.1)
        assert(f.API.Plan(p,vec(0,-20,0),function()return 0 end))
        f.Time(1.4);assert(f.API.Plan(p,vec(0,-20,0),function()return 0 end))
        f.Time(1.46);assert(not f.API.Plan(p,vec(0,-20,0),function()return 0 end))
        assert(f.API.LastReturnMargin==.35)
    end)
    test("native registry removal confirms completion without a Destroyed flag",function()
        local f=fixture()
        f.Skills.LavaSmash={Lifetime=3,SurfacePosition=vec(0,0,0),LastCFrame={Position=vec(0,10,0)}}
        local p=f.API.Plan(vec(0,-20,0),nil,function()return 0 end)
        f.Skills.LavaSmash=nil;f.Position(vec(0,10,0));f.Time(1)
        assert(f.API.Plan(p,vec(0,-20,0),function()return 0 end))
        f.Time(1.2);assert(not f.API.Plan(p,vec(0,-20,0),function()return 0 end))
    end)
    test("ground tracker confirmation handles a standing root above the native reference",function()
        local f=fixture();f.Grounded(false)
        f.Skills.LavaSmash={Lifetime=3,SurfacePosition=vec(0,0,0),LastCFrame={Position=vec(0,0,0)}}
        f.Position(vec(0,100,0))
        local p=f.API.Plan(vec(0,-20,0),nil,function()return 0 end)
        f.Skills.LavaSmash=nil;f.Grounded(true);f.Position(vec(0,23,0));f.Time(1)
        assert(f.API.Plan(p,vec(0,-20,0),function()return 0 end))
        f.Time(1.1);assert(f.API.Plan(p,vec(0,-20,0),function()return 0 end))
        f.Time(1.2);assert(not f.API.Plan(p,vec(0,-20,0),function()return 0 end))
        assert(f.API.LastSkillEndAt==1,"Do not restart the completion timer every frame")
    end)
    test("FireDash returns quickly when native completion confirms there are no flames",function()
        local f=fixture();f.FireAssets({});f.Dash()
        local p=f.API.Plan(vec(0,-20,0));assert(p)
        f.Skills.FireDash=nil;f.Time(.1)
        assert(f.API.Plan(p,vec(0,-20,0)))
        f.Time(.27);assert(not f.API.Plan(p,vec(0,-20,0)),"No fixed three-second post-dash wait")
        assert(f.API.Completed.FireDash and f.API.LastSkillEndName=="FireDash")
    end)
    local function flame()
        local part={Parent=true,Position=vec(50,0,0),Size=vec(100,2,20),IsA=function()return true end}
        part.CFrame={PointToObjectSpace=function(_,point)return point-part.Position end}
        return part
    end
    test("FireDash keeps real flames hazardous until they disappear",function()
        local f=fixture();local part=flame();f.FireAssets({part});f.Dash()
        local p=f.API.Plan(vec(50,-20,0));assert(p)
        f.Skills.FireDash=nil;f.Time(.1);assert(f.API.Plan(p,vec(50,-20,0)))
        f.Time(.3);assert(f.API.Plan(p,vec(50,-20,0)),"Native completion cannot erase lingering flames")
        part.Parent=nil;f.Time(.31);assert(not f.API.Plan(p,vec(50,-20,0)))
    end)
    test("FireDash resumes if the route to the boss is outside surviving flames",function()
        local f=fixture();f.FireAssets({flame()});f.Dash()
        local p=f.API.Plan(vec(50,-20,0));assert(p)
        f.Skills.FireDash=nil;f.Time(.1);assert(f.API.Plan(p,vec(120,-20,0)))
        f.Time(.27);assert(not f.API.Plan(p,vec(120,-20,0)))
    end)
    test("FireDash retains its conservative tail when flame inspection is unavailable",function()
        local f=fixture();f.Dash()
        local p=f.API.Plan(vec(0,-20,0))
        f.Skills.FireDash=nil;f.Time(.3);assert(f.API.Plan(p,vec(0,-20,0)))
        f.Time(2);assert(f.API.Plan(p,vec(0,-20,0)))
        f.Time(4);assert(not f.API.Plan(p,vec(0,-20,0)))
    end)
    test("LavaGyzer returns quickly when the cast ends without outstanding points",function()
        local f=fixture();f.Skills.LavaGyzer={}
        f.API.Plan(vec(0,-20,0));f.Skills.LavaGyzer=nil;f.Time(.1)
        f.API.Plan(vec(0,-20,0));f.Time(.27)
        assert(not f.API.Plan(vec(0,-20,0)) and f.API.ThreatCount==0)
        assert(f.API.Completed.LavaGyzer)
    end)
    test("LavaGyzer waits through a removed point's scheduled burst and returns promptly",function()
        local f=fixture()
        local marker={Parent=true,Position=vec(0,0,0),Size=vec(40,1,40),IsA=function()return true end,
            GetAttribute=function()return .5 end}
        f.Points[1]=marker;f.Skills.LavaGyzer={}
        local p=f.API.Plan(vec(0,-20,0));assert(p)
        f.Skills.LavaGyzer=nil;f.Points[1]=nil;marker.Parent=nil;f.Time(.1)
        assert(f.API.Plan(p,vec(0,-20,0)))
        f.Time(.7);assert(f.API.Plan(p,vec(0,-20,0)))
        f.Time(.81);assert(not f.API.Plan(p,vec(0,-20,0)),"Do not retain the old one-second stale-point tail")
    end)
    test("Above farming can escape a slam without a long dive below the map",function()
        local f=fixture();f.State.FarmAbove=true
        f.Skills.LavaSmash={Lifetime=3,SurfacePosition=vec(0,0,0)}
        local current=vec(0,110,0)
        local p=f.API.Plan(current,nil,function()return 0 end)
        assert(p and p.Y>0 and (p-current).Magnitude<=112 and p.Magnitude<=128)
    end)
    print("All "..count.." Atheon dodge scenarios passed")
end
