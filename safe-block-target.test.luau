return function(source)
    local a,b,c={UserId=1},{UserId=2},{UserId=3}
    local state={SafePendingUserId=2}
    local showing=a
    local chunk=assert(loadstring(source.."\nreturn chooseBlockTarget"))
    setfenv(chunk,setmetatable({state=state,allowed=function(person)return person==c end,
        findPrompt=function(person)
            if person==c then error("An unsupported whitelisted dialog cannot authorize a click")end
            return person==showing and {}or nil
        end},{__index=getfenv()}))
    local choose=chunk()
    assert(choose({b,a})==a,"A recognized eligible open modal must win over a newer pending outsider")
    showing=nil
    assert(choose({a,b})==b,"Without a recognized modal, preserve pending-player priority")
    showing=c
    assert(choose({c,a,b})==b,"Whitelisted or unrelated modals cannot become block targets")
    showing=a
    assert(choose({b})==b,"Never select a user absent from the eligible list merely because their old dialog exists")
    print("PASS Safe block target: recognized eligible dialog, pending priority, whitelist and departed-target guards")
end
