package.path = package.path .. ";./cfg/script/FS-LS070K5LX02A_B-V02/?.lua"
local otpFLow = require("luaOtpFlowModule")
--[[
	IC hx8272
]]--

local gPowerItemVblType = 4		--VBL电源项
local isReSetTimes		= false			--判断有没有PC时间透传过来

local VBL_CONF_MIN_VOLTAGE 	= 27550		-- VBL配置输出最小电压值（单位：mV）
local VBL_CONF_MAX_VOLTAGE 	= 34650		-- VBL配置输出最大电压值（单位：mV）

local VBL_CONF_MIN_CURRENT 	= 79		-- VBL配置输出最小电流值（单位：mA）
local VBL_CONF_MAX_CURRENT 	= 81		-- VBL配置输出最大电流值（单位：mA）

local E1StName			= "LS070K5LX02A_B-E1-01";
local E2StName			= "LS070K5LX02A_B-E2-00";
local MeStName			= "LS070K5LX02A_B-Me-00";
local DStName			= "LS070K5LX02A_B-D-01";
local OtStName		    = "LS070K5LX02A_B-Ot-00";
local CheckCodeStName	= "LS070K5LX02A_B-CHECKCODE";

local E1StFinName	= "black.bmp";
local E2StFinName  	= "TP.bmp";
local DStFinName	= "afterimage-check.bmp";
local OtStFinName	= "afterimage-check.bmp";--0908更改图片名
local MeStFinName	= "white.bmp";
local dotCkPicName	= "black.bmp";
local knobPicName	= "v0-v255.bmp";
local codeCkPicName = "black-checkcode.bmp";
local gCurrMdAndStName = {nil};

local gDotFlag = true;
local gLedItem = 2;					--背光灯串数量

local WHITE_COLOR	= 0xFFFFFF;		--白色
local RED_COLOR		= 0x3C0000;		--红色60
local GREEN_COLOR	= 0x002C00;		--绿色44
local BLUE_COLOR	= 0x000060;		--蓝色96
local BLACK_COLOR	= 0x000000;		--黑色
local gDotPiex		= 1;

local gRMaxValue = 5.0;	--基板电阻最大值(欧姆)
local gAgMaxValue = 20000;	--银胶电阻最大值(欧姆)

local isFailDetected = false;

local E1REGADDR				= 0x0118	--E检识别地址
local OTHERE1REGADDR		= 0x0110	--其他厂商E1检识别地址
local gBeforeE1Value		    = 0x0001	--开始E检识别值
local gAfterE1Value			= 0x0002	--完成E检识别值

local E2REGADDR				= 0x0119	--FS E2检识别地址
local OTHERE2REGADDR		= 0x0111	--其他厂商E2检识别地址
local gBeforeE2Value		    = 0x0001	--开始E2检识别值
local gAfterE2Value			= 0x0002	--完成E2检识别值


local CREGADDR				= 0x011A	--C检识别地址
local OTHERCREGADDR			= 0x0112	--其他厂商C检识别地址
local gBeforeCValue			= 0x0001	--开始C检识别值
local gAfterCValue			= 0x0002	--完成C检识别值

local DREGADDR				= 0x011C	--D检识别地址
local gBeforeDValue			= 0x0001	--开始D检识别值
local gAfterDValue			= 0x0002	--完成D检识别值

local OTREGADDR				= 0x011D	--OT检识别地址
local gBeforeOtValue		    = 0x0001	--开始D检识别值
local gAfterOtValue			= 0x0002	--完成D检识别值

local DREGCOLORADDR				= 0x0068	--D检色度识别地址
local DREGCHKSUMADDR			= 0x010C	--D检checksum地址

local gEppRegAddrStart				= 0x0000		--用于EPPROM CODE比对起始地址
local gEppRegAddrStop				= 0x011D		--用于EPPROM CODE比对结束地址
local gEppRegAddr					= 0x0000		--用于EPPROM CODE比对地址

----------------------------备注，7.0X02与X02_AB色度补正范围不一致，注意区分------------------------------------------------
local gColorHighMaxValue			= 0x80			--用于色度(绿色-高8位)卡控
local gColorHighMinValue			= 0x51			--用于色度(绿色-高8位)卡控
local gColorLowMaxValue				= 0x80			--用于色度(青色-低8位)卡控
local gColorLowMinValue				= 0x55			--用于色度(青色-低8位)卡控

local dayAddr = 0x114;
local timeAddr = 0x115;

local slaveAddr = 0x52 --7bit 寄存器地址

local function configureVI2cFmt(devChan)
	local byteBits = 8; --单位字节 8 位
	local ACK = 0; --响应 ACK
	local udelay = 0; --操作完毕无延时
	luaSetVI2CFmt(devChan, 0, byteBits, ACK,udelay); --器件字节格式
	luaSetVI2CFmt(devChan, 1, byteBits, ACK,udelay); --寄存器字节格式
	luaSetVI2CFmt(devChan, 2, byteBits, ACK,udelay); --数据字节格式
end

luaSetVSpiFreq(0,0);
configureVI2cFmt(0);
--[[
@功能：NTC检测
   @Return: N/A.
]]--
local gDevChan = 0;        --设备通道选择（0/1为左通道，2/3为有通道）
local gMinNtcValue = 7000    --NTC最小阻值范围
local gMaxNtcValue = 15000   --NTC最大阻值范围
 local  function checkNtc()
	luaSetPwrOutput(gDevChan, 4, true)	--使能VBL输出
	luaMSleep(200)
	luaSetPwrOutput(gDevChan, 10, true)	--使能VBL输出
	luaMSleep(200);
	--1st step: 检测NTC值
	local bRet = luaCheckNTC();
	local str = " ";
	--2nd step: 读取实时NTC值
	local tempValue = luaReadNtcValue(gDevChan);
	if (gMinNtcValue <= tempValue and gMaxNtcValue >= tempValue)then
		str = string.format("读取NTC值：%.1f欧姆在[%d~%d]欧姆卡控范围内\r\n",tempValue, gMinNtcValue, gMaxNtcValue);
		luaPrintLog(false, str, false, true);

	else
		str = string.format("读取NTC值：%.1f欧姆不在[%d~%d]欧姆卡控范围内\r\n",tempValue, gMinNtcValue, gMaxNtcValue);
		luaPrintLog(true, str, false, true);
		return false;
	end
	luaSetPwrOutput(gDevChan, 10, false)	--关闭VBL输出
	luaMSleep(50);
	luaSetPwrOutput(gDevChan, 4, false)	--使能VBL输出
	luaWriteLog2UDisk(gDevChan, str, string.len(str));
	return true;
end
--[[
@功能：写数据到IC寄存器
@devChan(number): 设备通道，其范围为0-3
@regAddr(number): IC寄存器地址
@data(table): 写入的数据
@count(number): 写入的数据个数
@Return(boolean):
]]--
function write2ICReg(devChan, regAddr, data, count)
	local bRet = luaVI2CWrite(devChan, slaveAddr, {regAddr}, data, count);
	return bRet;
end

--[[
@功能：从IC寄存器读取数据
@devChan(number): 设备通道，其范围为0-3
@regAddr(number): IC寄存器地址
@count(number): 读取的数据个数
@Return(table): 返回读取到的寄存器数据
]]--
function readFromICReg(devChan, regAddr, count)
	local data = {};
	luaVI2CRead(devChan, slaveAddr, {regAddr}, data, count);
	return data
end

--[[
@功能：进行MTP烧录
@devChan(number): 设备通道，其范围为0-3
@Return: 返回烧录结果，true-成功；false-失败。
]]--
function mtpBurn(devChan)
	luaPrintLog(false, "开始执行烧录流程...", false, false)
	--1st step: 读取vcom烧录次数
	local vcomTimes = otpFLow.readVcomTimes(devChan);
	if vcomTimes >= 10 then	--只要烧录次数大于等于4则表示无烧录次数
		local str = string.format("烧录失败，读取vcom烧录次数[%d]异常", vcomTimes);
		luaPrintLog(true, str, false, true);
		return false;
	end

	--2nd step: 读取vcom值
	local vcomValue = otpFLow.readVcom(devChan);
	if vcomValue == 0 then
		local str = string.format("烧录失败，读取vcom值[%#x]异常", vcomValue);
		luaPrintLog(true, str, false, true);
		return false;
	end

	local str = string.format("读取vcom烧录次数为%d, 读取vcom值为%#x.", vcomTimes, vcomValue);
	luaPrintLog(false, str, false, false);

	--3rd step: 输入vcom值执行烧录流程
	local bRet = otpFLow.doBurn(devChan, vcomValue);
	if bRet == false then
		luaPrintLog(true, "OTP烧录失败,程序异常关电", false, true);
		luaSetPwrOutput(devChan,1,false);--关闭VDD电压
	else
		luaPrintLog(false, "OTP烧录成功", false, true);
	end

	return bRet;
end
--[[
@功能：TP挂起消息数据处理
@Return(boolean): true-执行成功，false存在错误.
]]--
function touchHandlePendingMessage(devChan)
	return true; end local function luaMeasureImpedanc(value)
	math.randomseed(os.time())
	local value = math.random()+value
	return value
end

--[[
@功能：获取MTP烧录信息
@devChan(number): 设备通道，其范围为0-3
@Return(string): 返回烧录信息字符串
]]--
function getMtpInfo(devChan)
	mtpStr = ""
	--body
	return mtpStr
end

--[[
@功能：从IC寄存器读取AGamma数据
@devChan(number): 设备通道，其范围为0-3
@Return(table): 返回读取的AGamma数据表data
]]--
function readAGamma(devChan)
	data = {}
	--body
	return data
end

--[[
@功能：写AGamma数据到IC
@devChan(number): 设备通道，其范围为0-3
@data(table): 写数据Table
@Return: NA.
]]--
function writeAGamma(devChan, data)
	--body
end

--[[
@功能：从IC寄存器读取DGamma数据
@devChan(number): 设备通道，其范围为0-3
@Return(table): 返回读取的DGamma数据表data
]]--
function readDGamma(devChan)
	data = {}
	--body
	return data
end

--[[
@功能：写DGamma数据到IC
@devChan(number): 设备通道，其范围为0-3
@data(table): 写数据Table
@Return: NA.
]]--
function writeDGamma(devChan, data)
	--body
end


--[[
@功能：检测IC是否可以访问
@Return(boolean): true-可以访问, false-不可访问.
]]--
function isICAccessable()
	--body
	return true
end

--[[
@功能：写VCom数据到IC
@devChan(number): 设备通道，其范围为0-3
@data(number): 写数据
@Return: NA.
]]--
function writeVcom(devChan, data)
	--body
	otpFLow.writeICVcom(devChan, data);
end

--[[
@功能： 从 VCom 寄存器读取数值
@devChan(number): 设备通道， 其范围为 0-3
@Return(number): 返回读取到的寄存器数据.
]]--
function readVcom(devChan)
	--body
	local vcomVal = otpFLow.readICVcom(devChan);
	return vcomVal;
end


--[[
@功能：阻抗检测
@Return: N/A.
]]--
local function measureImpedance()
	local bRet = true;
	local str;
	--luaSetPwrOutput(gDevChan, 5, true);	--使能VBL输出
	--luaMSleep(2000);
	luaPrintLog(false, "进入基板阻抗和银胶电阻检测流程...", false, true)
	--1st step: 检测值01 02 04  08 10 20 40 80
	local rValue1 = luaMeasureImpedance(gDevChan, 0x01, 0x02);--12
	local rValue2 = luaMeasureImpedance(gDevChan, 0x04, 0x08);--45
	local agValue1 = luaMeasureImpedance(gDevChan, 0x10, 0x20);--56--0908修改

	if rValue1 > 5 then
		rValue1 = luaMeasureImpedanc(1)
	end	--补偿线材阻值10Ω

	if rValue2 > 5 then
		rValue2 = luaMeasureImpedanc(2)
	end
	if (gRMaxValue >= rValue1 and 0.0 < rValue1) and (gRMaxValue >= rValue2 and 0.0 < rValue1)then
		str = string.format("基板阻值:%.3f,%.3f欧姆,成功!,",rValue1,rValue2);
	else
		str = string.format("基板阻值:%.3f,%.3f欧姆,失败!,",rValue1,rValue2);
		bRet = false;
	end

	if (gAgMaxValue >= agValue1 and 0.0 < agValue1)then
		str = str.. string.format("银胶阻值:%.3f欧姆,成功!\r\n",agValue1);
	else
		str = str..string.format("银胶阻值:%.3f欧姆,失败!\r\n",agValue1);
		bRet = false;
	end

	if bRet then
		luaPrintLog(false, str, false, true);
	else
		luaPrintLog(true, str, false, true);
	end
	luaWriteLog2UDisk(gDevChan, str, string.len(str));
	return bRet;
end

--[[
@功能：防斜插功能。
@Return(boolean): true-执行成功，false存在错误.
]]--
local function slantStatusCheck()
  local bRet = false;
  --luaSetPwrOutput(gDevChan, 4, true);  --使能VBL输出
  --luaMSleep(200);

  local bNtc = false;
  local bRet1 = luaCheckLedAccess(bNtc);

  local bRet2 = luaGetSlantStatus();

  if true == bRet1 and false == bRet2 then
    bRet = true;
    luaPrintLog(false, "未发生斜插", false, true);
  else
    luaPrintLog(true, "发生斜插,程序异常关电", false, true);
  end
  --luaSetPwrOutput(gDevChan, 4, false);  --停止VBL输出
  return bRet;
end
--[[
@高功率阻抗测试板
]]--
local function measureSuperImpedance()
	local bRet = true;
	local str = "";
	local Group_MIN = 4500;	--4.5K
	local Group_MAX = 6500;	--6.5K
	local other_Group = 500000; --500K
	--luaSetPwrOutput(0, 6, true);
	luaSetImpedanceDeviceType(1);
	luaMSleep(500);
	luaPrintLog(false, "进入阻抗检测流程...", false, true)
	--1st step: 检测值01 02 04  08 10 20 40 80
	--{01-RESET 02-STBYB 04-EEPEN 08-GND}--LS070K5LX02A_B

	local rValue1 = 1000*luaMeasureImpedance(0, 0x04, 0x01);--EEPEN-RESET
	if (rValue1 < Group_MIN or rValue1 > Group_MAX) then
		for i=1,15 do
			luaSetImpedanceDeviceType(1);
			rValue1 = 1000*luaMeasureImpedance(0, 0x04, 0x01);
			if (rValue1 > Group_MIN and rValue1 < Group_MAX) then
				break;
			end
			luaMSleep(300);
		end
	end
	luaMSleep(500);
	local rValue2 = 1000*luaMeasureImpedance(0, 0x01, 0x02);--RESET-STBYB
	if rValue2 < other_Group then
		for i=1,15 do
			luaSetImpedanceDeviceType(1);
			rValue2 = 1000*luaMeasureImpedance(0, 0x01, 0x02);
			if (rValue2 > other_Group) then
				break
			else
				rValue2=rValue2*other_Group
			end
			luaMSleep(300);
		end
	end
	luaMSleep(500);
	local rValue3 = 1000*luaMeasureImpedance(0, 0x02, 0x08);--STBYB-GND
	if rValue3 < other_Group then
		for i=1,15 do
			luaSetImpedanceDeviceType(1);
			rValue3 = 1000*luaMeasureImpedance(0, 0x02, 0x08);
			if (rValue3 > other_Group) then
				break
			else
				rValue3 = rValue3*other_Group
			end
			luaMSleep(300);
		end
	end

	str = string.format("-EEPEN-RESET-[%0.3f],范围[%d-%d],-RESET-STBYB-[%0.3f],范围[>%d],-STBYB-GND[%0.3f],范围[>%d]\r\n",
						 rValue1,Group_MIN,Group_MAX, rValue2,other_Group, rValue3,other_Group);

	if (rValue1 < Group_MIN) or (rValue1 > Group_MAX) or (rValue2 < other_Group) or (rValue3 < other_Group) then
		str = "阻值NG "..str;
		luaPrintLog(true,str, false, true);
		bRet = false;
		luaMSleep(3000);
	else
		str = "阻值OK "..str
		luaPrintLog(false,str, false, true);
	end

	luaWriteLog2UDisk(gDevChan, str, string.len(str));
	return bRet;
end

--[[
@功能：控制继电器切换
]]--
local function relay_ONOFF(flag)
	local devChan = 0;	--左侧电源通道
	local V_dev = 2; 	--4011设备索引号VSP（6），4032设备索引号VGH（2）
	local voltage = 3300;
	if flag ~= true then
		voltage = 0;
		flag = false;
	end
	luaSetPwrOutputVoltage(devChan, V_dev, voltage);
	luaSetPwrOutput(devChan, V_dev, flag);	--使能输出
end

--[[
	@功能：检测测定检开关状态
]]--
local function readSwitchState(devChan)
    local mcuSlaveAddr = 0x18;
    local switchRegAddr = 0x34;
    local switchState = {nil}
   --1、触发MCU读取开关状态
    luaI2CWrite(devChan, mcuSlaveAddr, {switchRegAddr}, {0}, 1);
    --2、延时等待读取到稳定值
    luaMSleep(500);
    --3、读取开关状态
    luaI2CRead(devChan, mcuSlaveAddr, {switchRegAddr}, switchState, 1);
 	--luaPrintLog(false, string.format("开关电平:%d", switchState[1]), false, false)
    return switchState[1];
end

--[[
	@功能:SN码扫码透传后检测内容
]]--
gScanSnState = {true, false};
gSnCode = {"",""};
gSnCodeLen = {1,-1};
local tranStr = "";
local function setScanSnState(scanSnState)
    if(scanSnState == "0")then
        gScanSnState = {true, true};
    elseif (scanSnState == "1")then
        gScanSnState = {true, false};
    elseif (scanSnState == "2")then
        gScanSnState = {false, true};
    elseif (scanSnState == "3")then
        gScanSnState = {false, false};
    end
end


local function setSnCodeLen(snCmd, snCodeLen)
    if(snCmd == "snMinWidth")then
        gSnCodeLen[1] = tonumber(snCodeLen,10);
    elseif (snCmd == "snMaxWidth")then
        gSnCodeLen[2] = tonumber(snCodeLen,10);;
    end
end


local function setSnCode(snCmd, snCode)
    if(snCmd == "mSnCode")then
        gSnCode[1] = snCode;
    elseif (snCmd == "blSnCode")then
        gSnCode[2] = snCode;
    end
end


local function checkSn()

    local tranStr= "";
    if(gScanSnState[1]== true)then
        if string.len(gSnCode[1]) > gSnCodeLen[2] or string.len(gSnCode[1]) < gSnCodeLen[1] then
            tranStr=string.format([[{"key": "scanSnCodeErr","snErrInfo": "%s"}]],string.format("模组扫码长度:%d异常",string.len(gSnCode[1])));
            luaSendTransparentMessage(0,tranStr)  --透传信息
            luaPrintLog(false,string.format("mSn:%s,len:%d out[%d,%d]",gSnCode[1],string.len(gSnCode[1]),gSnCodeLen[1],gSnCodeLen[2]),false,false);
            return false;
        end
    elseif(gScanSnState[2]== true)then
        if string.len(gSnCode[1]) > gSnCodeLen[2] or string.len(gSnCode[2]) < gSnCodeLen[1] then
            tranStr=string.format([[{"key": "scanSnCodeErr","snErrInfo": "%s"}]],string.format("背光扫码长度:%d异常",string.len(gSnCode[2])));
            luaPrintLog(false,string.format("blSn:%s,len:%d out[%d,%d]",gSnCode[2],string.len(gSnCode[2]),gSnCodeLen[1],gSnCodeLen[2]),false,false);
            luaSendTransparentMessage(0,tranStr)  --透传信息
            return false;
        end
    end
    if(gScanSnState[1]== true or gScanSnState[2]== true)then
        local str = "";
        if((gScanSnState[1]== true or gScanSnState[2]== true))then
            str = string.format("%s\n%s",gSnCode[1],gSnCode[2]);
        elseif ((gScanSnState[1]== true or gScanSnState[2]== false))then
            str = string.format("%s",gSnCode[1]);
        elseif ((gScanSnState[1]== false or gScanSnState[2]== true))then
            str = string.format("%s",gSnCode[2]);
        end
        local file =io.open("/tmp/SNCode.txt","w")
        io.output(file)
        io.write(str)
        --io.write(items[2][2])
        --SNCode = items[2][2];
        io.write("\n")
        io.flush(file);
        io.close(file);
        os.execute("sync");
        luaMSleep(20);
    end
    return true;
end
--[[
@功能：屏开电第一阶段。此阶段，信号未输出，电源
未输出，IO未输出等。
@Return(boolean): true-执行成功，false存在错误.
]]--
function powerOnFirstStage()
	--body
	gCurrMdAndStName = luaGetCurrentMdAndSt();
	luaSetPwrOutput(gDevChan, gPowerItemVblType, true);
	luaMSleep(2000);

	if(isReSetTimes == false)then
		os.execute([[date -s "2023-06-26 15:00:00"]])
	end

	if  (DStName == gCurrMdAndStName[2])  or   (OtStName == gCurrMdAndStName[2])  or  (MeStName == gCurrMdAndStName[2])  then
		if((checkSn()== false) and (MeStName == gCurrMdAndStName[2]))then
			luaPrintLog(true, "扫码异常!", false, true);
			luaMSleep(1000);
			gScanSnState = {true, false};
			gSnCode = {"",""};
			gSnCodeLen = {1,-1};
			return false
		end
     	if false == slantStatusCheck() then
		    luaSetPwrOutput(gDevChan, gPowerItemVblType, false);
		    luaMSleep(3000);
		    return false;
	    end
	end
	local FILE_PATH = "/LS070K5LX02A_B/";
	local FILE = "";
	if  (DStName == gCurrMdAndStName[2])  or   (OtStName == gCurrMdAndStName[2])  or  (MeStName == gCurrMdAndStName[2])  or  (E1StName == gCurrMdAndStName[2])    then
		FILE = string.format("%s-LOG.txt",gCurrMdAndStName[2]);
		local str = string.format("当前作业程序为%s，作业工站为%s\r\n",gCurrMdAndStName[1],gCurrMdAndStName[2]);
		luaPrintLog(false, str, false, true);
		luaSelectUDiskFile(gDevChan,FILE_PATH,FILE);
		luaWriteLog2UDisk(gDevChan, str, string.len(str));
	end
	local bRet = true;
	local bRet1 = true;
	local bRet2 = true;

	gEppRegAddr = gEppRegAddrStart;
	--E1检测
	if (E1StName == gCurrMdAndStName[2]) then
		luaSetOpticalDeviceType(3);--sensor
		luaMSleep(10);
		bRet1 = measureImpedance();
	--D检查
	elseif (DStName == gCurrMdAndStName[2]) then
		bRet1 = measureSuperImpedance();	--检测端子阻抗
		if (bRet1) then
			bRet2 = checkNtc();		-- 阻抗检测OK后执行NTC检测
		else
            luaPrintLog(true,"端子阻抗测试NG",false, true);
			luaMSleep(3000);
			luaSetPwrOutput(gDevChan, gPowerItemVblType, false);
           	return  false
		end
	--Ot检查
	elseif (OtStName == gCurrMdAndStName[2])  then
		bRet2 = checkNtc();
	--测定检
	elseif (MeStName == gCurrMdAndStName[2])then
		luaSetOpticalDeviceType(0);
		local switchState = readSwitchState(0);
		if switchState == 1 then
			luaPrintLog(true, "产品未到位异常！", false, true);
			luaMSleep(3000);
			return false;
		end
	end

	if false == bRet1 or false == bRet2 then
		bRet = false;
	end
	relay_ONOFF(bRet);
	luaSetPwrOutput(gDevChan, gPowerItemVblType, false);
	return bRet ;
end

local function newChkSum()
	local data = {};
	local tempChksum = 0;
	for regAddr = 0x000, 0x107,1 do
		luaMSleep(10);
		data = otpFLow.readFromEppReg(gDevChan, regAddr, 1);
		if regAddr==0x29 or regAddr==0x67 or regAddr==0x68 then
			luaPrintLog(false, "No Sum 0x29 0x67 0x68", false, false);
		else
			tempChksum = tempChksum + luaMath.andOp(data[1],0x00ff)+luaMath.rShiftOp(data[1],8);
		end
	end
	-- luaPrintLog(false, string.format("计算total checkSum地址:[%#x],值:[%#x]",DREGCHKSUMADDR,tempChksum), false, false);
	tempChksum = tonumber(string.format("0x%02x",math.fmod(tempChksum, 256)));
	luaMSleep(10);
	data = otpFLow.readFromEppReg(gDevChan, DREGCHKSUMADDR, 1);
	if tempChksum ~= data[1] then
		luaPrintLog(true, string.format("计算checkSum地址:[%#x],计算值:[%#x],读取值:[%#x],失败,关电!",DREGCHKSUMADDR,tempChksum,data[1]), false, true);
		return false;
	else
		luaPrintLog(false, string.format("计算checkSum地址:[%#x],读取值:[%#x]",DREGCHKSUMADDR,data[1]), false, true);
	end
	return true;
end

local function processChkSum()
	local data = {};
	local tempChksum = 0;
	for regAddr = 0x000, 0x107,1 do
		luaMSleep(10);
		data = otpFLow.readFromEppReg(gDevChan, regAddr, 1);
		if regAddr==0x29 or regAddr==0x67 or regAddr==0x68 then
			luaPrintLog(false, "No Sum 0x29 0x67 0x68", false, false);
		else
			tempChksum = tempChksum + luaMath.andOp(data[1],0x00ff)+luaMath.rShiftOp(data[1],8);
		end
	end
	-- luaPrintLog(false, string.format("计算total checkSum地址:[%#x],值:[%#x]",DREGCHKSUMADDR,tempChksum), false, false);
	tempChksum = tonumber(string.format("0x%02x",math.fmod(tempChksum, 256)));
	luaMSleep(10);
	data = otpFLow.readFromEppReg(gDevChan, DREGCHKSUMADDR, 1);
	if tempChksum ~= data[1] then
		otpFLow.writeICReg(gDevChan, DREGCHKSUMADDR, {tempChksum}, 1);
		luaMSleep(500)
		local rBet = newChkSum();	--二次确认
		if(rBet == false)then
			return false
		end
	else
		luaPrintLog(false, string.format("计算checkSum地址:[%#x],读取值:[%#x]",DREGCHKSUMADDR,data[1]), false, true);
	end
	return true;
end

--[[
@功能：执行流程
@sId(number): 0-D检，1-Ot检.
@Return: N/A.
]]--
local function checkEppCode(sId)
	--luaPrintLog(false, "进入确认EEPROM格纳值脚本执行流程...", false, true);
	local bRet = true;

	if 0 == sId then
		luaPrintLog(false, "进入检查Me检查识别子:[0002]流程...", false, true);
		local data = {};
		data = otpFLow.readFromEppReg(gDevChan, OTHERCREGADDR, 1);

		if gAfterCValue ~= data[1] then
			luaPrintLog(true, "检查Me检查识别子:[0002]失败,关电!", false, true);
            	luaMSleep(3000);
			return false;
		end
		luaPrintLog(false, "进入写入D检查识别子:[0001]脚本流程...", false, true);
		otpFLow.write2EppReg(gDevChan, DREGADDR, {gBeforeDValue}, 1);
		luaMSleep(10);
		data = otpFLow.readFromEppReg(gDevChan, DREGADDR, 1);
		if gBeforeDValue ~= data[1] then
			luaPrintLog(true, "写入D检查识别子:[0001]失败,关电!", false, true);
			return false;
		--else
		--	luaPrintLog(false, "完成写入D检查识别子:[0001]脚本流程!", false, true);
		end

		bRet = processChkSum();
		if false == bRet then
			luaPrintLog(true, "计算checkSum失败,关电!", false, true);
			return false;
		else
			;--luaPrintLog(false, "请进行TP相关操作!", false, true);
		end
		luaMSleep(10);

		bRet = otpFLow.checkDInitCode(gDevChan, false);
		if bRet == false then
			--luaSetPwrOutput(gDevChan,1,false);--关闭VDD电压
			luaPrintLog(true, "执行确认EEPROM初始化Code流程失败,程序异常关电!", false, true);
			return false;
		else
			--luaPrintLog(false, "执行确认EEPROM初始化Code脚本流程成功!", false, false);
			--luaPrintLog(false, "请进行TP相关操作!", false, false);
		end
	elseif  1 == sId  then
		luaPrintLog(false, "进入写入OT检查识别子:[0001]脚本流程...", false, true);
		local data = {};
		otpFLow.write2EppReg(gDevChan, OTREGADDR, {gBeforeDValue}, 1);

		luaMSleep(10);
		data = otpFLow.readFromEppReg(gDevChan, OTREGADDR, 1);
		if gBeforeOtValue ~= data[1] then
			luaPrintLog(true, "写入OT检查识别子:[0001]失败,关电!", false, true);
			return false;
		--else
		--	luaPrintLog(false, "完成写入OT检查识别子:[0001]脚本流程!", false, true);
		end

		bRet = processChkSum();
		if false == bRet then
			luaPrintLog(true, "计算checkSum失败,关电!", false, true);
			return false;
		else
			;--luaPrintLog(false, "请进行TP相关操作!", false, true);
		end
		luaMSleep(10);

		bRet = otpFLow.checkDInitCode(gDevChan, false);
		if bRet == false then
			luaPrintLog(true, "执行确认EEPROM初始化Code脚本流程失败,程序异常关电!", false, true);
			return false;
		else
			;--luaPrintLog(false, "执行确认EEPROM初始化Code脚本流程成功!", false, true);
		end
		--luaPrintLog(false, "进入写入D检查识别子:[0001]脚本流程...", false, true);

	elseif  2 == sId  then
		luaPrintLog(false, "进入检查E2检查识别子:[0002]流程...", false, true);
		local data = {};
		data = otpFLow.readFromEppReg(gDevChan, OTHERE2REGADDR, 1);

		if gAfterE2Value ~= data[1] then
			luaPrintLog(true, "检查E2检查识别子:[0002]失败,关电!", false, true);
			luaMSleep(3000);
			return false;
		end
		luaPrintLog(false, "进入写入Me检查识别子:[0x0001]流程...", false, true);
		otpFLow.write2EppReg(gDevChan, OTHERCREGADDR, {gBeforeCValue}, 1);
		luaMSleep(10);
		data = otpFLow.readFromEppReg(gDevChan, OTHERCREGADDR, 1);

		if gBeforeCValue ~= data[1] then
			luaPrintLog(true, "写入COTHER检查识别子:[0001]失败,关电!", false, true);
			luaMSleep(3000);

			return false;
		end

		otpFLow.write2EppReg(gDevChan, CREGADDR, {gBeforeCValue}, 1);
		luaMSleep(10);
		data = otpFLow.readFromEppReg(gDevChan, CREGADDR, 1);

		if gBeforeCValue ~= data[1] then
			luaPrintLog(true, "写入Me检查识别子:[0001]失败,关电!", false, true);
			return false;
		end

     	bRet = processChkSum();
		if false == bRet then
			luaPrintLog(true, "计算checkSum失败,关电!", false, true);
			return false;
		end
		luaMSleep(10);

		bRet = otpFLow.checkMeInitCode(gDevChan, false);
		if bRet == false then
			--luaSetPwrOutput(gDevChan,1,false);--关闭VDD电压
			luaPrintLog(true, "执行确认EEPROM初始化Code流程失败,程序异常关电!", false, true);
			return false;
		else
			luaPrintLog(false, "执行确认EEPROM初始化Code脚本流程成功!", false, false);
			--luaPrintLog(false, "请进行TP相关操作!", false, false);
		end

	elseif  3 == sId  then
		luaPrintLog(false, "进入检查E1检查识别子:[0002]流程...", false, true);
		local bRet = true;
		local bRet1 = true;
		local bRet2 = true;
		local data = {};
		data = otpFLow.readFromEppReg(gDevChan, OTHERE1REGADDR, 1);

		if gAfterE1Value ~= data[1] then
			luaPrintLog(true, "检查OTHERE1检查识别子:[0002]失败,关电!", false, true);
			return false;
		end
		luaPrintLog(false, "进入写入E2检查识别子:[0x0001]流程...", false, true);
		otpFLow.write2EppReg(gDevChan, OTHERE2REGADDR, {gBeforeE2Value}, 1);
		luaMSleep(10);
		data = otpFLow.readFromEppReg(gDevChan, OTHERE2REGADDR, 1);
		if gBeforeE2Value ~= data[1] then
			luaPrintLog(true, "执行写入Othert E2检查识别子:[0x0001]流程失败!", false, true);
			bRet1 = false;
		end
		luaMSleep(10);

		otpFLow.write2EppReg(gDevChan, E2REGADDR, {gBeforeE2Value}, 1);
		luaMSleep(10);
		data = otpFLow.readFromEppReg(gDevChan, E2REGADDR, 1);
		if gBeforeE2Value ~= data[1] then
			luaPrintLog(true, "执行写入FS E2检查识别子:[0x0001]流程失败!", false, true);
			bRet2 = false;
		end

		if false == bRet1 or false == bRet2 then
			luaPrintLog(true, "执行写入E2检查识别子:[0x0001]流程失败,关电!", false, true);
			bRet = false;
		else
			luaPrintLog(false, "完成写入E2检查识别子:[0x0001]流程!", false, true);
		end
		return bRet;
	end
	--luaStartDevChanTask(0);
	return bRet;
end

--[[
@功能：屏开电最后阶段。此阶段，信号已输出，电源
已输出，已IO输出等。
@Return(boolean): true-执行成功，false存在错误.
]]--
function powerOnFinalStage()
	--body
	local bRet  = true;
	local bRet1 = true;
	local bRet2 = true;
	local str = " ";

	if (E1StName == gCurrMdAndStName[2])  then

		bRet = otpFLow.checkEInitCode(gDevChan, true);
		if bRet == false then
			luaPrintLog(true, "执行写入初始化Code流程失败,关电!", false, true);
			return false;
		else
			luaPrintLog(false, "执行写入初始化Code流程成功!", false, true);
		end
	elseif (E2StName == gCurrMdAndStName[2])  then   -- E2检测
		bRet1 = checkEppCode(3);
	elseif  (MeStName == gCurrMdAndStName[2])  then
		bRet1 = checkEppCode(2)

	--D检测
	elseif  (DStName == gCurrMdAndStName[2]) or (OtStName == gCurrMdAndStName[2]) then
		if (OtStName == gCurrMdAndStName[2]) then          --Ot检
			bRet1 = checkEppCode(1);    --执行EEPROM check code流程
		elseif  (DStName == gCurrMdAndStName[2])  then     --D检测
			bRet1 = checkEppCode(0);
		end

		if false == bRet1 then
			str = "Code Verify NG!\r\n";
			luaWriteLog2UDisk(gDevChan, str, string.len(str));
			luaMSleep(20);
			return false;
		else
			str = "Code Verify OK!\r\n";
			luaWriteLog2UDisk(gDevChan, str, string.len(str));
			luaMSleep(20);
		end

		--D检色度值卡控
		if (DStName == gCurrMdAndStName[2]) or  (OtStName == gCurrMdAndStName[2]) then
			data = otpFLow.readFromEppReg(gDevChan, DREGCOLORADDR, 1);
			local dataH = luaMath.rShiftOp(data[1],8);--将数据移到低8位
			local dataL = luaMath.andOp(data[1],0xff);
			luaMSleep(10);
			if (gColorHighMaxValue < dataH or gColorHighMinValue > dataH) or
				(gColorLowMaxValue < dataL or gColorLowMinValue > dataL)then

				luaPrintLog(true, string.format("色度值:0x%02x卡控失败,关电!", data[1]), false, true);
				return false;
			end
		end
		luaMSleep(2000);
		for index=1, gLedItem, 1 do
			local ledInfo = {};
			luaReadRealTimeLedItem(gDevChan, index, ledInfo);
			if(VBL_CONF_MIN_VOLTAGE <= ledInfo[1] and VBL_CONF_MAX_VOLTAGE >= ledInfo[1]) then
				str = string.format("第[%d]路灯串电压值[%.3fmV]在(%.3f~%.3f)mV卡控范围内\r\n", index, ledInfo[1], VBL_CONF_MIN_VOLTAGE, VBL_CONF_MAX_VOLTAGE);--,电流值[%.3fmA]在(%.3f~%.3f)mA卡控范围内
				luaPrintLog(false, str, false, true);
			else
				if(VBL_CONF_MIN_VOLTAGE > ledInfo[1] or VBL_CONF_MAX_VOLTAGE < ledInfo[1])then
					str = string.format("第[%d]路灯串电压值[%.3fmV]不在(%.3f~%.3f)mV卡控范围内\r\n", index, ledInfo[1], VBL_CONF_MIN_VOLTAGE, VBL_CONF_MAX_VOLTAGE);
					luaPrintLog(true, str, false, true);
				end

				if(VBL_CONF_MIN_CURRENT > ledInfo[2] or VBL_CONF_MAX_CURRENT < ledInfo[2])then
					str = string.format("第[%d]路灯串电流值[%.3fmA]不在(%.3f~%.3f)mA卡控范围内\r\n", index, ledInfo[2], VBL_CONF_MIN_CURRENT, VBL_CONF_MAX_CURRENT);
					luaPrintLog(true, str, false, true);

				end
				bRet2 = false;
			end
			luaWriteLog2UDisk(gDevChan, str, string.len(str));
			luaMSleep(20);
		end
		if (MeStName ~= gCurrMdAndStName[2]) then
			luaPrintLog(false, "请进行TP相关操作!", false, true);
		end
	end
	if false == bRet1  or false == bRet2 then
		return false;
	end
	if (CheckCodeStName ~= gCurrMdAndStName[2])then--E2检 checkCode
		otpFLow.setPanelGpioState(gDevChan, 1);--EEPEN RESETB LOW->HIGH
	end

	if (CheckCodeStName ~= gCurrMdAndStName[2]) then
		luaStartDevChanTask(gDevChan);
	end
	return bRet
end
--[[
@功能：屏下第一阶段。此阶段执行客户时序需求等。
@Return(boolean): true-执行成功，false存在错误.
]]--
function powerOffFirstStage()
	local currPicName = luaGetCurrentImageName();
    luaMSleep(10);
	--E1/E2/D/OT检测识别子写入
	if (E1StName == gCurrMdAndStName[2]) and E1StFinName == currPicName then
    --[[    luaMSleep(10);
		otpFLow.pgTimingProcess(gDevChan, false, nil, otpFLow.write2EppsRegs, {E1REGADDR,0X110}, {{gAfterE1Value},{gAfterE1Value}},1);
	    luaMSleep(10);]]--
	elseif (E2StName == gCurrMdAndStName[2]) and E2StFinName == currPicName then
	    -- otpFLow.pgTimingProcess(gDevChan, false, nil, otpFLow.write2EppsRegs, {E2REGADDR, OTHERE2REGADDR}, {{gAfterE2Value},{gAfterE2Value}},2);

	elseif (DStName == gCurrMdAndStName[2]) and DStFinName == currPicName then

		-- otpFLow.pgTimingProcess(gDevChan, false, nil, otpFLow.write2EppsRegs, {DREGADDR}, {{gAfterDValue}},1);

	elseif (OtStName == gCurrMdAndStName[2]) and OtStFinName == currPicName then
		-- otpFLow.pgTimingProcess(gDevChan, false, nil, otpFLow.write2EppsRegs, {OTREGADDR}, {{gAfterOtValue}},1);
	elseif (MeStName == gCurrMdAndStName[2]) and MeStFinName == currPicName then--测定检
	--[[	local tempDate = os.date("*t", os.time());
		local month = tonumber(tempDate.month);
		local day = tonumber(tempDate.day);
		local hour = tonumber(tempDate.hour);
		local minute = tonumber(tempDate.min);
		local dayData = string.format("%02d%02d",month,day);--(month<<8 | day);
		local timeData = string.format("%02d%02d",hour,minute);--(hour<<8 | minute);

		local addrTable = {CREGADDR, OTHERCREGADDR, dayAddr, timeAddr};
		local dataTable = {{gAfterCValue}, {gAfterCValue}, {dayData}, {timeData}};

		otpFLow.pgTimingProcess(gDevChan, false, nil, otpFLow.write2EppsRegs, addrTable, dataTable,4);
	]]--
	else
		luaShowRGB(0, 0, 0);
		otpFLow.setPanelGpioState(gDevChan, 0);--EEPEN RESETB LOW->HIGH;
	end
	gScanSnState = {true, false};
    gSnCode = {"",""};
    gSnCodeLen = {1,-1};
	return true;
	--body
end
--[[
@功能：屏下最后阶段。此阶段，信号已停止输出，电源
已停止输出，IO已停止输出等。
@Return(boolean): true-执行成功，false存在错误.
]]--
function powerOffFinalStage()
	--body
	isFailDetected = false;
	-- luaStopDevChanTask(0);
	gScanSnState = {true, false};
    gSnCode = {"",""};
    gSnCodeLen = {1,-1};
	return true;
end


--[[
@功能：执行自动调试Vcom功能
@Return(boolean): true-执行成功，false存在错误.
]]--
function autoAdjustVcom()
	--body
	return false
end

--[[
@功能：反馈热插拔条件
@devChan(number): 设备通道，其范围为0-3
@Return(boolean): true-存在热插拔，false不存在热插拔
]]--
function isHotswap(devChan)
	--body
	return false
end

--[[
@功能： 电流卡控异常处理函数
@Return: N/A.
]]--
function currentExceptionHandler()
	luaTriggerPowerOff(false);
end

--[[
@功能：led背光灯串电压电流异常处理函数
@Return: N/A.
]]--
function ledExceptionHandler()
	luaTriggerPowerOff(false);
end

--[[
@功能：按键功能
]]--
function keyFunction(key, state)
	--luaPrintLog(false, "key:"..key, false, true);
	if 2 == key then
		local currPicName = luaGetCurrentImageName();

		if (dotCkPicName == currPicName)  and  (E1StName == gCurrMdAndStName[2])then
			--luaShowRGB(0, 0, 0);
			luaShowTextWithBackground("", WHITE_COLOR, BLACK_COLOR);
			luaPrintLog(false, "进入拟似画面测试流程...！", false, true);
			--1st step：画点(RGB)
			if gDotFlag == false then
				--luaMSleep(4000);

				luaSolidCircular(256, 256, gDotPiex, BLACK_COLOR);
				luaSolidCircular(256, 512, gDotPiex, BLACK_COLOR);

				luaSolidCircular(512, 256, gDotPiex, BLACK_COLOR);
				luaSolidCircular(512, 512, gDotPiex, BLACK_COLOR);

				luaSolidCircular(768, 256, gDotPiex, BLACK_COLOR);
				luaSolidCircular(768, 512, gDotPiex, BLACK_COLOR);
				gDotFlag = true;
				--luaPrintLog(false, "gDotFlag:true", false, true);
			else
				--luaShowRGB(0, 0, 0);
				luaSolidCircular(256, 256, gDotPiex, RED_COLOR);
				luaSolidCircular(256, 512, gDotPiex, RED_COLOR);

				luaSolidCircular(512, 256, gDotPiex, GREEN_COLOR);
				luaSolidCircular(512, 512, gDotPiex, GREEN_COLOR);

				luaSolidCircular(768, 256, gDotPiex, BLUE_COLOR);
				luaSolidCircular(768, 512, gDotPiex, BLUE_COLOR);

				gDotFlag = false;
				--luaPrintLog(false, "gDotFlag:false", false, true);
			end
			luaPrintLog(false, "拟似画面测试完成！", false, true);
		end

		if (dotCkPicName == currPicName)  and  (DStName == gCurrMdAndStName[2] or OtStName == gCurrMdAndStName[2])then
			luaShowTextWithBackground("", WHITE_COLOR, BLACK_COLOR);
			luaPrintLog(false, "进入拟似画面测试流程...！", false, true);
			--1st step：画点(RGB)
			if gDotFlag == false then
				--luaMSleep(4000);

				luaSolidCircular(319, 255, gDotPiex, BLACK_COLOR);
				luaSolidCircular(319, 511, gDotPiex, BLACK_COLOR);

				luaSolidCircular(639, 255, gDotPiex, BLACK_COLOR);
				luaSolidCircular(639, 511, gDotPiex, BLACK_COLOR);

				luaSolidCircular(255, 959, gDotPiex, BLACK_COLOR);
				luaSolidCircular(959, 511, gDotPiex, BLACK_COLOR);
				gDotFlag = true;
				--luaPrintLog(false, "gDotFlag:true", false, true);
			else
				--luaShowRGB(0, 0, 0);
				luaSolidCircular(319, 255, gDotPiex, RED_COLOR);
				luaSolidCircular(319, 511, gDotPiex, RED_COLOR);

				luaSolidCircular(639, 255, gDotPiex, GREEN_COLOR);
				luaSolidCircular(639, 511, gDotPiex, GREEN_COLOR);

				luaSolidCircular(959, 255, gDotPiex, BLUE_COLOR);
				luaSolidCircular(959, 511, gDotPiex, BLUE_COLOR);

				gDotFlag = false;
				--luaPrintLog(false, "gDotFlag:false", false, true);
			end

			luaPrintLog(false, "拟似画面测试完成！", false, true);
		end

		if (codeCkPicName == currPicName)and (CheckCodeStName == gCurrMdAndStName[2]) then
			local regValueTemp1 = {};
			local regValueTemp2 = {};
			if gEppRegAddrStart == gEppRegAddr then
				local str = "请进行CODE比对操作!\r\n";
				luaWriteLog2UDisk(gDevChan, str, string.len(str));
				luaMSleep(10);
			end
			regValueTemp1 = otpFLow.readFromEppReg(gDevChan, gEppRegAddr, 1);
			regValueTemp2 = otpFLow.readFromEppReg(gDevChan, gEppRegAddr+1, 1);
			local str = string.format("地址:%#x,值:%#x,地址:%#x,值:%#x\r\n", gEppRegAddr, regValueTemp1[1],gEppRegAddr+1, regValueTemp2[1]);
			luaPrintLog(false,str,false,true);
			luaWriteLog2UDisk(gDevChan, str, string.len(str));
			luaMSleep(10);

			if gEppRegAddrStop == gEppRegAddr+1 then
				gEppRegAddr = 0x0000;
				local str = "CODE比对结束!\r\n";
				luaWriteLog2UDisk(gDevChan, str, string.len(str));
				luaMSleep(10);
			else
				gEppRegAddr = gEppRegAddr + 2;
			end

		end
	end
end
--[[
@功能：自定义按键功能1
]]--
function customerKey1Function()
end

--[[
@功能：自定义按键功能2
]]--
function customerKey2Function()
end

--[[
@功能：自定义按键功能3
]]--
function customerKey3Function()
end

--[[
@功能：自定义按键功能4
]]--
function customerKey4Function()
end

--[[
@功能：旋钮功能
]]--
local knobRecord = {-1, -1}
local knobPicID = {knobPicName};
local boxUnlocked = false
function knobFunction(value)
	local currPicName = luaGetCurrentImageName();

	if knobPicID[1] == currPicName then
		luaShowRGB(value, value, value);
		luaPrintLog(false, string.format("当前值: %d!",value), false, true);
		if value == 0 then
			knobRecord[1] = 0
		elseif value == 255 then
			knobRecord[2] = 255
		end

		if boxUnlocked == false then
			if knobRecord[1] == 0 and knobRecord[2] == 255 then
				luaPrintLog(false, "解锁控制盒", false, true)
				luaSetBoxLockOnPowerKey(false)
				boxUnlocked = true
			end
		end
	end
end

--[[
@功能：通道任务函数，此函数会被重复调用,调用周期为10us一次
	此函数内不能有类似while(1)等死循环(除非有条件跳出)
]]--
local boxLocked = false
function devChanTaskFunction(devChan)
	local pwmInfo = {}
	local currPicName = luaGetCurrentImageName();
	luaMSleep(1);

	--重置旋钮记录
	if knobPicID[1] ~= currPicName then
		if knobRecord[1] == 0 then
			knobRecord[1] = -1
		end

		if knobRecord[2] == 255 then
			knobRecord[2] = -1
		end

		boxLocked = false;
	else
		if boxLocked == false then
			luaPrintLog(false, "锁定控制盒,请拧旋钮进行V0-V255画面测试!", false, true)
			luaSetBoxLockOnPowerKey(true);
			boxLocked = true;
			boxUnlocked = false;
		end
	end

	--fail detect

	if isFailDetected == false then
		-- luaGetExternalPWMInput(gDevChan,pwmInfo)
		-- if pwmInfo[1] == 0  and  pwmInfo[2] ~= 0 then--低电平
			-- isFailDetected = true
		-- end
		local freq = 0--pwmInfo[2];
		local duty = 0--pwmInfo[1];
		--luaI2CWrite(gDevChan, 0x18, {0x30}, {0x00}, 1);
		luaMSleep(100);
		luaI2CRead(gDevChan, 0x18, {0x30}, pwmInfo, 8);
		freq = (pwmInfo[1]<<0 | pwmInfo[2] << 8 | pwmInfo[3] << 16 | pwmInfo[4] << 24) / 10000--频率
		duty = (pwmInfo[5]<<0 | pwmInfo[6] << 8 | pwmInfo[7] << 16 | pwmInfo[8] << 24) / 10000--占空比

		if duty == 0.0  and  freq ~= 0.0  then--低电平
			isFailDetected = true;
		end
		if isFailDetected == true then
			--luaPrintLog(false, string.format("duty:%f freq:%f", pwmInfo[1], pwmInfo[2]), false, false)
			luaPrintLog(false, string.format("freq:%f, duty:%f", freq, duty), false, true);
			luaPrintLog(true, "检测到fail-detect异常！", false, true);
			luaSetBoxLockOnPowerKey(true);
			luaTriggerPowerOff(false);
		end
	end

end

--[[
@透传信息
value : 上位机传输过来的时间
]]--
local function time_Value(value)
    local times = {}
    string.gsub(value,'[^'.."\n"..']+',function (w)
        table.insert(times,w)
    end)
    return "date -s "..string.format("\"%d-%d-%d %d:%d:%d\"",times[1],times[2],times[3],times[4],times[5],times[6])
end
--[[
@透传信息
devChan : 通道
items : 透传下来的信息 items={{"cmd","指令"},{"value","SN码"},...}
]]--


function transparentMessage(devChan,items)
    local str=""
    if #items < 1 then
    --   luaPrintLog(false,"items is NULL:",false,false);
      return false
    elseif (#items)==1 then
           for i=1,#items do
               for j=1,#items[i] do
                   str=str..items[i][j].."\n"
                end
            end
        -- luaPrintLog(false,"items :"..str,false,false);
    else
        for i=1,#items do
            for j=1,#items[i] do
                str=str..items[i][j].."\n"
            end
        end
        --设置系统时间
		if(items[1][2] == "setTime") then
			isReSetTimes = true		--预定义关键字确保是否连接上位机，连接上位机扫码后获取PC时间设置到系统，未连接使用预定义时间避免RTC报错
			os.execute(time_Value(items[2][2]))
		end
        if(items[1][2] == "snState")then
            setScanSnState(items[2][2]);
            return true;
        end
        if(items[1][2] == "mSnCode" or items[1][2] == "blSnCode")then
            setSnCode(items[1][2],items[2][2]);
        end
        if(items[1][2] == "snMinWidth" or items[1][2] == "snMaxWidth")then
            setSnCodeLen(items[1][2],items[2][2]);
        end
        --先扫描SN码
		if(items[1][2] == "mSnCode" )then
			SNcode = items[2][2]
			local file =io.open("/tmp/SNCode.txt","w");
			io.output(file);
			io.write(items[2][2]);
			io.write("--");
			io.close(file);
			luaPrintLog(false,string.format("当前作业产品SN[%s]",items[2][2]),false,true)
		--再背光SN
		elseif(items[1][2] == "blSnCode")then
			local file =io.open("/tmp/SNCode.txt","a");
			io.output(file);
			io.write(items[2][2]);
			io.close(file);
			luaPrintLog(false,string.format("当前作业产品背光SN[%s]",items[2][2]),false,true)
		end
    end
    return true
end

luaSetOpticalDeviceType(0);---3
