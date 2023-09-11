package.path = package.path .. ";./cfg/script/FS-LS070K5LX02A_B-V02/?.lua"
local otpFLow = require("luaOtpFlowModule")

local gDevChan 				= 0			--设备通道
local E1REGADDR				= 0x0118	--E1检识别地址
local gBeforeE1Value		= 0x0001	--开始E1检识别值
local gAfterE1Value			= 0x0002	--完成E1检识别值
local DREGCHKSUMADDR		= 0x010C	--checksum地址

local gDevChan 				= 0			--设备通道
local E1REGADDR				= 0x0118	--E1检识别地址
local gBeforeE1Value		= 0x0001	--开始E1检识别值
local gAfterE1Value			= 0x0002	--完成E1检识别值
local DREGCHKSUMADDR		= 0x010C	--checksum地址
local vcomVal 				= 0;

local function readVcomFile()
	local file = io.open("/tmp/flicker.txt","r");
	if file == nil then
		luaPrintLog(true, "vcomVal异常,关电!", false, true);
		return false;
	end
	for line in file:lines() do
		if line == nil then
			luaPrintLog(true, "vcomVal异常,关电!", false, true);
			return false;
		end
		vcomVal = tonumber(line,16);
		luaPrintLog(false, string.format("rVcomVal:%#x",vcomVal), false, true);
		break;
	end
	io.close(file);
	os.remove("/tmp/flicker.txt");
	return true;
end
local function chkSumProcess()
	local data = {};
	local tempChksum = 0;

	--otpFLow.setPanelGpioState(gDevChan, 0);
	readVcomFile();
	if vcomVal > 0 then
		otpFLow.writeVcom(gDevChan, vcomVal);
		luaMSleep(10);
		data[1] = otpFLow.readVcom(gDevChan);
		if vcomVal ~= data[1] then
			luaPrintLog(true, string.format("wVcomVal:[%#x],读取值:[%#x],失败!",vcomVal,data[1]), false, true);
			otpFLow.setPanelGpioState(gDevChan, 1);
			return false;
		end
	else
		luaPrintLog(true, string.format("vcomVal获取异常!"), false, true);
		otpFLow.setPanelGpioState(gDevChan, 1);
		return false;
	end
	for regAddr = 0x000, 0x107,1 do
		luaMSleep(5);
		data = otpFLow.readFromEppReg(gDevChan, regAddr, 1);
		if regAddr==0x29 or regAddr==0x67 or regAddr==0x68 then
			luaPrintLog(false, "No Sum 0x29 0x67 0x68", false, false);
		else
			tempChksum = tempChksum + luaMath.andOp(data[1],0x00ff)+luaMath.rShiftOp(data[1],8);
		end
	end
	luaPrintLog(false, string.format("计算total checkSum地址:[%#x],值:[%#x]",DREGCHKSUMADDR,tempChksum), false, false);
	tempChksum = tonumber(string.format("0x%02x",math.fmod(tempChksum, 256)));
	--luaPrintLog(false, string.format("计算checkSum地址:[%#x],值:[%#x]",DREGCHKSUMADDR,tempChksum), false, true);
	otpFLow.writeICReg(gDevChan, DREGCHKSUMADDR, {tempChksum}, 1);
	luaMSleep(10);
	otpFLow.readICReg(gDevChan, DREGCHKSUMADDR, data, 1);
	if tempChksum ~= data[1] then
		luaPrintLog(true, string.format("写入checkSum地址:[%#x],计算值:[%#x],读取值:[%#x],失败,关电!",DREGCHKSUMADDR,tempChksum,data[1]), false, true);
		otpFLow.setPanelGpioState(gDevChan, 1);
		return false;
	end
	--otpFLow.setPanelGpioState(gDevChan, 1);
	return true;
end
--[[
@功能：执行流程
@Return: N/A.
]]--
local function doProcess(devChan)
	luaMSleep(1000);
	luaSetWaittingDialog(true, "进入写入和比对初始化Code脚本执行流程...");
	luaPrintLog(false, "进入写入和比对初始化Code脚本执行流程...", false, true);
	local bRet = true;

	--[[bRet = otpFLow.checkEInitCode(gDevChan, true);
	if bRet == false then
		luaSetWaittingDialog(false, "执行写入初始化Code流程失败,程序异常关电!");
		--luaSetPwrOutput(gDevChan,1,false);--关闭VDD电压
		luaPrintLog(true, "执行写入初始化Code流程失败,程序异常关电!", false, true);
		luaPowerOff();
		return false;
	else]]--
	bRet = chkSumProcess();
	if false == bRet then
		luaPrintLog(true, "计算checkSum失败,关电!", false, true);
		luaTriggerPowerOff(false);--luaPowerOff();
		return false;
	end

		bRet = otpFLow.checkEInitCode(gDevChan, false);
		if bRet == false then
			luaSetWaittingDialog(false, "执行比对初始化Code失败,程序异常关电!");
			--luaSetPwrOutput(gDevChan,1,false);--关闭VDD电压
			luaPrintLog(true, "执行比对初始化Code流程失败,程序异常关电!", false, true);
			luaTriggerPowerOff(false);--luaPowerOff();
			return false;
		else
			luaSetWaittingDialog(false, "完成写入和比对初始化Code脚本执行流程!");
			luaPrintLog(false, "执行写入和比对初始化Code脚本执行流程流程成功!", false, true);
			local str = " ";
			str = string.format("code烧录、比对成功!\r\n");
			luaWriteLog2UDisk(gDevChan, str, string.len(str));
			luaMSleep(10);
		end
	--end
	return bRet;
end

--doProcess();
bRet = otpFLow.pgTimingProcess(gDevChan, false, "black1.bmp", doProcess, nil, nil,0);
if false == bRet then
	;--luaPowerOff();
else
	otpFLow.pgTimingProcess(gDevChan, true, "black1.bmp", nil, nil, nil,0);
end
