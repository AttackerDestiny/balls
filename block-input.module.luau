-- CoreGui coordinate transforms vary across client layouts. Verify each candidate.
return function(button,inset,hit)
    local origin=button.AbsolutePosition
    local half=button.AbsoluteSize/2
    if hit then
        local center=origin+half
        if hit(center)then return center end
        local shifted=center+inset
        if (inset.X~=0 or inset.Y~=0)and hit(shifted)then return shifted end
        return nil
    end
    return origin+inset+half
end
