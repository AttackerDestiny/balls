return function(source,arrivalSource)
    local function vec(x,y,z)return {X=x,Y=y,Z=z}end
    local created={}
    local root={Parent=true,Position=vec(1,2,3),AssemblyMass=10}
    local current=root
    local load=assert(loadstring(source))
    setfenv(load,setmetatable({Vector3={new=vec},Enum={ActuatorRelativeTo={World="World"}}},{__index=getfenv()}))
    local api=load()({Workspace={Gravity=196.2},Root=function()return current end,
        Create=function(class,properties,parent)
            local item=properties;item.Class=class;item.Parent=parent
            function item:Destroy()self.Parent=nil end
            created[#created+1]=item;return item
        end})
    api.Attach(root);assert(#created==2 and created[2].Class=="VectorForce")
    assert(created[2].Force.X==0 and created[2].Force.Z==0 and math.abs(created[2].Force.Y-1962)<.001)
    local moved=vec(30,4,80);root.Position=moved;api.Update(1)
    assert(root.Position==moved and created[2].Position==nil,"Passive support must not pin or teleport any position")
    api.Attach(root);assert(#created==2,"No repeated arrival work")
    root.AssemblyMass=20;api.Update(2);assert(math.abs(created[2].Force.Y-3924)<.001)
    current={};api.Update(3);assert(not api.Root and created[2].Parent==nil)
    print("PASS One-shot arrival passive support does not pin position and cleans up")
    local calls,stops=0,0
    local float={}
    float.Attach=function(r)float.Root=r;calls+=1 end
    local state={AutoFarm=true,Enabled=true,TravelHold=true,TravelHoldPosition={},MultiSpotLandingPosition={},ArenaFloat=float}
    local held,holds=nil,0
    local clock=0
    local chunk=assert(loadstring(arrivalSource))
    setfenv(chunk,setmetatable({os={clock=function()return clock end},state=state,player={Character={
        FindFirstChild=function()return root end,FindFirstChildOfClass=function()return {Health=100}end}},
        waveDodge={Idle=function(anchor)held=anchor;holds+=1 end},
        stopMovement=function()stops+=1 end},{__index=getfenv()}));chunk()
    assert(state.FinishMultiSpotArrival() and not state.TravelHold and not state.TravelHoldPosition and calls==0)
    state.AutoFarm=false
    assert(state.FinishMultiSpotArrival() and calls==1 and stops==1)
    root.Position=vec(999,4,999)
    assert(state.FinishMultiSpotArrival() and calls==1 and stops==1 and root.Position.X==999)
    print("PASS Multi Spot releases the destination once and hands movement to Auto Farm")
    local alive=1
    state.MultiSpot=true;state.MultiSpotAnchor=vec(840,798,336);state.MultiSpotController={Current={}}
    state.ReadAutomationEncounter=function()return alive end
    assert(not state.HoldMultiSpotIdle() and holds==0,"A living boss or add must not pull farming back to the spot")
    alive=0;assert(not state.HoldMultiSpotIdle()and holds==0)
    clock=4.99;assert(not state.HoldMultiSpotIdle()and holds==0)
    clock=5;assert(state.HoldMultiSpotIdle() and holds==1 and held==state.MultiSpotAnchor)
    alive=math.huge;assert(not state.HoldMultiSpotIdle() and holds==1,"Unknown streamed mobs cannot prove an idle arena")
    alive=0;clock=10;assert(not state.HoldMultiSpotIdle(),"Unknown mobs reset the five-second timer")
    state.SafeModePanic=true;assert(not state.HoldMultiSpotIdle() and holds==1)
    print("PASS Multi Spot holds its selected spot only with no living arena enemies")
end
