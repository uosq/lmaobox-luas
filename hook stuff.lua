local hooks = {}

function hooks.hookfunction(funcname, originalfn, hookfn, calloriginal)
   local function wrapper(...)
      local hook_result = {hookfn(...)}

      if calloriginal then
         originalfn(...)
      end

      return table.unpack(hook_result)
   end

   _G[funcname] = wrapper
   return wrapper
end

local hook_print
hook_print = function(...)
   local args = {...}
   if #args > 0 then
      io.stdout:write(table.unpack(args))
   end
end

hooks.hookfunction("print", print, hook_print, false)

print()