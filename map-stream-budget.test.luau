return function(source)
    local callback,deferred
    local pendingJobs,applied,peak,chunk,now,waits=0,0,0,0,0,0
    local state={Running=true,TransparentMap=true}
    local fn=assert(loadstring(source))
    setfenv(fn,setmetatable({state=state,workspace={DescendantAdded={}},restoringZoom=false,
        bind=function(_,fn)callback=fn end,
        task={defer=function(fn)pendingJobs+=1;deferred=fn end,wait=function()peak=math.max(peak,chunk);chunk=0;waits+=1 end},
        os={clock=function()return now end},applyPart=function()applied+=1;chunk+=1;now+=.00005 end},{__index=getfenv()}))
    fn()
    local function part(kind)return {Parent=true,IsA=function(_,class)return class==kind end}end
    for _=1,500 do callback(part("BasePart"));callback(part("Attachment"))end
    assert(pendingJobs==1 and applied==0,"A stream burst must schedule one worker and no synchronous property work")
    deferred();assert(applied==500 and waits>1 and peak<=48,"Streaming updates must be bounded across frames")
    local removed=part("BasePart");callback(removed);removed.Parent=nil;deferred();assert(applied==500)
    callback(part("BasePart"));state.Running=false;deferred();assert(applied==500,"Runtime cleanup cancels queued visual changes")
    print("PASS Streamed map batching: one worker, no synchronous burst, bounded slices, ignored non-parts, removal and cleanup")
end
