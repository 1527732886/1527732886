
local gDevChan 			= 0;			--设备通道
local gPowerItemVddType = 0;			--VDD电源项

local VDD_OFFSET 	= 80;			--VDD补偿电压(mV)
local VDD_MIN_VOLTAGE 	= 3130;			--VDD最小电压(mV)
local VDD_NORMAL_VOLTAGE 	= 3450;		--VDD正常电压(mV)
local VDD_MAX_VOLTAGE 	= 3640;			--VDD最大电压(mV)

local CLK_NORMAL_VALUE 	= 60;			--CLK最小值(HZ)
--[[
@功能：执行流程
@Return: N/A.
]]--
local function doProcess()	
	local bRet = true;
	local powerInfo = {}
	
	if gDevChan < 2 then
		luaGpioSet(98, 0);
	end
	luaMSleep(20);--待稳定
	luaSetFrameFrequency(CLK_NORMAL_VALUE);
	luaMSleep(100);--待稳定
	luaSetPwrOutputVoltage(gDevChan, gPowerItemVddType, VDD_NORMAL_VOLTAGE);
	luaMSleep(400);--待电压稳定
	luaReadRealTimePowerItem(gDevChan, gPowerItemVddType, powerInfo)	--读取VDD实时电源项信息
	if powerInfo[1] < VDD_MIN_VOLTAGE-VDD_OFFSET or powerInfo[1] > VDD_MAX_VOLTAGE then
		--local str = string.format("VDD电压值[%.3fmV]", powerInfo[1]);
		--luaPrintLog(false, str, false, false);
		bRet = false;
	--[[else
		local str = string.format("VDD电压值[%.3fmV]在(%.3f~%.3f)mV卡控范围内", powerInfo[1], VDD_MIN_VOLTAGE, VDD_MAX_VOLTAGE);
		luaPrintLog(false, str, false, true);
		bRet = true;]]--
	end

	if bRet then
		luaPrintLog(false, string.format("VDD:[%.3fmV],CLK:[68.256MHz]恢复成功!",powerInfo[1]-VDD_OFFSET), false, true);
		--luaSetFrameFrequency(CLK_NORMAL_VALUE);
		--luaPrintLog(false, "CLK检测成功！", false, true);
	else
		luaPrintLog(true, string.format("VDD:[%.3fmV],CLK:[68.256MHz]恢复失败,关电!",powerInfo[1]-VDD_OFFSET), false, true);
		luaTriggerPowerOff(false);--luaPowerOff();
	end
	
	return bRet;
end

doProcess();
