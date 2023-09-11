package.path = package.path .. ";./cfg/script/FS-LS070K5LX02A_B-V02/?.lua"
local otpFLow = require("luaOtpFlowModule")

local gDevChan 				= 0			--设备通道
local gOptDevChan 			= 0			--光学设备通道
local gExternalFlag 		= false		--PG设备内部调试Vcom流程标识
local gFlickerMaxValue		= 15.00
local gFlickerMinValue		= 0.00

--[[
@功能：设置GPIO状态
@devChan(number): 设备通道，其范围为0-3
@state(number): gpio状态值，范围0-1
@Return: N/A
]]--
local function setPanelGpioState(state)
	luaGpioSet(97, state);--EEPEN(通道0,1)
	luaMSleep(20);
end

--[[
@功能：执行流程
@Return: N/A.
]]--
local function doProcess()
	luaPrintLog(false, "进入复测Flicker和机种名确认脚本执行流程...", false, true);
	local bRet = true;

	--1st step 判断是否连接了色彩分析仪
	if luaOpticalDeviceConnectedState(gOptDevChan) == false then
		luaPrintLog(true, "光学设备未连接，没有执行flicker调节流程，程序异常关电!", false, false);
		--luaTriggerPowerOff(false);
		luaTriggerPowerOff(false);--luaPowerOff();--触发异常关电
		return false;
	end

	--2nd step 复测FLicker
	local flickerValue = {};
	luaMeasureFlick(gDevChan, flickerValue);
	if flickerValue[1] ~= nil and gFlickerMaxValue >= flickerValue[1] and gFlickerMinValue <= flickerValue[1] then
		luaPrintLog(false, "复测FLicker值合格,flicker值:"..flickerValue[1].."在["..gFlickerMinValue.."~"..gFlickerMaxValue.."范围内", false, false);
	else
		luaPrintLog(true, "复测FLicker值失败,flicker值:"..flickerValue[1].."不在["..gFlickerMinValue.."-"..gFlickerMaxValue.."范围内", false, false)

		bRet = false;
	end


	--3rd step：开启自动flick调节任务
	--[[setPanelGpioState(0);
	otpFLow.writeICVcom(gDevChan, 0xE3);--给初始vcom值
	bRet = luaStartAutoAdjustVcom(gDevChan, gOptDevChan, gExternalFlag);

	if bRet == true then
		local vcomVal = otpFLow.readICVcom(gDevChan);
		setPanelGpioState(1);
		otpFLow.writeVcom(gDevChan, vcomVal);
	end

	luaSetWaittingDialog(false, "完成Flicker调节脚本执行流程");
	if bRet == false then
		luaPrintLog(true, "调节Vcom值失败", false, true);
		setPanelGpioState(1);
		luaSetPwrOutput(gDevChan,1,false);--关闭VDD电压
	else
		luaPrintLog(false, "完成Flicker脚本执行流程", false, true);
	end]]--
	if false == bRet then
		luaTriggerPowerOff(false);--luaPowerOff();--关闭VDD电压
	end
	luaPrintLog(false, "完成复测Flicker和机种名确认脚本执行流程", false, true);
	return bRet;
end

luaSetOpticalDeviceType(0);--CA310
luaMSleep(20);
doProcess();
