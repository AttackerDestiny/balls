return function(source,binding)
    local initialized=assert(loadstring(binding.."\nreturn controllerViews"))()
    assert(type(initialized.New)=="function","Runtime must initialize the view factory before controllers use it")
    local make=assert(loadstring(source))()
    local views=make()
    local view=views.New({Name="Status",Text="Ready"})
    assert(type(view)=="table"and view.ControllerView and view.Text=="Ready")
    local fired=false
    local connection=view.Activated:Connect(function()fired=true end)
    assert(not connection.Connected and not fired,"Controller state must not own input connections")
    view.Text="Working";assert(view.Text=="Working"and not view:IsFocused())
    local clone=view:Clone();assert(clone~=view and clone.Text=="Working")
    for _=1,10000 do local child=views.New({Name="Discarded"},view);child:Destroy()end
    assert(#view:GetChildren()==0,"Controller models must not retain transient dropdown rows")
    view:Destroy();connection:Disconnect()
    print("PASS Controller state adapters: no GUI instances, input listeners, retained child trees or legacy panel")
end
