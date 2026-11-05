return function(source)
    local slot=assert(loadstring(source))()
    local ids={80,20,60,40,10,30,50,70}
    local positions={}
    for _,id in ipairs(ids)do
        local x,z=slot(id,ids,12,12,2,2)
        assert(math.abs(x)<=4.5 and math.abs(z)<=4.5,"Keep character footprint inside pad edges")
        for _,p in ipairs(positions)do assert((x-p[1])^2+(z-p[2])^2>=9,"Separate eight account positions")end
        positions[#positions+1]={x,z}
        local a,b=slot(id,{10,20,30,40,50,60,70,80},12,12,2,2)
        assert(a==x and b==z,"Player enumeration order cannot change the slot")
    end
    local x,z=slot(10,ids,1,1,2,2)
    assert(x==0 and z==0,"Small pads cannot place characters beyond their edges")
    print("PASS Friend pad slots: eight distinct bounded positions, stable account ordering and small-pad fallback")
end
