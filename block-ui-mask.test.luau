return function(source)
    local function signal()
        local api={Listeners={}}
        function api:Connect(fn)
            local connection={Connected=true};self.Listeners[connection]=fn
            function connection:Disconnect()self.Connected=false;api.Listeners[self]=nil end
            return connection
        end
        function api:Fire(value)for _,fn in pairs(self.Listeners)do fn(value)end end
        return api
    end
    local added,render=signal(),signal()
    local root={DescendantAdded=added}
    local function object(name,kind,parent)
        local v={Name=name,Kind=kind,Parent=parent,BackgroundTransparency=.2,ImageTransparency=.3,
            TextTransparency=.4,TextStrokeTransparency=.5,Transparency=.6,Visible=true,Active=true,Children={}}
        function v:IsA(class)return class==self.Kind or class=="GuiObject"and self.Kind~="UIStroke"end
        function v:QueryDescendants()return self.Children end
        return v
    end
    local modal=object("BlockingModal","ImageButton",root)
    local button=object("3","TextButton",modal);local stroke=object("Border","UIStroke",button)
    modal.Children={button,stroke}
    local unrelated=object("Inventory","TextButton",root)
    function root:QueryDescendants()return {modal}end
    local mask=assert(loadstring(source))()({Root=root,Render=render})
    for _=1,3 do
        mask.Begin()
        assert(modal.ImageTransparency==1 and button.TextTransparency==1 and stroke.Transparency==1)
        assert(button.Visible and button.Active,"Native controls must remain interactable")
        assert(unrelated.TextTransparency==.4,"Other Roblox UI stays unchanged")
        local late=object("Late","TextLabel",modal);added:Fire(late);assert(late.TextTransparency==1)
        button.TextTransparency=.25;render:Fire();assert(button.TextTransparency==1,"Suppress native visual animations")
        mask.End();mask.End()
        assert(button.TextTransparency==.4 and modal.ImageTransparency==.3 and stroke.Transparency==.6)
        assert(late.TextTransparency==.4 and next(added.Listeners)==nil and next(render.Listeners)==nil)
    end
    mask.Begin();mask.Destroy();assert(next(render.Listeners)==nil)
    function root:QueryDescendants()error("unsupported")end
    assert(not pcall(mask.Begin)and next(added.Listeners)==nil,"Initialization failure must release listeners")
    print("PASS Hidden block dialog: scoped transparency, active hit targets, late UI, animation suppression, restore, repeated cleanup and errors")
end
