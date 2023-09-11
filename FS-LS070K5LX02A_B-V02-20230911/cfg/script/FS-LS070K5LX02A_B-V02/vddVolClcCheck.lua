
--[[
	VDD电压&CLK检测
]]--

local gDevChan 			= 0;			--设备通道
local gPowerItemVddType = 0;			--VDD电源项

local VDD_OFFSET 	= 80;				--VDD补偿电压(mV)
local VDD_MIN_VOLTAGE 	= 3130;			--VDD最小电压(mV)
local VDD_NORMAL_VOLTAGE 	= 3450;		--VDD正常电压(mV)
local VDD_MAX_VOLTAGE 	= 3640;			--VDD最大电压(mV)

local CLK_NORMAL_VALUE 	= 60;			--CLK最小值(HZ)
local CLK_MAX_VALUE 	= 66;			--CLK最大值(HZ)
--[[
@功能：执行流程
@Return: N/A.
]]--
local function doProcess()	
	local bRet = true;
	local powerInfo = {}
	
	--luaSetPwrOutputVoltage(gDevChan, gPowerItemVddType, VDD_MIN_VOLTAGE);
	luaReadRealTimePowerItem(gDevChan, gPowerItemVddType, powerInfo)	--读取VDD实时电源项信息
	if powerInfo[1] < VDD_MIN_VOLTAGE-VDD_OFFSET or powerInfo[1] > VDD_MAX_VOLTAGE then
		--local str = string.format("VDD电压值[%.3fmV]", powerInfo[1]);
		--luaPrintLog(false, str, false, false)
		bRet = false;
	--[[else
		local str = string.format("VDD电压值[%.3fmV]在(%.3f~%.3f)mV卡控范围内", powerInfo[1], VDD_MIN_VOLTAGE, VDD_MAX_VOLTAGE)
		luaPrintLog(false, str, false, true);
		bRet = true;]]--
	end

	if bRet then
		--luaPrintLog(false, "VDD电压检测成功！", false, true);
		luaMSleep(20);	--等待稳定
		luaSetFrameFrequency(CLK_MAX_VALUE);
		luaMSleep(100);	--等待稳定
		--luaSetFrameFrequency(CLK_NORMAL_VALUE);
		luaPrintLog(false, string.format("CLK:[75MHz]检测成功!"), false, true);
	else
		luaPrintLog(true, "CLK:[75MHz]检测失败,关电！", false, true);
		--luaTriggerPowerOff(false);
		--luaSetPwrOutput(devChan,gPowerItemVddType,false);
		luaTriggerPowerOff(false);--luaPowerOff();
	end
	--luaGpioSet(54, 1);
	--luaMSleep(50);
	
	--luaMSleep(500);--待电压稳定
	--luaSetPwrOutputVoltage(gDevChan, gPowerItemVddType, VDD_NORMAL_VOLTAGE);
	--luaMSleep(200);--待电压稳定
	return bRet;
end

doProcess();
