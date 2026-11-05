return function(source)
    local make=assert(loadstring(source))()
    local api=make(8192)
    local values={}
    for i=1,20000 do values[i]={};api.Push(values[i],i%2==0)end
    assert(api.Count==8192 and api.Peak==8192 and api.Dropped==11808,"Effect bursts cannot grow retained references without a bound")
    for _,value in ipairs(values)do api.Remove(value)end
    assert(api.Count==0 and api.Pop()==nil,"Streamed-out instances are released immediately without waiting to drain")
    local low,high={},{}
    api.Push(low,false);api.Push(high,true);assert(api.Pop()==high and api.Pop()==low)
    for i=1,30000 do local value={};api.Push(value,true);api.Remove(value)end
    assert(api.Count==0 and api.Peak==8192,"Repeated churn does not retain queue slots or removed nodes")
    api.Push({},true);api.Destroy();assert(api.Count==0 and not api.Push({},true))
    print("PASS Instance queue: 20k burst cap, immediate removals, priority, 30k churn and disposal")
end
