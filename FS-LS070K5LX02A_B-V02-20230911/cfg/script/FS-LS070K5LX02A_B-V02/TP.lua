package.path = package.path .. ";./cfg/script/FS-LS070K5LX02A_B-V02/?.lua"
local otpFLow = require("luaOtpFlowModule")

local gCurrMdAndStName = luaGetCurrentMdAndSt();
local E2StName			= "LS070K5LX02A_B-E2-00";
local E2REGADDR				= 0x0119	--FS E2检识别地址
local gAfterE2Value			= 0x0002	--完成E2检识别值
local OTHERE2REGADDR		= 0x0111	--其他厂商E2检识别地址

if E2StName == gCurrMdAndStName[2] then
	luaMSleep(10);
	otpFLow.pgTimingProcess(0, false, nil, otpFLow.write2EppsRegs, {E2REGADDR, OTHERE2REGADDR}, {{gAfterE2Value},{gAfterE2Value}},2);
	luaMSleep(10);
end


luaPrintLog(false, "请进行TP检测!", false, true);