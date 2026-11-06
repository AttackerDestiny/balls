-- Detach callbacks before invoking them so nested shutdown cannot run twice.
return function()
    local scope={Errors={}}
    local callbacks,labels={},{}
    local open=true
    function scope.Add(label,callback)
        assert(open,"Runtime scope already closed")
        assert(type(callback)=="function","Cleanup must be callable")
        callbacks[#callbacks+1]=callback;labels[#labels+1]=label
    end
    function scope.Close()
        if open then
            open=false
            local pending=callbacks;callbacks={}
            for index=1,#pending do
                local callback=pending[index];pending[index]=nil
                local ok,reason=pcall(callback)
                if not ok then scope.Errors[#scope.Errors+1]={Name=labels[index],Error=tostring(reason)}end
                labels[index]=nil
            end
        end
        return scope.Errors
    end
    return scope
end
