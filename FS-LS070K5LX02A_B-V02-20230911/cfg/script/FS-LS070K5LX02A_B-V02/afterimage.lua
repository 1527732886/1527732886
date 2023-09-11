package.path = package.path .. ";./cfg/script/FS-LS070K5LX02A_B-V02/?.lua"
local otpFLow = require("luaOtpFlowModule")

local gCurrMdAndStName = luaGetCurrentMdAndSt();
local DStName			= "LS070K5LX02A_B-D-01";
local OtStName		    = "LS070K5LX02A_B-Ot-01";

local DREGADDR				= 0x011C	--D检识别地址
local OTREGADDR				= 0x011D	--OT检识别地址
local gAfterDValue			= 0x0002	--完成D检识别值
local gAfterOtValue			= 0x0002	--完成OT检识别值

local gDevChan 				= 0			--设备通道
local gGpioRote				= 98		--控制画面翻转
--[[
@功能：执行流程
@Return: N/A.
]]--
local function doProcessFunc(devChan)
	local addrTable = {0x114};
	local dataTable = {{0xffff}};
	otpFLow.write2EppsRegs(devChan, addrTable, dataTable, 1);
end

local function doProcess()
	luaSetWaittingDialog(true, "进入残想画面检测脚本执行流程...");
	luaPrintLog(false, "进入残想画面检测脚本执行流程...", false, true);
	luaMSleep(500);
	--luaSetPwrOutput(gDevChan,1,false);--关闭VDD电压

	otpFLow.pgTimingProcess(0, false, "black1.bmp", doProcessFunc, nil, nil,0);--"black.bmp"
	luaMSleep(200);
	--luaSetPwrOutput(gDevChan,1,true);--开启VDD电压
	if gDevChan < 2 then
		luaGpioSet(98, 1);
	end
	otpFLow.pgTimingProcess(gDevChan, true, "afterimage-checkafter.bmp", nil, nil, nil,0);--"afterimage-check.bmp"
	luaMSleep(500);
	--luaGpioSet(gGpioRote, 0);

	luaSetWaittingDialog(false, "完成残想画面检测脚本执行流程");
	luaPrintLog(false, "执行残想画面检测脚本流程成功", false, true);
	luaStopDevChanTask(0);
	luaMSleep(50);
	return bRet;
end

if DStName == gCurrMdAndStName[2] then
	luaMSleep(10);
	otpFLow.pgTimingProcess(gDevChan, false, nil, otpFLow.write2EppsRegs, {DREGADDR}, {{gAfterDValue}},1);
	luaMSleep(10);
elseif OtStName == gCurrMdAndStName[2] then
	luaMSleep(10);
	otpFLow.pgTimingProcess(gDevChan, false, nil, otpFLow.write2EppsRegs, {OTREGADDR}, {{gAfterOtValue}},1);
	luaMSleep(10);
end

luaMSleep(1000);

doProcess();

