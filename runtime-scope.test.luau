return function(source)
    local make=assert(loadstring(source))()
    local api=make();local calls={}
    api.Add("Save",function()calls[#calls+1]="Save"end)
    api.Add("BrokenHUD",function()error("HUD missing")end)
    api.Add("Disconnect",function()calls[#calls+1]="Disconnect"end)
    api.Add("Root",function()calls[#calls+1]="Root"end)
    local errors=api.Close();api.Close()
    assert(#calls==3 and calls[1]=="Save"and calls[3]=="Root"and #errors==1 and errors[1].Name=="BrokenHUD")
    assert(not pcall(api.Add,"Late",function()end),"Retired scopes cannot acquire new resources")
    print("PASS Runtime scope: all cleanup continues after failure, preserves order and executes only once")
end
