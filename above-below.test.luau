return function(rangeSource,offsetSource,scriptSource,payloadSource)
    local count=0
    local function test(name,fn)fn();count+=1;print("PASS "..name)end
    local mt={}
    local function vec(x,y,z)return setmetatable({X=x,Y=y,Z=z},mt)end
    mt.__add=function(a,b)return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
    mt.__sub=function(a,b)return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
    mt.__mul=function(a,n)if type(n)=="number"then return vec(a.X*n,a.Y*n,a.Z*n)end;return vec(a.X*n.X,a.Y*n.Y,a.Z*n.Z)end
    mt.__index=function(a,k)if k=="Magnitude"then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)end end
    local function load(source,extra)
        local chunk=assert(loadstring(source))
        setfenv(chunk,setmetatable(extra or {Vector3={new=vec}},{__index=getfenv()}));return chunk()
    end
    local function geometry()
        local state={AutoFarm=true,FarmAbove=false}
        local api=load(rangeSource)({State=state,Clock=function()return 0 end})
        local solve=load(offsetSource)
        local data={Root={Position=vec(0,100,0),Size=vec(19.5,45.5,19.5)},BodyAbove=62,BodyBelow=22.75}
        local root={Position=vec(0,0,0),Size=vec(2,2,1)}
        return state,api,solve,data,root
    end
    test("Above and Below stay on the selected side inside measured hit range",function()
        local state,api,solve,data,root=geometry()
        for _,above in ipairs({false,true})do
            state.FarmAbove=above
            local center=root.Position+api.Delta(data,root)
            local plan=assert(solve({Enemy=data.Root,Player=root,Center=center,Mode=above and "Above"or"Below",
                Reach=api.BodyRange(data),Margin=1.8,AdaptiveAbove=above,BodyAbove=50,BodyBelow=data.BodyBelow,PlayerAbove=3,PlayerBelow=3}))
            assert(above and plan.Destination.Y>104.5 or not above and plan.Destination.Y<100-22.75-3)
            assert(api.Delta(data,{Size=root.Size,Position=plan.Destination}).Magnitude<api.BodyRange(data))
        end
    end)
    test("Above adjusts studs to learned reach without crossing below the root",function()
        local _,_,solve,data,root=geometry()
        local input={Enemy=data.Root,Player=root,Mode="Above",AdaptiveAbove=true,Reach=27.75,Margin=1.8,
            BodyAbove=50,PlayerBelow=3}
        local plan=assert(solve(input))
        assert(plan.Offset>=4.5 and plan.Radius<27.75)
        input.Reach=26;assert(not solve(input),"Do not cross below the root to satisfy an unreachable range")
    end)
    test("Above range learning stays separate and is limited to Auto Farm",function()
        local state,api,_,data,root=geometry()
        for i=1,3 do api.Record("Kill",29.7,0,data)end
        local below=api.Range("Kill",data);assert(below<api.BodyRange(data))
        state.FarmAbove=true;assert(api.Range("Kill",data)==api.BodyRange(data))
        state.AutoFarm=false;assert(api.Range("Kill",data)==below)
        assert(api.Delta(data,root).Y==78.25)
    end)
    test("Removed Above/Below control cannot restore a stale Above preference",function()
        assert(not string.find(scriptSource,'state.UI.AboveBelow',1,true))
        assert(not string.find(scriptSource,'function state.SetFarmAbove',1,true))
        assert(not string.find(scriptSource,'preference("FarmAbove"',1,true))
        assert(string.find(scriptSource,'FarmAbove=false',1,true)and string.find(scriptSource,'OffsetMode="Below"',1,true))
    end)
    test("Settings discard the removed Above preference",function()
        local position={X={Scale=0,Offset=0},Y={Scale=0,Offset=0}}
        local result=load(payloadSource.."\nreturn settingsPayload()",{state={FarmAbove=true},panel={Position=position},enemyHUD={Position=position}})
        assert(result.FarmAbove==nil)
    end)
    print("All "..count.." Above/Below scenarios passed")
end
