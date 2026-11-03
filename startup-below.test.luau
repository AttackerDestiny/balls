return function(source)
    local run=assert(loadstring(source))()
    local now,alive,ready,moves=0,true,true,{}
    local root={};local point={X=123,Y=103,Z=-456}
    local ctx={Now=function()return now end,Alive=function()return alive end,
        Root=function()return ready and root or nil end,Position=function()return point end,
        Surface=function()return 100 end,Move=function(r,x,y,z)moves[#moves+1]={Root=r,X=x,Y=y,Z=z}end,
        Sleep=function(dt)now+=dt;if now>=.2 then ready=true end end}
    assert(run(ctx)and #moves==1 and moves[1].X==123 and moves[1].Y==80 and moves[1].Z==-456)
    point.Y=80;assert(run(ctx)and moves[2].Y==80,"Repeated startup must use ground height instead of subtracting another 20")
    moves={};ready=false;now=0;assert(run(ctx)and now>=.2 and #moves==1,"Wait for the first living character")
    moves={};alive=false;assert(not run(ctx)and #moves==0,"Cancelled startup cannot move a character")
    alive=true;ready=false;now=0;ctx.Sleep=function(dt)now+=dt end
    assert(not run(ctx)and now>=8 and #moves==0,"Missing characters must not block startup forever")
    ready=true;ctx.Surface=function()return 0/0 end;assert(not pcall(run,ctx)and #moves==0)
    print("PASS Startup below: exact ground-minus-20, X/Z preservation, no cumulative offset, delayed character, cancellation and bounded timeout")
end
