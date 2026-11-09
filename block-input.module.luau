-- CoreGui hit-test positions exclude the inset; injected input includes it.
return function(button,inset,hit)
    local origin=button.AbsolutePosition
    local half=button.AbsoluteSize/2
    if hit then
        local center=origin+half
        if hit(center)then return center+inset end
        return nil
    end
    return origin+inset+half
end
