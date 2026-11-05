return function(source)
    local count=0
    local function test(name,fn)fn();count+=1;print("PASS "..name)end
    local function fixture()
        local f={Now=0,Clicks=0,Active=true,Blocked={},Result=true,MaskStarts=0,MaskEnds=0}
        local state={}
        local chunk=assert(loadstring(source))
        setfenv(chunk,setmetatable({state=state,ctx={MakeBlockMask=function()return {
            Begin=function()f.Masked=true;f.MaskStarts+=1 end,
            End=function()f.Masked=false;f.MaskEnds+=1 end}end},
            game={GetService=function()return {PreRender={}}end},findPrompt=function()end,
            workerIdentity=function()end,getBlocked=function()return f.Blocked end,
            block=function()assert(f.Masked,"Hide before opening native block prompt");f.Clicks+=1;if f.Fail then error("native block failed")end;return f.Result end,
            virtualInput={SendMouseButtonEvent=function()end},typeof=type,
            os={clock=function()return f.Now end},task={wait=function(dt)f.Now+=dt end}},{__index=getfenv()}))
        chunk();f.State=state;f.Live=function()return f.Active end;return f
    end
    test("A confirmed existing moderator block does not reopen a dialog",function()
        local f=fixture();f.Blocked[1]=true;assert(f.State.BlockPlayerNative({UserId=1},f.Live)and f.Clicks==0)
    end)
    test("The shared native block helper requires confirmation and honors cancellation",function()
        local f=fixture();f.Result=false;assert(not f.State.BlockPlayerNative({UserId=1},f.Live)and f.Clicks==1)
        assert(f.MaskStarts==1 and f.MaskEnds==1 and not f.Masked)
        f.Active=false;assert(not f.State.BlockPlayerNative({UserId=1},f.Live)and f.Clicks==1)
    end)
    test("An errored native confirmation releases the shared dialog lock",function()
        local f=fixture();f.Fail=true;assert(not pcall(f.State.BlockPlayerNative,{UserId=1},f.Live))
        f.Fail=false;assert(f.State.BlockPlayerNative({UserId=1},f.Live)and f.Clicks==2)
        assert(f.MaskStarts==2 and f.MaskEnds==2 and not f.Masked,"Errors cannot leak the UI mask")
    end)
    print("All "..count.." shared native block scenarios passed")
end
