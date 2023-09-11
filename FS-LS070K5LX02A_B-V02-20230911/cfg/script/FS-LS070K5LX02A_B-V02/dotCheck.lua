package.path = package.path .. ";./cfg/script/FS-LS070K5LX02A_B-V02/?.lua"
local otpFLow = require("luaOtpFlowModule")

local gCurrMdAndStName = luaGetCurrentMdAndSt();
local E1StName			= "LS070K5LX02A_B-E1-01";
local E1REGADDR				= 0x0118	--E检识别地址
local gAfterE1Value			= 0x0002	--完成E检识别值


if E1StName == gCurrMdAndStName[2] then
    luaMSleep(10);
	otpFLow.pgTimingProcess(0, false, nil, otpFLow.write2EppsRegs, {E1REGADDR,0X110}, {{gAfterE1Value},{gAfterE1Value}},1);
	luaMSleep(10);
end

luaPrintLog(false, "请进行拟似画面检查操作流程！", false, true);