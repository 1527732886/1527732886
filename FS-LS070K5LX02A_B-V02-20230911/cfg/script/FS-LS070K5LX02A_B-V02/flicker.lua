package.path = package.path .. ";./cfg/script/FS-LS070K5LX02A_B-V02/?.lua"
local otpFLow = require("luaOtpFlowModule")

local gDevChan 				= 0			--设备通道
local gOptDevChan 			= 0			--光学设备通道
local gExternalFlag 		= false		--PG设备内部调试Vcom流程标识
local gFlickerMaxValue		= 15.00
local gFlickerMinValue		= 0.01
local gVcomMinValue			= 0xa0
local gVcomDefValue			= 0xd3
local gVcomMaxValue			= 0x104
local vcomVal				= 0;

local function writeVcomFile(wVcomVal)
	local file = io.open("/tmp/flicker.txt","w");
	if file == nil then
		luaPrintLog(true, "wVcomVal异常,关电!", false, true);
		return false;
	end
	luaPrintLog(false, string.format("wVcomVal:%s",wVcomVal), false, true);
	io.output(file)
	io.write(wVcomVal)
	io.write("\n")
   io.close(file)
	return true;
end
--[[
@功能：设置GPIO状态
@devChan(number): 设备通道，其范围为0-3
@state(number): gpio状态值，范围0-1
@Return: N/A
]]--
local function setPanelGpioState(state)
	luaMSleep(20);
	luaGpioSet(97, state);--EEPEN(通道0,1)
	luaMSleep(20);
end
--[[
@功能：执行流程
@Return: N/A.
]]--
local function doProcess()
	luaPrintLog(false, "进入Flicker脚本执行流程...", false, true);
	luaSetWaittingDialog(true, "进入Flicker调节脚本执行流程...");
	local bRet = true;

	--1st step 判断是否连接了色彩分析仪
	if luaOpticalDeviceConnectedState(gOptDevChan) == false then
		luaPrintLog(true, "光学设备未连接，没有执行flicker调节流程，程序异常关电!", false, true);
		--luaTriggerPowerOff(false);
		luaTriggerPowerOff(false);--luaPowerOff();--关闭VDD电压
		return false;
	end

	--2nd step 读取屏表面辉度判断闪烁探头是否放置 -----230721
	luaSetOpticalDeviceType(3); ----FS
	local memCh = 1;
	local opDev = 0;
	local Lv= {};
	local LvMinValue = 5;
	luaSetxyLvMemoryChan(opDev, memCh);
	luaMSleep(200);
	luaMeasurexyLv(opDev, Lv);

	if Lv[3] == nil then
		luaPrintLog(true,"亮度值获取错误,请检查探头连接情况@",false,true);
		return false;
	end
	if Lv[3] < LvMinValue then
	    --luaPrintLog(true,"",false,true);
	    luaPrintLog(true, string.format("Lv:%.2f,请检查闪烁探头是否正确放置!",Lv[3]), false, true);
	    --str = string.format("asdasdad:[%d]",Lv[3])
	    --luaPrintLog(false,str,false,false)
	    luaMSleep(2000);
	    return false;
	end

	--3rd step：开启自动flick调节任务
	setPanelGpioState(0);
	otpFLow.writeICVcom(gDevChan, 0xd3);--给初始vcom值
	bRet = luaStartAutoAdjustVcom(0, 0);

	if bRet == true then
		luaMSleep(50);
		local vcomVal = otpFLow.readICVcom(gDevChan);
		luaMSleep(50);
		if gVcomMinValue <= vcomVal - 5 then
			vcomVal = vcomVal - 5;--XP要求最佳值减5
		end
		--vcomVal = 0xE5;
		--otpFLow.writeVcom(gDevChan, vcomVal);
		otpFLow.writeICVcom(gDevChan, vcomVal);
		--setPanelGpioState(1);
		luaMSleep(10);
		local flickerValue = {};
		luaMeasureFlick(gDevChan, flickerValue);
		luaMSleep(20);
		local str = " ";
		if flickerValue[1]  == nil then
			str = string.format("AutoVcomAdj Value:0X%02X,flick:nil,NG!\r\n",vcomVal);
			luaPrintLog(true, str, false, true);
			luaWriteLog2UDisk(0, str, string.len(str));
			return false;
		elseif( vcomVal <  gVcomMinValue or gVcomMaxValue < vcomVal or flickerValue[1] > gFlickerMaxValue or  flickerValue[1] < gFlickerMinValue )then
			str = string.format("AutoVcomAdj Value:0X%02X,flick:%f,NG!\r\n",vcomVal,flickerValue[1]);
			luaPrintLog(true, str, false, true);
			luaWriteLog2UDisk(0, str, string.len(str));
			return false;
		end
		str = string.format("vcom值:%#x,flick值:%.3f,成功!\r\n",vcomVal,flickerValue[1]);
		luaWriteLog2UDisk(gDevChan, str, string.len(str));
		luaMSleep(10);
		luaPrintLog(false, str, false, true);
		writeVcomFile(string.format("%x",vcomVal));
		--bRet = otpFLow.pgTimingProcess(gDevChan, false, "black1.bmp", otpFLow.writeVcom, {nil}, vcomVal,1);
        str = string.format("vcom值:%#x,flick值:%.3f,成功!\r\n",vcomVal,flickerValue[1]);
		luaMSleep(10);
		luaPrintLog(false, str, false, true);

	end

	if bRet == false then
		--otpFLow.writeVcom(gDevChan, gVcomDefValue);
		luaPrintLog(true, "调节Vcom值失败,关电!", false, true);
		--setPanelGpioState(1);
		return false;
	else
		--otpFLow.pgTimingProcess(gDevChan, true, "flicker1.bmp", nil, nil, nil,0);
	end
	luaSetWaittingDialog(false, "完成Flicker调节脚本执行流程");
	return bRet;
end
luaSetOpticalDeviceType(3);--sensor
luaMSleep(20);
if false == doProcess()then
	luaSetWaittingDialog(false, "完成Flicker调节脚本执行流程");
	setPanelGpioState(1);
	luaMSleep(1000);
	luaTriggerPowerOff(false);
end
