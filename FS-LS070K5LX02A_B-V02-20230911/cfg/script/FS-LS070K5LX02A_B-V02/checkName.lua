luaPrintLog(false, "请确认机种名!", false, true);

--[[
local qq =  1
if qq < 2 then
		luaGpioSet(54, 0);
	else
		luaGpioSet(61, 1);
	end
]]--