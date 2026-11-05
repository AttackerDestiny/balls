-- Every registered cleanup runs exactly once, even after another cleanup fails.
return function()
    local api={Errors={}}
    local entries,disposed={},false
    function api.Add(name,fn)
        assert(not disposed,"Runtime scope already closed")
        entries[#entries+1]={Name=name,Run=fn}
    end
    function api.Close()
        if disposed then return api.Errors end
        disposed=true
        for _,entry in ipairs(entries)do
            local ok,reason=pcall(entry.Run)
            if not ok then api.Errors[#api.Errors+1]={Name=entry.Name,Error=tostring(reason)}end
            entry.Run=nil
        end
        table.clear(entries)
        return api.Errors
    end
    return api
end
