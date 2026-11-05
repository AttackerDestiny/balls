-- State adapters for controllers that publish Text/Visible values.
-- These are plain tables: no Instances, input listeners, layout, or fallback UI.
return function()
    local api={}
    local disconnected={Connected=false,Disconnect=function()end}
    local signal={ControllerSignal=true,Connect=function()return disconnected end}
    local methods={}
    function methods:GetChildren()return {}end
    function methods:FindFirstChild()return nil end
    function methods:IsA()return false end
    function methods:IsFocused()return false end
    function methods:GetPropertyChangedSignal()return signal end
    function methods:Destroy()self.Parent=nil end
    function methods:Clone()
        local properties=table.clone(self)
        return api.New(properties)
    end
    local events={Activated=true,FocusLost=true,InputBegan=true,InputChanged=true,InputEnded=true,Changed=true,Destroying=true}
    local meta={__index=function(_,key)return events[key]and signal or methods[key]end}
    function api.New(properties,parent)
        local view={ControllerView=true,Visible=false,Text="",Parent=parent}
        for key,value in pairs(properties or {})do view[key]=value end
        return setmetatable(view,meta)
    end
    return api
end
