-- The public entry remains one executor-side Lua fetch and compilation.
local address="https://raw.githubusercontent.com/AttackerDestiny/balls/main/kill-aura.luau"
local bytes=game:HttpGet(address.."?t="..os.time())
assert(type(bytes)=="string"and #bytes>0,"Feather source download was empty")
local execute,diagnostic=loadstring(bytes,"Feather")
assert(execute,diagnostic)
return execute()
