-- Resolve aliases once; unmatched configured identities remain explicit requirements.
return function(self,players,text)
    local lookup={}
    for _,person in ipairs(players)do
        lookup[person.Name:lower()]=person
        lookup[tostring(person.UserId)]=person
    end
    local members={self}
    local identities={[tostring(self.UserId)]=true}
    for token in tostring(text or ""):gmatch("[%w_]+")do
        local person=lookup[token:lower()]or lookup[token]
        local identity=person and tostring(person.UserId)or "missing:"..token:lower()
        if not identities[identity]then
            identities[identity]=true
            members[#members+1]=person or {Name=token,UserId=tonumber(token),CreditMissing=true}
        end
    end
    return members
end
