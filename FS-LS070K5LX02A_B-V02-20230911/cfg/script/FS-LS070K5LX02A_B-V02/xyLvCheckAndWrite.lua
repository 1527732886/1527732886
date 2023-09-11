local file_path = luaGetCurrentMdAndSt()[1]
package.path = package.path .. ";./cfg/script/"..file_path.."/?.lua"
local otpFLow = require("luaOtpFlowModule")
local logAccess = require("logAccess")

local READ_EDID_CNT = 128;		--定义读取EDID个数

--[[

	执行色域监控
	执行EDID写入
	执行EDID写入后的数据回读比对

]]--

--白色色坐标卡控范围，7.0X02与X02_AB色坐标范围不一致，注意区分
local xWMin = 0.3090;
local xWMax = 0.3150;
local yWMin = 0.3150;
local yWMax = 0.3210;
local LvWMin = 750;			--Lv最小值
local LvWMax = 2000;		--Lv最大值 ??

--黑色画面卡控范围
local LvBlMax = 2;	

--黑白对比度卡控范围
local minDT = 900;

--光学设备相关
local optDevChan = 0;
local optDevMemoryChan = 0; --96 -Off, 1-Factory, 2-user1, 3-user2, ... 32-user31
----------------------------备注，7.0X02与X02_AB色度补正范围不一致，注意区分------------------------------------------------
local gDevChan 				= 0			--设备通道
local REGCHKSUMADDR			= 0x010C	--checksum地址
local REGCOLORADDR			= 0x0068	--色度识别地址

local minGreenHighBit		= 0x51;		--绿色度最小值
local HIGHGREENBIT			= 0x65;		--绿色度初始值
local maxGreenHighBit		= 0x80;		--绿色度最大值

local minBlueHighBit		= 0x55;		--蓝色度最小值
local LOWBLUEBIT			= 0x69;		--蓝色度初始值
local maxBlueHighBit		= 0x80;		--蓝色度最大值

local COLORDEFAULTVALUE		= 0x6569;	--2023年6月14日,初期值7.0X02与7.0X02A_B不一致需要注意

local gBaseHighGreenBit			= HIGHGREENBIT;
local gBaseLowBlueBit			= LOWBLUEBIT;

local function xyBitChange(lowBit)
	if lowBit < 0 then
		lowBit = -(math.floor(-lowBit + 0.5));
	elseif lowBit > 0 then
		lowBit = math.floor(lowBit + 0.5)
	end
	return lowBit;
end

local function doCorrWReg(devChan,data)
	otpFLow.write2EppReg(devChan, REGCOLORADDR, data, 1);
end

local function xyTranslate(xyLvW)
	local highBit = 0.0;
	local lowBit = 0.0;
	--luaShowRGB(0, 0, 0);
	--luaMSleep(200);
	--7.0X02A_B与7.0X02色度补正算法不一致，修改需要注意
	luaPrintLog(false, "进入色度补正算法流程中", false, false);
	lowBit = tonumber(string.format("%0.5f", (0.312 - (xyLvW[1])) / -0.00075));
	lowBit =  xyBitChange(lowBit)
	highBit = tonumber(string.format("%0.5f",(((0.3180 - xyLvW[2])-lowBit*(-0.0011)) /0.0010)));	--2023年6月13日，修正算法
	highBit =  xyBitChange(highBit);
	luaPrintLog(false, string.format("lowBit:%0.5f,highBit:%0.5f",lowBit,highBit), false, false);
	
	luaPrintLog(false, string.format("change lowBit:%0.1f,highBit:%0.1f",lowBit,highBit), false, false);
	local tempLowBit = (gBaseLowBlueBit + math.modf(lowBit));
	local tempHighBit = (gBaseHighGreenBit + math.modf(highBit));
	local correctionValue = (tempHighBit << 8 ) | tempLowBit;

	luaPrintLog(false, string.format("correctionValue:0x%04X",correctionValue), false, false);

	otpFLow.pgTimingProcess(gDevChan, false, nil, doCorrWReg, {nil}, {correctionValue},1);
	otpFLow.pgTimingProcess(gDevChan, true, nil, nil, nil, nil,0);
	luaMSleep(400);
	gBaseLowBlueBit = tempLowBit;
	gBaseHighGreenBit = tempHighBit;
	luaPrintLog(false, string.format("写入值:gBaseBlueBit:0x%02X,gBaseGreenBit:0x%02X",gBaseLowBlueBit,gBaseHighGreenBit), false, false);
	return {lowBit, highBit, correctionValue};
end

local str_Title = "Date,SERIAL_No.,PROBE Serial No.,Corr. Sample No.,V255_L,V255_x,V255_y,Blue Corr. Value (Adj.1),Green Corr. Value (Adj.1),Corr. Write Value(HEX) (Adj.1),V255_L (Adj.1),V255_x (Adj.1),V255_y (Adj.1),Blue Corr. Value (Adj.2),Green Corr. Value (Adj.2),Corr. Write Value(HEX) (Adj.2),V255_L (Adj.2),V255_x (Adj.2),V255_y (Adj.2),V0_L,CONTRAST,JUDGE \r\n"; 
local str_SERIAL_No					= " ";	
local str_PROBESerialNo				= "";
local str_CorrSampleNo				= "3";
local str_V255_L						= "--";
local str_V255_x						= "--";	
local str_V255_y						= "--";	
local str_BlueCorrValueAdj1			= "--";
local str_GreenCorrValueAdj1		= "--";
local str_CorrWriteValueAdj1	= "--";	
local str_V255_LAdj1					= "--";
local str_V255_xAdj1					= "--";
local str_V255_yAdj1					= "--";
local str_BlueCorrValueAdj2			= "--";
local str_GreenCorrValueAdj2		= "--";
local str_CorrWriteValueAdj2	= "--";	
local str_V255_LAdj2					= "--";
local str_V255_xAdj2					= "--";
local str_V255_yAdj2					= "--";	
local str_V0_L							= "--";	
local str_CONTRAST						= "--";	
local str_JUDGE							= "NG";
local str_Canceled						= "CANCELED";
local str_end							="	\r\n";

local canceledFlag						= false;
local V255_xyLv = {};
local xyFlag = {true, true, true};
local xyLvW = {nil};
--local xyLvDt2RegData = {nil};
--local xyLvDt2RegBaseAddr = 0x011D	--xyLvDt起始保存地址

--[[
@function: xyLv 检测
@colorType: 0-白色， 1-黑色， 2-蓝色
@xMin: x最小值
@xMax: x最大值
@yMin: y最小值
@yMax: y最大值
@xyLv：存储xyLv值的table
@Ret: true-检测成功；false-检测失败
]]--
local function xyLvCheck(xyLvW)
	--白色-- 
	local bRet1 = true;
	local bRet2 = true;
	local tempXyLvW = {nil};
	local tempXyLvW1 = {0.0, 0.0, 0.0};
	luaShowRGB(255, 255, 255);
	luaMSleep(1500);
	
	for i = 1, 3 do
		tempXyLvW = {nil};
		luaMeasurexyLv(optDevChan, tempXyLvW);
		tempXyLvW1[1] = tonumber(string.format("%0.5f", tempXyLvW[1])) + tempXyLvW1[1];
		tempXyLvW1[2] = tonumber(string.format("%0.5f", tempXyLvW[2]))+ tempXyLvW1[2];
		tempXyLvW1[3] = tonumber(string.format("%0.5f", tempXyLvW[3]))+ tempXyLvW1[3];
		luaMSleep(50);
	end
	

	xyLvW[1] = tonumber(string.format("%0.4f", tempXyLvW1[1]/3));
	xyLvW[2] = tonumber(string.format("%0.4f", tempXyLvW1[2]/3));
	xyLvW[3] = tonumber(string.format("%0.4f", tempXyLvW1[3]/3));
	
	luaPrintLog(false, "白色W: x="..xyLvW[1].." y="..xyLvW[2].." Lv="..xyLvW[3], false, false);
	
	if xyLvW[1] < xWMin or xyLvW[1] > xWMax then
		luaPrintLog(true, "白色W: x="..xyLvW[1].."色坐标超限", false, false);
		xyFlag[1] = false;
		--return false;
	end
	
	if xyLvW[2] < yWMin or xyLvW[2] > yWMax then
		luaPrintLog(true, "白色W: y="..xyLvW[2].."色坐标超限", false, false);
		xyFlag[2] = false;
		--return false;
	end
	
	if xyLvW[3] < LvWMin or xyLvW[3] > LvWMax then
		luaPrintLog(true, "白色W: Lv="..xyLvW[3].."超出范围", false, false);
		luaPrintLog(true, "白色画面亮度卡控检测未通过", false, false);		
		--return false;
		xyFlag[3] = false;
	end
	if false == xyFlag[1] or false == xyFlag[2] or false == xyFlag[3] then
		return false;
	end
	--tconAccess.sendColorInfo(devChan, 3, xyLvW);
	
	--黑色--
	local xyLvBl = {nil};
	luaShowRGB(0, 0, 0);
	luaMSleep(1500);
	
	for i = 1, 3 do
		--xyLvBl = {nil};
		luaMeasurexyLv(optDevChan, xyLvBl);
		luaMSleep(100);
	end
	
	xyLvBl[1] = tonumber(string.format("%0.4f", xyLvBl[1]));
	xyLvBl[2] = tonumber(string.format("%0.4f", xyLvBl[2]));
	xyLvBl[3] = tonumber(string.format("%0.4f", xyLvBl[3]));
	
	luaPrintLog(false, "黑色B: x="..xyLvBl[1].." y="..xyLvBl[2].." Lv="..xyLvBl[3], false, false);
	
	if xyLvBl[3] > LvBlMax then
		luaPrintLog(true, "Bl: Lv="..xyLvBl[3].."超出范围", false, false);
		luaPrintLog(true, "黑色画面亮度卡控检测未通过", false, false);	
		--return false;
		bRet1 = false;
	end
	
	--黑白对比度--
	local DT = xyLvW[3]/xyLvBl[3];
	DT = tonumber(string.format("%0.0f", DT)); 
	luaPrintLog(false, "对比度DT="..tostring(DT), false, false);
	
	if DT < minDT then
		luaPrintLog(true, "对比度低于"..tostring(minDT), false, false);
		luaPrintLog(true, "对比度卡控检测未通过", false, false);
		bRet2 = false;
	end
	if false == bRet1 then
		str_V0_L = string.format("*%.3f",xyLvBl[3]);
	else
		str_V0_L = string.format("%.3f",xyLvBl[3]);
	end
	if false == bRet2 then
		str_CONTRAST = string.format("*%d",DT);
	else
		str_CONTRAST = string.format("%d",DT);
	end
	
	if false == bRet1 or false == bRet2 then
		return false;
	else
		--[[
		xyLvDt2RegData[1] = tonumber(str_CorrSampleNo);
		xyLvDt2RegData[2] = tonumber(string.format("%X", math.floor(xyLvW[3] + 0.5)));
		xyLvDt2RegData[3] = tonumber(string.format("%X", math.floor(xyLvW[1]*10000 + 0.5)));
		xyLvDt2RegData[4] = tonumber(string.format("%X", math.floor(xyLvW[2]*10000 + 0.5)));
		]]--
		return true;
	end
end

local function xyLvStrProcess(strType, xyLvStrFlag)
	if strType == 0 then
		if false == xyLvStrFlag[1] then
			str_V255_x = string.format("*%.4f",V255_xyLv[1]);
		else
			str_V255_x = string.format("%.4f",V255_xyLv[1]);
		end
		if false == xyLvStrFlag[2] then
			str_V255_y = string.format("*%.4f",V255_xyLv[2]);
		else
			str_V255_y = string.format("%.4f",V255_xyLv[2]);
		end
		if false == xyLvStrFlag[3] then
			str_V255_L = string.format("*%.1f",V255_xyLv[3]);
		else
			str_V255_L = string.format("%.1f",V255_xyLv[3]);
		end
	elseif strType == 1 then
		if false == xyLvStrFlag[1] then
			str_V255_xAdj1 = string.format("*%.4f",xyLvW[1]);
		else
			str_V255_xAdj1 = string.format("%.4f",xyLvW[1]);
		end
		if false == xyLvStrFlag[2] then
			str_V255_yAdj1 = string.format("*%.4f",xyLvW[2]);
		else
			str_V255_yAdj1 = string.format("%.4f",xyLvW[2]);
		end
		if false == xyLvStrFlag[3] then
			str_V255_LAdj1 = string.format("*%.1f",xyLvW[3]);
		else
			str_V255_LAdj1 = string.format("%.1f",xyLvW[3]);
		end
	else
		if false == xyLvStrFlag[1] then
			str_V255_xAdj2 = string.format("*%.4f",xyLvW[1]);
		else
			str_V255_xAdj2 = string.format("%.4f",xyLvW[1]);
		end
		if false == xyLvStrFlag[2] then
			str_V255_yAdj2 = string.format("*%.4f",xyLvW[2]);
		else
			str_V255_yAdj2 = string.format("%.4f",xyLvW[2]);
		end
		if false == xyLvStrFlag[3] then
			str_V255_LAdj2 = string.format("*%.1f",xyLvW[3]);
		else
			str_V255_LAdj2 = string.format("%.1f",xyLvW[3]);
		end
	end
end

local function xyLvCheckMontior()
	local bRet = true;
	local xyLvData = {0, 0, 0x6771};
	local xyTempFlag = {};
	local xyTempFlag1 = {};
	local xyTempFlag2 = {};
	local retryTimes = 3;
	
	while(retryTimes) do
		xyLvW = {0.0001,0.0001,0.0};
		bRet = xyLvCheck(xyLvW);
		if (xyLvW[1] >= 0.0 and xyLvW[1] <= 0.0001) or (xyLvW[2] >= 0.0 and xyLvW[2] <= 0.0001)then
			canceledFlag = true;
			return false;
		end
		
		if retryTimes == 3 then
			xyTempFlag[1] = xyFlag[1];
			xyTempFlag[2] = xyFlag[2];
			xyTempFlag[3] = xyFlag[3];
			V255_xyLv[1] = xyLvW[1];
			V255_xyLv[2] = xyLvW[2];
			V255_xyLv[3] = xyLvW[3];
			if xyFlag[3] == false then
				luaPrintLog(true, "亮度范围超限!", false, true);
				xyLvStrProcess(0, xyTempFlag)
				luaMSleep(1000);
				return false;
			end
		else
			if retryTimes == 2 then
				xyLvStrProcess(1, xyFlag);
				str_BlueCorrValueAdj1 = string.format("%d",xyLvData[1]);
				str_GreenCorrValueAdj1 = string.format("%d",xyLvData[2]);
				if (minBlueHighBit > gBaseLowBlueBit or maxBlueHighBit < gBaseLowBlueBit)or
				   (minGreenHighBit > gBaseHighGreenBit or maxGreenHighBit < gBaseHighGreenBit)then 
					str_CorrWriteValueAdj1 = string.format("*%04X",xyLvData[3]);
				else
					str_CorrWriteValueAdj1 = string.format("%04X",xyLvData[3]);
				end
			elseif retryTimes == 1 then
				xyLvStrProcess(2, xyFlag);
				str_BlueCorrValueAdj2 = string.format("%d",xyLvData[1]);
				str_GreenCorrValueAdj2 = string.format("%d",xyLvData[2]);
				if (minBlueHighBit > gBaseLowBlueBit or maxBlueHighBit < gBaseLowBlueBit)or
				   (minGreenHighBit > gBaseHighGreenBit or maxGreenHighBit < gBaseHighGreenBit)then 
					str_CorrWriteValueAdj2 = string.format("*%04X",xyLvData[3]);
				else
					str_CorrWriteValueAdj2 = string.format("%04X",xyLvData[3]);
				end
			end
		end

		if ((minGreenHighBit > gBaseHighGreenBit or maxGreenHighBit < gBaseHighGreenBit) or
			(minBlueHighBit > gBaseLowBlueBit or maxBlueHighBit < gBaseLowBlueBit)) or (false == bRet) then
			xyLvData = {};
			if retryTimes == 1 then
				xyLvStrProcess(0, xyTempFlag)
				return false;
			end
			if (true == xyFlag[1] and true == xyFlag[2] and false == xyFlag[3]) then
				str_JUDGE = "NG";
				xyLvStrProcess(0, xyTempFlag);
				luaPrintLog(true, "亮度范围超限!", false, true);
				luaMSleep(1000);
				return false;	
			end
			xyLvData = xyTranslate(xyLvW);
			--2023年6月13日，卡控补正后数据
			if (xyLvData[1] > maxBlueHighBit or xyLvData[1] < minBlueHighBit) then
				luaPrintLog(true,string.format("蓝色度补正超过范围[%#X]",xyLvData[1]),false,true)
				str_JUDGE = "NG";
				luaMSleep(2000)
				return false
			elseif (xyLvData[2] > maxGreenHighBit or xyLvData[2] < minGreenHighBit) then
				luaPrintLog(true,string.format("绿色度补正超过范围[%#X]",xyLvData[2]),false,true)
				str_JUDGE = "NG";
				luaMSleep(2000)
				return false
			end
			
			xyFlag[1] = true;
			xyFlag[2] = true;
			xyFlag[3] = true;
			retryTimes = retryTimes - 1;
		else
			if retryTimes == 3 then
				str_V255_x = string.format("%.4f",V255_xyLv[1]);
				str_V255_y = string.format("%.4f",V255_xyLv[2]);
				str_V255_L = string.format("%.1f",V255_xyLv[3]);
			else
				xyLvStrProcess(0, xyTempFlag)
			end
				str_JUDGE = "OK";
			return true;
		end
		
		luaMSleep(10);
	end
	return true;
end

local function processNGProd(devChan)
	local data = {};
	otpFLow.readICReg(gDevChan, REGCOLORADDR, data, 1);
	luaMSleep(10);
	luaPrintLog(false, string.format("读取色度值:[%#X]",data[1]), false, true);
	if nil ~= data[1] and data[1] ~=  COLORDEFAULTVALUE then
		otpFLow.writeICReg(gDevChan, REGCOLORADDR, {COLORDEFAULTVALUE}, 1);
		luaPrintLog(false, "写入初始色度值成功!", false, true);
	end
	return true;
end

local function processChkSum(devChan)
	local data = {};
	local tempChksum = 0;
	--otpFLow.setPanelGpioState(gDevChan, 0);
	for regAddr = 0x000, 0x107,1 do
		luaMSleep(5);
		data = otpFLow.readFromEppReg(gDevChan, regAddr, 1);
		if regAddr==0x29 or regAddr==0x67 or regAddr==0x68 then
			-- luaPrintLog(false, "No Sum 0x29 0x67 0x68", false, false);
		else
			tempChksum = tempChksum + luaMath.andOp(data[1],0x00ff)+luaMath.rShiftOp(data[1],8);
		end
	end
	--luaPrintLog(false, string.format("计算total checkSum地址:[%#x],值:[%#x]",DREGCHKSUMADDR,tempChksum), false, true);
	tempChksum = tonumber(string.format("0x%02x",math.fmod(tempChksum, 256)));
	luaPrintLog(false, string.format("计算checkSum地址:[%#x],写入值:[%#x]",REGCHKSUMADDR,tempChksum), false, false);
	otpFLow.writeICReg(gDevChan, REGCHKSUMADDR, {tempChksum}, 1);
	luaMSleep(10);
	data = {nil};
	otpFLow.readICReg(gDevChan, REGCHKSUMADDR, data, 1);
	if tempChksum ~= data[1] then
		luaPrintLog(true, string.format("计算checkSum地址:[%#x],计算值:[%#x],读取值:[%#x],失败,关电!",REGCHKSUMADDR,tempChksum,data[1]), false, true);
		--otpFLow.setPanelGpioState(gDevChan, 1);
		return false;
	else
		--[[
		if xyLvDt2RegData[1] ~= nil then
			for regAddrIndex = 1, 4,1 do
				otpFLow.writeICReg(gDevChan, xyLvDt2RegBaseAddr+regAddrIndex, {xyLvDt2RegData[regAddrIndex]}, 1);
			end
		end
		]]--
        luaPrintLog(false, string.format("计算checkSum地址:[%#x],读取值:[%#x]",REGCHKSUMADDR,data[1]), false, true);
	end
	--otpFLow.setPanelGpioState(gDevChan, 1);
	return true;
end

--**********************************************获取条码信息*******************************
--local str_Module_NO       = ""
--local str_BackLight_NO    = ""
local timeBase = 1621987199;--
local oneDayBase = 24*60*60;--
local gprobeNo	= 1;
local function doReadSeriaNo()
	local idTable = {};
	local serialNoTable = {};
	--luaSetxyLvMemoryChan(optDevChan, 1);
	--luaMSleep(1000);
	local bRet = luaIDPInOptical(gDevChan, gprobeNo, idTable, serialNoTable);
	if false == bRet then 
		return false;
	else
		local serialNoTemp = string.sub(serialNoTable[1], 2);
		--luaPrintLog(false, "获取id:"..idTable[1].." serialNo:"..serialNoTemp, false, true);
		str_PROBESerialNo = str_PROBESerialNo..serialNoTemp;
	end
	return true;
end

local function readFile()
	--assert("SNCode.txt","file open failed-文件打开失败");

	--local y = 1
	local file = io.open("/tmp/SNCode.txt","r");
	if file == nil then
		luaPrintLog(true, "未进行扫码操作，关电!", false, true);
		str_SERIAL_No = "123456";
		return true;--false;
	end
	for line in file:lines() do
		if line == nil then
			luaPrintLog(true, "未进行扫码操作，关电!", false, true);
			
			return false;
		end
		str_SERIAL_No = str_SERIAL_No..line;
	end 
	io.close(file);
	os.remove("/tmp/SNCode.txt");
	
	if false == doReadSeriaNo() then
		luaPrintLog(true, "310通讯失败,获取序列号失败,关电!", false, true);
		return false;
	end
	
	local timenow = os.time() - timeBase;
	local timeTemp = 0;
	--[[
	file = io.open("/tmp/310-corrTime.txt","r");
	for line in file:lines() do
		if line == nil then
			luaPrintLog(true, "24小时未进行校准操作,关电!", false, true);
			return false;
		end
		timeTemp = tonumber(line);
		break;
		
	end 
	io.close(file);
	if timenow - timeTemp > oneDayBase then
		luaPrintLog(true, "24小时未进行校准操作,关电!", false, true);
		return false;
	end
	]]--
	
	--str_SERIAL_No = str_SERIAL_No.."\n";
	 luaPrintLog(false,"SERIAL_No:"..str_SERIAL_No.." PROBENo:"..str_PROBESerialNo,false,false);
	return true;
end

FILE_PATH = "";
local tPanelId = {
"LS070K5LX02",
};
local function logParase()
	--[[
  local strHead;
  
	for i = 1, 128 do
		FILE_PATH = "";
		FILE_PATH = string.format("/mnt/sda%d/",i);
		if logAccess.file_exists(FILE_PATH) == true then
			FILE_PATH = FILE_PATH.."data/log/";
			local bRet = os.execute("mkdir -p "..FILE_PATH);
			if bRet == true then
				--luaPrintLog(false, FILE_PATH, false, false);
				break;
			end
			luaMSleep(5);
			--luaPrintLog(true, FILE_PATH, false, false);
		end
	end
  
  local path = FILE_PATH..tPanelId[1].."_"..os.date("%Y%m%d")..".csv";

  file = io.open(path , "rb");

  if file == nil then
   strHead = str_Title;--"id,time,SN,R_X,R_Y,G_X,G_Y,B_X,B_Y,W_X,W_Y,W_LV\n";
   	file = assert(io.open(path, "a+"));
    io.output(file) ;
    io.write(strHead);
	 io.close(file) ;
  end
--[[
  local n = 0;
  local file1 = io.open(path,"r+");
  for line in file1:lines() do
    n = n + 1;
  end
  io.close(file1) ;
  local IDnumber = n;--%A %p

  local time1=os.date("%Y/%m/%d %H:%M:%S");--"%Y/%m/%d %A %p %H:%M:%S"

   local temp = {};
   local logData = {};
   --table.insert(temp,n);
    table.insert(temp,time1);
   table.insert(temp,str_SERIAL_No);
   table.insert(temp,str_PROBESerialNo);
   table.insert(temp,str_CorrSampleNo);
   if canceledFlag == true then
	 table.insert(temp,str_Canceled);
   else
	   table.insert(temp,str_V255_L);
	   table.insert(temp,str_V255_x);
	   table.insert(temp,str_V255_y);
	   
	   table.insert(temp,str_BlueCorrValueAdj1);
	   table.insert(temp,str_GreenCorrValueAdj1);
	   table.insert(temp,str_CorrWriteValueAdj1);
	   table.insert(temp,str_V255_LAdj1);
	   table.insert(temp,str_V255_xAdj1);
	   table.insert(temp,str_V255_yAdj1);
	   
	   table.insert(temp,str_BlueCorrValueAdj2);
	   table.insert(temp,str_GreenCorrValueAdj2);
	   table.insert(temp,str_CorrWriteValueAdj2);
	   table.insert(temp,str_V255_LAdj2);
	   table.insert(temp,str_V255_xAdj2);
	   table.insert(temp,str_V255_yAdj2);
	   
	   table.insert(temp,str_V0_L);
	   table.insert(temp,str_CONTRAST);
	   
	   table.insert(temp,str_JUDGE);
   end
   table.insert(logData,temp);
   logAccess.writeCsv(path, logData);
   luaMSleep(10);
   logAccess.readCsv(path);
   ]]--
   ----------------------------------------------------透传PC-------------------------------------------------------------------
      
   local tranStr = "";
   local stationName = luaGetCurrentMdAndSt()[2];
   local str_Title = "startTime,SNCode,V255_L,V255_x,V255_y,Blue Corr. Value (Adj.1),Green Corr. Value (Adj.1),Corr. Write Value(HEX) (Adj.1),V255_L (Adj.1),V255_x (Adj.1),V255_y (Adj.1),Blue Corr. Value (Adj.2),Green Corr. Value (Adj.2),Corr. Write Value(HEX) (Adj.2),V255_L (Adj.2),V255_x (Adj.2),V255_y (Adj.2),V0_L,CONTRAST,JUDGE,EndTime\n"; 


   tranStr=string.format([[{"key": "stationName","Data": "%s"}]],stationName)
   luaSendTransparentMessage(0,tranStr)  --透传信息
   tranStr = "";
   luaMSleep(20);
   tranStr = string.format([[{"key": "logHeadName","Data": "%s"}]],str_Title);
   luaSendTransparentMessage(0,tranStr)  --透传信息


   local temp = {};
   local dataStr = "";


   if canceledFlag == true then
     table.insert(temp,str_Canceled);
     dataStr = str_Canceled.."\n";
     tranStr = string.format([[{"key": "NgData","Data": "%s"}]],dataStr);
   else
     table.insert(temp,str_V255_L);
     table.insert(temp,str_V255_x);
     table.insert(temp,str_V255_y);
        
     table.insert(temp,str_BlueCorrValueAdj1);
     table.insert(temp,str_GreenCorrValueAdj1);
     table.insert(temp,str_CorrWriteValueAdj1);
     table.insert(temp,str_V255_LAdj1);
     table.insert(temp,str_V255_xAdj1);
     table.insert(temp,str_V255_yAdj1);
        
     table.insert(temp,str_BlueCorrValueAdj2);
     table.insert(temp,str_GreenCorrValueAdj2);
     table.insert(temp,str_CorrWriteValueAdj2);
     table.insert(temp,str_V255_LAdj2);
     table.insert(temp,str_V255_xAdj2);
     table.insert(temp,str_V255_yAdj2);
        
     table.insert(temp,str_V0_L);
     table.insert(temp,str_CONTRAST);
        
     table.insert(temp,str_JUDGE);
      
   for i = 1, #temp-1 do
        dataStr = dataStr..temp[i].."\n";
   end
   dataStr = dataStr..temp[#temp];
      
   tranStr=string.format([[{"key": "OkData","Data": "%s"}]],dataStr);
   end
   luaPrintLog(false,tranStr,false,false)
   luaSendTransparentMessage(0,tranStr)  --透传信息
end
--[[
@功能：执行流程
@Return: N/A.
]]--
local function doProcess()
	local devChan = 0;
	--luaSetWaittingDialog(true, "正在执行色域监控流程...");
	luaPrintLog(false, "正在执行色域监控流程...", false, true);
	--1st step: 设置光学设备校准通道 
	luaSetxyLvMemoryChan(optDevChan, optDevMemoryChan);
	luaMSleep(2000);
	--1st step 判断是否连接了色彩分析仪
	if luaOpticalDeviceConnectedState(optDevChan) == false then
		luaPrintLog(true, "光学设备未连接，没有执行色域监控流程，程序异常关电!", false, true);
		--luaTriggerPowerOff(false);
		--luaPowerOff();--关闭VDD电压
		canceledFlag = true;
		return false;
	end
	luaMSleep(200);
	local tempXyLvW = {nil};
	local bRet = luaMeasurexyLv(optDevChan, tempXyLvW);
	
	luaMSleep(200);
	
	if false == bRet then
		canceledFlag = true;
		return false;
	else
		otpFLow.pgTimingProcess(gDevChan, false, nil, processNGProd, {nil}, nil,0);
		otpFLow.pgTimingProcess(gDevChan, true, nil, nil, {nil}, nil,0);
	end
	--2nd step: 开始检测 
	local bSuccess = xyLvCheckMontior();
	--luaSetWaittingDialog(false, "完成执行色域监控流程");
	
	if bSuccess then
		luaPrintLog(false, "所有检测项通过检测", false, true);
		
		local bRet = true;--processChkSum();
		bRet = otpFLow.pgTimingProcess(gDevChan, false, nil, processChkSum, {nil}, nil,0);
		
		if bRet == false then
			luaPrintLog(false, "checkSum计算失败", false, true);
			return false;
		else
			otpFLow.pgTimingProcess(gDevChan, true, nil, nil, {nil}, nil,0);
		end
		
	else
		luaPrintLog(true, "所有检测项中存在异常检测，检测不通过", false, true);
	end
	return bSuccess;
end
if false == readFile() then
	--luaMSleep(1000);
	--luaPrintLog(true, "未进行扫码或未获取探头序列号或24小时未校准或操作，关电!", false, true);
	luaMSleep(3000);
	luaTriggerPowerOff(false);--luaPowerOff();
	return false;
end
luaSetOpticalDeviceType(0);
luaMSleep(20);
local bResult = doProcess();
--luaMSleep(100);
--luaReleaseOpticalMode(optDevChan);
luaMSleep(20);
logParase();
if false == bResult then
	if canceledFlag == true then
		luaPrintLog(true, "310通讯异常,检测流程失败，关电!", false, true);
	else 
		luaPrintLog(true, "色度补正NG，关电!", false, true);
	end
	luaMSleep(3000);
	luaTriggerPowerOff(false);
else
	local CREGADDR				= 0x011A	
	local OTHERCREGADDR		= 0x0112	
	local gAfterCValue			= 0x0002	
	local dayAddr = 0x114;
	local timeAddr = 0x115;
	
	local tempDate = os.date("*t", os.time());
	local month = tonumber(tempDate.month);
	local day = tonumber(tempDate.day);
	local hour = tonumber(tempDate.hour);
	local minute = tonumber(tempDate.min);
	local dayData = string.format("%02d%02d",month,day);--(month<<8 | day);
	local timeData = string.format("%02d%02d",hour,minute);--(hour<<8 | minute);
	local addrTable = {CREGADDR, OTHERCREGADDR, dayAddr, timeAddr};
	local dataTable = {{gAfterCValue}, {gAfterCValue}, {dayData}, {timeData}};
	otpFLow.pgTimingProcess(gDevChan, false, nil, otpFLow.write2EppsRegs, addrTable, dataTable,4);
	
end
