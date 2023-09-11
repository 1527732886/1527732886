package.path = package.path .. ";./cfg/script/FS-LS070K5LX02A_B-V02/?.lua"
local otpFLow = require("luaOtpFlowModule")
local luaMath = require("luaMath")	--加载扩展lua数学库

local gDevChan 				= 0			--设备通道
local dayAddr = 0x114;
local timeAddr = 0x115;
local tempDate = os.date("*t", os.time());
local month = tonumber(tempDate.month);
local day = tonumber(tempDate.day);
local hour = tonumber(tempDate.hour);
local minute = tonumber(tempDate.min);
local dayData = string.format("%02d%02d",month,day);--(month<<8 | day);
local timeData = string.format("%02d%02d",hour,minute);--(hour<<8 | minute);


local code_addr = {0x0110,0x0111,0x0112,0x0113,0x0118,0x119,0x11A,0x11B,0x11C,0x11D,0x11E,0x11F, dayAddr, timeAddr};
local code_ok = {{0x02},{0x02},{0x02},{0x02},{0x02},{0x02},{0x02},{0x02},{0x02},{0x02},{0x02},{0x02},{dayData},{timeData}}

otpFLow.pgTimingProcess(gDevChan, false, nil, otpFLow.write2EppsRegs,code_addr , code_ok,#code_addr);
local str = string.format("测定检作业日期地址:%#x,日期:%d,时间地址:%#x,时间:%d\r\n", 0x0114, dayData,0x0115,timeData);
luaPrintLog(false,str,false,false)
luaPrintLog(false,"写入完成",false,false)
