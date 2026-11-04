return function(source)
    local roster=assert(loadstring(source))()
    local me={Name="Self",UserId=1};local a={Name="OtherDeviceA",UserId=2};local b={Name="OtherDeviceB",UserId=3}
    local group=roster(me,{me,a,b},"Self, 1, OtherDeviceA, 2, otherdeviceb, 4, MissingName")
    assert(#group==5 and group[1]==me and group[2]==a and group[3]==b)
    assert(group[4].CreditMissing and group[4].Name=="4"and group[5].CreditMissing and group[5].Name=="MissingName")
    group=roster(me,{me,a},"2, 3")
    assert(#group==3 and group[2]==a and group[3].CreditMissing,"Listed accounts cannot silently disappear from credit requirements")
    group=roster(me,{me,a,b},"2, 3");assert(group[3]==b,"Rejoining accounts replace missing entries with actual server identities")
    assert(#roster(me,{me,a,b},"")==1,"No list explicitly means only the local account")
    print("PASS Credit roster: cross-device identities, username/ID aliases, case-insensitivity, deduplication, required missing entries and reconnect")
end
