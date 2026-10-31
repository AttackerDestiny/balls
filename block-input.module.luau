-- Live Core FoundationOverlay input needs GuiService's inset, even when the
-- overlay reports IgnoreGuiInset=true (58 px in the observed client).
return function(button,inset)
    return button.AbsolutePosition+button.AbsoluteSize/2+inset
end
