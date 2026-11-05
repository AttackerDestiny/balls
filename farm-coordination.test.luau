return function(source,canMoveSource)
    local make=assert(loadstring(source))()
    local serverTime=100.01
    local clients={}
    for i=1,14 do
        -- Each client has independent local state, but reads the same replicated server clock.
        clients[i]=make({Now=function()return serverTime end,Vector=function(x,y,z)return {X=x,Y=y,Z=z}end})
        assert(not clients[i].Ready("target")and not clients[i].Ready("move"))
    end
    serverTime=100.26
    for _,client in ipairs(clients)do
        assert(client.Ready("target")and client.Ready("move"))
        assert(not client.Ready("target")and not client.Ready("move"),"Only one move/acquisition per shared beat")
        local point=client.Position({X=12.1,Y=125,Z=-24.1})
        assert(point.X==12 and point.Y==125 and point.Z==-24,"Use one destination independent of account/weapon settings")
        assert(client.Deadline(101.12,90)==191.5 and client.Deadline(101.12,45)==146.5)
    end
    serverTime=100.1
    for _,client in ipairs(clients)do assert(not client.Ready("move"),"Clock corrections cannot create a duplicate move")end
    serverTime=101.26
    for _,client in ipairs(clients)do
        assert(client.Ready("move")and not client.Ready("move"),"Low FPS skips missed beats without a catch-up burst")
    end
    local people={};for i=1,14 do people[i]={UserId=i}end
    local enemy={}
    local positions={}
    local vector=function(x,y,z)return {X=x,Y=y,Z=z}end
    for i=1,14 do
        local client=make({Now=function()return serverTime end,Vector=vector,UserId=i,
            Members=function()local copy=table.clone(people);table.sort(copy,function(a,b)return a.UserId>b.UserId end);return copy end})
        local point=client.Spread(vector(0,-20,0),enemy,vector(0,0,0),25)
        assert(point.X^2+point.Y^2+point.Z^2<25^2,"Separated positions stay inside the attack sphere")
        for _,other in ipairs(positions)do
            assert((point.X-other.X)^2+(point.Z-other.Z)^2>=3^2,"14 accounts must not overlap")
        end
        positions[#positions+1]=point
        assert(client.Spread(vector(.1,-20,.1),enemy,vector(0,0,0),25)==point,"Small enemy motion must retain the hold")
        local constrained=client.Spread(vector(0,-23,0),{},vector(0,0,0),24)
        assert(constrained.X^2+constrained.Y^2+constrained.Z^2<24^2,"Tight reach takes precedence over spacing")
    end
    local state={AutoFarm=true}
    local living=true
    state.IsFarmEnemyAlive=function()return living end
    local fn=assert(loadstring("return "..canMoveSource))
    setfenv(fn,setmetatable({state=state,api={},safe={},player={Character={
        FindFirstChild=function()return {Anchored=false}end,FindFirstChildOfClass=function()return {Health=100}end}}},{__index=getfenv()}))
    local canMove=fn()
    assert(not canMove(),"A ready/higher-priority spot cannot move away from the current living enemy")
    living=false;assert(canMove(),"Spot departure is allowed once the enemy is confirmed dead")
    state.SafeModePanic=true;assert(not canMove(),"Safety pauses still own movement after a kill")
    print("PASS Lua-only farm coordination: 14 independent clients, shared server beats, common position, respawn deadlines, clock correction and no catch-up burst")
end
