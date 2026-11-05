-- Deterministic, pad-local standing positions shared by accounts in one server.
return function(userId,ids,width,depth,bodyWidth,bodyDepth)
    local halfX=math.max(0,(width-bodyWidth)/2-.5)
    local halfZ=math.max(0,(depth-bodyDepth)/2-.5)
    local columns=math.max(1,math.floor(halfX*2/math.max(3,bodyWidth+1))+1)
    local rows=math.max(1,math.floor(halfZ*2/math.max(3,bodyDepth+1))+1)
    local rank=0
    for _,id in ipairs(ids)do if id<userId then rank+=1 end end
    local slot=rank%(columns*rows)
    local column,row=slot%columns,math.floor(slot/columns)
    return columns==1 and 0 or -halfX+column*halfX*2/(columns-1),
        rows==1 and 0 or -halfZ+row*halfZ*2/(rows-1)
end
