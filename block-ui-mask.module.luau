-- Hide only the native blocking modal's visuals; keep its hit targets usable.
return function(ctx)
    local api={}
    local finish
    function api.End()
        if finish then local close=finish;finish=nil;close()end
    end
    function api.Begin()
        api.End()
        local saved,modals,connections={},{},{}
        local function hide(instance)
            local properties={}
            if instance:IsA("GuiObject")then properties[#properties+1]="BackgroundTransparency"end
            if instance:IsA("ImageLabel")or instance:IsA("ImageButton")then properties[#properties+1]="ImageTransparency"end
            if instance:IsA("TextLabel")or instance:IsA("TextButton")or instance:IsA("TextBox")then
                properties[#properties+1]="TextTransparency";properties[#properties+1]="TextStrokeTransparency"
            end
            if instance:IsA("UIStroke")then properties[#properties+1]="Transparency"end
            if instance:IsA("CanvasGroup")then properties[#properties+1]="GroupTransparency"end
            if #properties==0 then return end
            local record=saved[instance]or {};saved[instance]=record
            for _,key in ipairs(properties)do
                if record[key]==nil then record[key]=instance[key]end
                instance[key]=1
            end
        end
        local function added(instance)
            if instance.Name=="BlockingModal"and instance:IsA("GuiObject")then
                modals[instance]=true;hide(instance)
                for _,child in ipairs(instance:QueryDescendants("GuiObject, UIStroke"))do hide(child)end
            else
                local parent=instance.Parent
                while parent and parent~=ctx.Root do
                    if modals[parent]then hide(instance);break end
                    parent=parent.Parent
                end
            end
        end
        finish=function()
            for _,connection in ipairs(connections)do connection:Disconnect()end
            for instance,record in pairs(saved)do
                if instance.Parent then for key,value in pairs(record)do pcall(function()instance[key]=value end)end end
            end
            table.clear(saved);table.clear(modals);table.clear(connections)
        end
        connections[#connections+1]=ctx.Root.DescendantAdded:Connect(added)
        local ok,reason=pcall(function()
            for _,modal in ipairs(ctx.Root:QueryDescendants("#BlockingModal"))do added(modal)end
            connections[#connections+1]=ctx.Render:Connect(function()
                -- Native hover/fade animations may rewrite alpha while the prompt is active.
                for instance,record in pairs(saved)do
                    if instance.Parent then for key in pairs(record)do instance[key]=1 end
                    else saved[instance]=nil;modals[instance]=nil end
                end
            end)
        end)
        if not ok then api.End();error(reason)end
    end
    api.Destroy=api.End
    return api
end
