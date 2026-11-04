-- Every configured account remains required; an unmatched entry is never dropped.
return function(self,players,text)
    local byName,byId={},{}
    for _,person in ipairs(players)do byName[person.Name:lower()]=person;byId[tostring(person.UserId)]=person end
    local result,seen={self},{[tostring(self.UserId)]=true}
    for word in tostring(text or ""):gmatch("[%w_]+")do
        local person=byName[word:lower()]or byId[word]
        local key=person and tostring(person.UserId)or ("missing:"..word:lower())
        if not seen[key]then
            seen[key]=true
            result[#result+1]=person or {Name=word,UserId=tonumber(word),CreditMissing=true}
        end
    end
    return result
end
