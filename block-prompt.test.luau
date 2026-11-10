return function(source,nativeInstances)
    local owned={}
    local function node(class,name,parent)
        if nativeInstances then
            local object=Instance.new(class);object.Name=name;object.Parent=parent
            if not parent then owned[#owned+1]=object end
            return object
        end
        local object={ClassName=class,Name=name,Parent=parent,Visible=true,Enabled=true,Children={}}
        if parent then parent.Children[#parent.Children+1]=object end
        function object:IsA(kind)
            return self.ClassName==kind or kind=="GuiObject"and (class=="Frame"or class=="TextLabel"or class=="TextButton")
                or kind=="GuiButton"and class=="TextButton"or kind=="LayerCollector"and class=="ScreenGui"
        end
        function object:GetChildren()return self.Children end
        function object:FindFirstChild(key)for _,child in ipairs(self.Children)do if child.Name==key then return child end end end
        function object:QueryDescendants()
            local result={}
            local function walk(o)
                for _,child in ipairs(o.Children)do if child:IsA("TextLabel")then result[#result+1]=child end;walk(child)end
            end
            walk(self);return result
        end
        function object:Destroy()end
        return object
    end
    local make=assert(loadstring(source))()
    local function fixture(target,text,horizontal,roster)
        local root=node("Folder","CoreGui")
        local overlay=node("ScreenGui","FoundationOverlay",root)
        local blocking=node("Frame","BlockingModal",overlay)
        local modal=node("Frame","AlertModal",blocking)
        local contents=node("Frame","AlertContents",modal)
        local heading=node("Frame","Heading",contents)
        local row=node("Frame","Row",heading)
        local title=node("TextLabel","Title",row);title.Text=text or "Block "..target.Name.."?"
        local footer=node("Frame","Footer",contents)
        local buttons=node("Frame","Buttons",footer)
        local no=node("TextButton","1",buttons);no.LayoutOrder=horizontal and 1 or 2
        local report=node("TextButton","2",buttons);report.LayoutOrder=horizontal and 2 or 1
        local yes=node("TextButton","3",buttons);yes.LayoutOrder=horizontal and 3 or 0
        return {Root=root,Overlay=overlay,Blocking=blocking,Modal=modal,Contents=contents,Title=title,Buttons=buttons,
            Confirm=yes,Cancel=no,Report=report,Find=make({Root=root,Targets=roster and function()return roster end or nil})}
    end
    local ok,result=pcall(function()
        local target={Name="Target_User",DisplayName="Target Name"}
        for _,horizontal in ipairs({false,true})do
            local f=fixture(target,"Chặn <b>Target Name</b>?",horizontal)
            local button,cancel=f.Find(target)
            assert(button==f.Confirm and cancel==f.Cancel,"Recognize native vertical and horizontal button order")
            assert(button~=f.Report,"Block-and-report can never be used as the block button")
            f.Overlay.Enabled=false;assert(not f.Find(target));f.Overlay.Enabled=true
            for _,object in ipairs({f.Blocking,f.Modal,f.Contents,f.Title})do
                object.Visible=false;assert(not f.Find(target),"Visible title cannot resurrect a hidden ancestor")
                object.Visible=true
            end
            f.Title.Text="Block Target_User2?"
            local a,b,pending=f.Find(target)
            assert(not a and not b and pending=="Busy","Substrings cannot identify a different user")
            f.Title.Text="Block Target_User?"
            assert(f.Find(target)==f.Confirm)
            f.Confirm.Visible=false
            local _,_,pending=f.Find(target);assert(pending=="Loading","Wait for partially mounted buttons")
            f.Confirm.Visible=true;f.Report.LayoutOrder=99
            assert(not pcall(f.Find,target),"Unknown button order must fail closed")
        end
        local f=fixture(target)
        f.Title.Text="Block SomeoneElse?"
        local _,_,pending=f.Find(target);assert(pending=="Busy")
        f.Blocking.Visible=false
        assert(not f.Find(target),"A stale hidden different-target modal cannot permanently block recovery")
        local other=node("ScreenGui","UnrelatedOverlay",f.Root)
        local title=node("TextLabel","Title",other);title.Text="Block Target_User?"
        assert(not f.Find(target),"Only the recognized native block overlay is eligible")
        local blank={Name="Target_User",DisplayName=""}
        f.Blocking.Visible=true;f.Title.Text="Block Other?"
        local _,_,pending=f.Find(blank);assert(pending=="Busy","Empty display names cannot match every dialog")
        local intended={Name="IntendedUser",DisplayName="SameDisplay",UserId=20}
        local peer={Name="OtherUser",DisplayName="SameDisplay",UserId=10}
        local duplicate=fixture(intended,"Block SameDisplay?",false,{peer,intended})
        for _,person in ipairs({peer,intended})do
            local button,cancel,pending=duplicate.Find(person)
            assert(not button and not cancel and pending=="Ambiguous",
                "A shared display name cannot authorize a click or cancellation for either user ID")
        end
        duplicate.Title.Text="Block @IntendedUser?"
        assert(duplicate.Find(intended)==duplicate.Confirm,"An unambiguous username still identifies its own prompt")
        assert(not duplicate.Find(peer),"The unrelated duplicate-display account cannot acquire a username-specific prompt")
        local whitelisted={Name="TrustedUser",DisplayName="SameDisplay",UserId=30}
        duplicate=fixture(intended,"Block SameDisplay?",false,{intended,whitelisted})
        local _,_,pending=duplicate.Find(intended)
        assert(pending=="Ambiguous","Identity checks include whitelisted users, not just block candidates")
        return {Passed=true,Vertical=true,Horizontal=true,HiddenAncestors=true,TargetGuard=true,Native=nativeInstances==true}
    end)
    for _,object in ipairs(owned)do object:Destroy()end
    assert(ok,result)
    print("PASS Native block prompt: horizontal/vertical layouts, target identity, hidden ancestors, mounting and fail-closed unknown layouts")
    return result
end
