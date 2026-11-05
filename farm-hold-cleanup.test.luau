return function(source)
    local cleanup=assert(loadstring(source.."\nreturn clearStaleFarmControllers"))()
    local function child(name,class)
        return {Name=name,IsA=function(_,kind)return kind==class end,Destroy=function(self)self.Destroyed=true end}
    end
    local children={child("SB2FarmPosition","AlignPosition"),child("SB2FarmPosition","AlignPosition"),
        child("SB2FarmOrientation","AlignOrientation"),child("SB2FarmAttachment","Attachment"),
        child("NativeMovement","AlignPosition"),child("SB2FarmPosition","Folder")}
    local root={GetChildren=function()return children end}
    cleanup(root)
    for i=1,4 do assert(children[i].Destroyed,"Every orphaned Feather constraint must retire")end
    assert(not children[5].Destroyed and not children[6].Destroyed,"Other movement instances remain owned by their creators")
    cleanup(root)
    print("PASS Farm hold cleanup: duplicate constraints, attachment cleanup, native controller preservation")
end
