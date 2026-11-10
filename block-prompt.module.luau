-- Recognize only the native Settings block modal; never interact with another dialog.
return function(ctx)
    local function visible(object,root)
        local node=object
        while node and node~=root do
            if node:IsA("GuiObject")and not node.Visible then return false end
            if node:IsA("LayerCollector")and not node.Enabled then return false end
            node=node.Parent
        end
        return node==root
    end
    local function contains(text,name)
        if type(name)~="string"or name==""then return false end
        local from=1
        repeat
            local first,last=text:find(name,from,true)
            if not first then return false end
            local before=first>1 and text:sub(first-1,first-1)or ""
            local after=text:sub(last+1,last+1)
            if not before:match("[%w_]")and not after:match("[%w_]")then return true end
            from=last+1
        until from>#text
        return false
    end
    local function targetMatches(text,target)
        if not(contains(text,target.DisplayName)or contains(text,target.Name))then return false end
        if ctx.Targets then
            for _,person in ipairs(ctx.Targets())do
                if person.UserId~=target.UserId and (contains(text,person.DisplayName)or contains(text,person.Name))then
                    return false,true
                end
            end
        end
        return true
    end
    return function(target)
        local busy,loading,ambiguous=false,false,false
        local confirm,cancel
        for _,overlay in ipairs(ctx.Root:GetChildren())do
            if overlay.Name=="FoundationOverlay"and overlay:IsA("ScreenGui")and overlay.Enabled then
                for _,title in ipairs(overlay:QueryDescendants("#BlockingModal >> TextLabel"))do
                    if title.Name=="Title"and visible(title,overlay)then
                        local contents=title.Parent
                        for _=1,6 do
                            if not contents or contents==overlay or contents.Name=="AlertContents"then break end
                            contents=contents.Parent
                        end
                        local modal=contents and contents.Parent
                        if contents and contents.Name=="AlertContents"and modal and modal.Name=="AlertModal"
                            and modal.Parent and modal.Parent.Name=="BlockingModal"then
                            local text=title.Text:gsub("<[^>]*>",""):gsub("&amp;","&"):gsub("&lt;","<"):gsub("&gt;",">")
                            local matched,conflict=targetMatches(text,target)
                            if conflict then ambiguous=true
                            elseif not matched then busy=true
                            else
                                local footer=contents:FindFirstChild("Footer")
                                local buttons=footer and footer:FindFirstChild("Buttons")
                                local yes=buttons and buttons:FindFirstChild("3")
                                local no=buttons and buttons:FindFirstChild("1")
                                local report=buttons and buttons:FindFirstChild("2")
                                if not(yes and no and report)then loading=true
                                else
                                    local vertical=yes.LayoutOrder==0 and no.LayoutOrder==2 and report.LayoutOrder==1
                                    local horizontal=yes.LayoutOrder==3 and no.LayoutOrder==1 and report.LayoutOrder==2
                                    local supported=yes:IsA("GuiButton")and no:IsA("GuiButton")and report:IsA("GuiButton")
                                        and (vertical or horizontal)
                                    assert(supported,"Unsupported Roblox block dialog layout; no rejoin attempted")
                                    if visible(yes,overlay)and visible(no,overlay)and visible(report,overlay)then
                                        confirm,cancel=yes,no
                                    else loading=true end
                                end
                            end
                        end
                    end
                end
            end
        end
        -- Another modal can cover an otherwise matching button; don't click through it.
        if ambiguous then return nil,nil,"Ambiguous"end
        if busy then return nil,nil,"Busy"end
        if confirm then return confirm,cancel end
        if loading then return nil,nil,"Loading"end
    end
end
