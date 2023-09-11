--[[
	VDD电流检测
]]--

local gDevChan 			= 0;			--设备通道
local gPowerItemVddType = 0;			--VDD电源项

local VDD_MIN_CURRENT 	= 0;			--VDD最小电流(mA)
local VDD_MAX_CURRENT 	= 140;			--VDD最大电流(mA)

--[[
@功能：执行流程
@Return: N/A.
]]--
local function doProcess()
	--luaGpioSet(GPIO_STBYB_PIN, 0);
	luaMSleep(600);--待图片稳定显示
	
	local bRet = true;
	local powerInfo = {};
	local str = " ";
	luaReadRealTimePowerItem(gDevChan, gPowerItemVddType, powerInfo)	--读取VDD实时电源项信息
	if powerInfo[2] < VDD_MIN_CURRENT or powerInfo[2] > VDD_MAX_CURRENT then
		str = string.format("最大消费电流值[%.3fmA]不在(%.3f~%.3f)mA卡控范围内\r\n", powerInfo[2], VDD_MIN_CURRENT, VDD_MAX_CURRENT)
		--luaPrintLog(true, str, false, false)
		bRet = false;
	else
		str = string.format("最大消费电流值[%.3fmA]在(%.3f~%.3f)mA卡控范围内\r\n", powerInfo[2], VDD_MIN_CURRENT, VDD_MAX_CURRENT)
		--luaPrintLog(false, str, false, true);
	end
	luaWriteLog2UDisk(gDevChan, str, string.len(str));
	luaMSleep(10);
	
	if bRet then
		luaPrintLog(false, string.format("最大消费电流:[%.3fmA]检测成功!",powerInfo[2]), false, true);
	else
		luaPrintLog(true, string.format("最大消费电流:[%.3fmA]检测失败,关电!",powerInfo[2]), false, true);
		luaTriggerPowerOff(false);--luaPowerOff();
	end
	return bRet;
end

doProcess();
