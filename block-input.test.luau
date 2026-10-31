return function(source)
    local point=assert(loadstring(source))()
    local mt={}
    local function vec(x,y)return setmetatable({X=x,Y=y},mt)end
    mt.__add=function(a,b)return vec(a.X+b.X,a.Y+b.Y)end
    mt.__div=function(a,b)return vec(a.X/b,a.Y/b)end
    local root={IgnoreGuiInset=true}
    local button={AbsolutePosition=vec(784,475.5),AbsoluteSize=vec(352,32),
        FindFirstAncestorWhichIsA=function()return root end}
    local p=point(button,vec(0,58))
    assert(p.X==960 and p.Y==549.5,"Live FoundationOverlay input includes the CoreGui inset")
    root.IgnoreGuiInset=false;p=point(button,vec(0,58));assert(p.X==960 and p.Y==549.5)
    p=point(button,vec(0,0));assert(p.X==960 and p.Y==491.5)
    print("PASS Block confirmation uses the live-verified CoreGui input coordinate")
end
