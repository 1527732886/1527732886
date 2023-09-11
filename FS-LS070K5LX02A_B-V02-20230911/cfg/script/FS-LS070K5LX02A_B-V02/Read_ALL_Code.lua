package.path = package.path .. ";./cfg/script/FS-LS070K5LX02A_B-V02/?.lua"
local otpFLow = require("luaOtpFlowModule")
local luaMath = require("luaMath")	--加载扩展lua数学库

local gEppRegAddrStart				= 0x0000		--用于EPPROM CODE比对起始地址
local regValueTemp1 = {};
local regValueTemp2 = {};
local gDevChan = 0;
local str = "";
local fileName = "CheckCodeLog.txt";
local FILE_PATH = "/LS070K5LX02A_B/";

luaSelectUDiskFile(gDevChan,FILE_PATH,fileName);

otpFLow.setPanelGpioState(gDevChan,0)
for gEppRegAddr = 0x0000,0x011f,2 do
	if gEppRegAddrStart == gEppRegAddr then
		local str = "正在进行CODE读取操作!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\r\n";
		luaPrintLog(false,str,false,false);
		luaMSleep(10);
	end
	regValueTemp1 = otpFLow.readFromEppReg(gDevChan, gEppRegAddr, 1);
	regValueTemp2 = otpFLow.readFromEppReg(gDevChan, gEppRegAddr+1, 1);
	if gEppRegAddr==0x0114 then
		str = string.format("测定检作业日期地址:%#x,日期:%d,时间地址:%#x,时间:%d\r\n", gEppRegAddr, regValueTemp1[1],gEppRegAddr+1, regValueTemp2[1]);
	else
		str = string.format("地址:%#x,值:%#x,地址:%#x,值:%#x\r\n", gEppRegAddr, regValueTemp1[1],gEppRegAddr+1, regValueTemp2[1]);
	end
	luaMSleep(100);
	luaWriteLog2UDisk(gDevChan, str, string.len(str))
	luaPrintLog(false,str,false,false);
end
luaPrintLog(false,"Code log已经全部保存U盘"..FILE_PATH..fileName,false,true);
otpFLow.setPanelGpioState(gDevChan,1)
