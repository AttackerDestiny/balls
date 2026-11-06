-- Reversible alpha overlay owned only while a native block prompt is active.
return function(ctx)
    local api={}
    local session
    local function properties(object)
        local fields={}
        local kinds={GuiObject={"BackgroundTransparency"},ImageLabel={"ImageTransparency"},ImageButton={"ImageTransparency"},
            TextLabel={"TextTransparency","TextStrokeTransparency"},TextButton={"TextTransparency","TextStrokeTransparency"},
            TextBox={"TextTransparency","TextStrokeTransparency"},UIStroke={"Transparency"},CanvasGroup={"GroupTransparency"}}
        for class,names in pairs(kinds)do if object:IsA(class)then for _,name in ipairs(names)do fields[name]=true end end end
        return fields
    end
    local function overlay(active,object)
        local fields=properties(object)
        if next(fields)==nil then return end
        local saved=active.Saved[object]
        if not saved then saved={};active.Saved[object]=saved end
        for property in pairs(fields)do
            if saved[property]==nil then saved[property]=object[property]end
            object[property]=1
        end
    end
    function api.End()
        local active=session;session=nil
        if not active then return end
        for _,connection in ipairs(active.Connections)do connection:Disconnect()end
        for object,saved in pairs(active.Saved)do
            if object.Parent then for property,value in pairs(saved)do pcall(function()object[property]=value end)end end
        end
        table.clear(active.Saved);table.clear(active.Modals);table.clear(active.Connections)
    end
    function api.Begin()
        api.End()
        local active={Saved={},Modals={},Connections={}}
        session=active
        local function discover(object)
            if session~=active then return end
            if object.Name=="BlockingModal"and object:IsA("GuiObject")then
                active.Modals[object]=true;overlay(active,object)
                for _,child in ipairs(object:QueryDescendants("GuiObject, UIStroke"))do overlay(active,child)end
                return
            end
            local parent=object.Parent
            while parent and parent~=ctx.Root do
                if active.Modals[parent]then overlay(active,object);return end
                parent=parent.Parent
            end
        end
        local ok,reason=pcall(function()
            active.Connections[1]=ctx.Root.DescendantAdded:Connect(discover)
            for _,modal in ipairs(ctx.Root:QueryDescendants("#BlockingModal"))do discover(modal)end
            active.Connections[2]=ctx.Render:Connect(function()
                for object,saved in pairs(active.Saved)do
                    if object.Parent then for property in pairs(saved)do object[property]=1 end
                    else active.Saved[object]=nil;active.Modals[object]=nil end
                end
            end)
        end)
        if not ok then api.End();error(reason)end
    end
    api.Destroy=api.End
    return api
end
