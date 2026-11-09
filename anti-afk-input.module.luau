-- Lazy idle-only input with a paired press/release fallback for restricted executors.
return function(ctx)
    return function()
        local input=ctx.Input()
        local point,frame=ctx.Point(),ctx.Frame()
        pcall(input.CaptureController,input)
        local clicked,clickError=pcall(input.ClickButton2,input,point,frame)
        if clicked then return "VirtualUser ClickButton2"end
        local pressed,pressError=pcall(function()
            input:Button2Down(point,frame)
            ctx.Wait(.05)
        end)
        -- Release even when a partial press errors, or the runtime closes during the wait.
        local released,releaseError=pcall(input.Button2Up,input,point,frame)
        assert(pressed and released,"Idle input unavailable: "..tostring(pressError or releaseError or clickError))
        return "VirtualUser Button2Down/Up"
    end
end
