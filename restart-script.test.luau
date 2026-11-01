return function(source)
    local make=assert(loadstring(source))()
    local function fixture(failure)
        local f={Order={},Errors=0}
        local function record(name)table.insert(f.Order,name);if failure==name then error(name)end end
        f.Restart=make({Spawn=function(fn)f.Pending=fn end,Status=function(text)f.Status=text end,
            Save=function()record("save")end,Fetch=function()record("fetch");return "loader"end,
            Compile=function(source)assert(source=="loader");record("compile");return function()record("run")end end,
            Destroy=function()record("destroy")end,Error=function()f.Errors+=1 end})
        return f
    end
    local f=fixture();f.Restart();f.Restart();f.Pending()
    assert(table.concat(f.Order,",")=="save,fetch,compile,destroy,run")
    for _,failure in ipairs({"save","fetch","compile"})do
        f=fixture(failure);f.Restart();f.Pending()
        assert(f.Errors==1 and not table.find(f.Order,"destroy"))
        f.Restart();f.Pending();assert(f.Errors==2)
    end
    f=fixture("run");f.Restart();f.Pending();assert(f.Errors==1)
    print("PASS Restart: saves, fetches and compiles before cleanup, same-build reload, duplicate clicks, retry after failure")
end
