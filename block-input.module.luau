-- FoundationOverlay's native coordinate space includes the GuiService inset.
return function(button,inset)
    local origin=button.AbsolutePosition
    local half=button.AbsoluteSize/2
    return origin+inset+half
end
