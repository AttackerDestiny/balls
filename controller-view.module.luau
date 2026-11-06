-- Nonvisual controller projections deliberately have no hierarchy or callbacks.
return function()
    local factory={}
    local connection={Connected=false,Disconnect=function()end}
    local nullSignal={ControllerSignal=true}
    function nullSignal:Connect()return connection end
    local behavior={}
    behavior.GetChildren=function()return {}end
    behavior.FindFirstChild=function()return nil end
    behavior.IsA=function()return false end
    behavior.IsFocused=function()return false end
    behavior.GetPropertyChangedSignal=function()return nullSignal end
    behavior.Destroy=function(self)self.Parent=nil end
    behavior.Clone=function(self)return factory.New(table.clone(self))end
    local eventNames={"Activated","FocusLost","InputBegan","InputChanged","InputEnded","Changed","Destroying"}
    for _,event in ipairs(eventNames)do behavior[event]=nullSignal end
    local metatable={__index=behavior}
    function factory.New(values,parent)
        local projection={ControllerView=true,Text="",Visible=false,Parent=parent}
        for property,value in pairs(values or {})do projection[property]=value end
        return setmetatable(projection,metatable)
    end
    return factory
end
