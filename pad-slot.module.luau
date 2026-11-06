-- Rank accounts once in pad-local geometry; cells never extend past its bounds.
return function(userId,players,width,depth,bodyWidth,bodyDepth)
    local function axis(size,body)
        local extent=math.max(0,(size-body)/2-.5)
        local cells=math.max(1,math.floor(2*extent/math.max(3,body+1))+1)
        return extent,cells
    end
    local x,columns=axis(width,bodyWidth)
    local z,rows=axis(depth,bodyDepth)
    local order=0
    for _,other in ipairs(players)do if other<userId then order+=1 end end
    local index=order%(columns*rows)
    local column=index%columns;local row=math.floor(index/columns)
    local function coordinate(cell,count,extent)
        if count<2 then return 0 end
        return extent*(2*cell/(count-1)-1)
    end
    return coordinate(column,columns,x),coordinate(row,rows,z)
end
