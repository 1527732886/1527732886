package.path = package.path .. ";./cfg/script/?.lua"
local luaMath = require("luaMath")	--加载扩展lua数学库

--注意进制转换
local tftInitialECode = {
0x7210,0xB1F9,0x04CC,0x1070,0x0706,0x86B0,0x8008,0x0060,
0x0053,0x00A5,0x4000,0x007F,0x0023,0x2B32,0x7200,0x7840,
0x0204,0x0000,0x0000,0x0915,0x0915,0x0915,0x0010,0x0000,
0x0000,0x0000,0x0000,0x0000,0x0000,0x007A,0x8F4F,0x4E28,
0xAFAF,0x1030,0x1040,0x4040,0xFC48,0x11FF,0xB715,0x111F,
0x4800,0xD300,0x0006,0x090A,0x0610,0x1720,0x292C,0x2E22,
0x1B22,0x2D22,0x1C29,0x2C1C,0x0006,0x090A,0x0610,0x1720,
0x292C,0x2E22,0x1B22,0x2D22,0x1C29,0x2C1C,0x0006,0x090A,
0x0610,0x1720,0x292C,0x2E22,0x1B22,0x2D22,0x1C29,0x2C1C,
0x0006,0x090B,0x0711,0x1922,0x2D30,0x3228,0x2227,0x2F23,
0x1B27,0x2A1A,0x0006,0x090B,0x0711,0x1922,0x2D30,0x3228,
0x2227,0x2F23,0x1B27,0x2A1A,0x0006,0x090B,0x0711,0x1922,
0x2D30,0x3228,0x2227,0x2F23,0x1B27,0x2A1A,0x1010,0x1080,
0x6E70,0x34FF,0x005F,0x000A,0x0000,0x0A00,0x0004,0x0C1C,--0x6569
0x2C3C,0x5C7C,0xBCFC,0x7CFC,0x0080,0x0040,0x80A0,0xC0D0,
0xE0F0,0xF8FC,0x0000,0x05AF,0xFFFF,0x0004,0x0C1C,0x2C3C,
0x5C7C,0xBCFC,0x7CFC,0x0080,0x0040,0x80A0,0xC0D0,0xE0F0,
0xF8FC,0x0000,0x05AF,0xFFFF,0x0004,0x0C1C,0x2C3C,0x5C7C,
0xBCFC,0x7CFC,0x0080,0x0040,0x80A0,0xC0D0,0xE0F0,0xF8FC,
0x0000,0x05AF,0xFFFF,0x1055,0x23FF,0xAAAA,0xAAAA,0xAA00,
0x0000,0x0000,0x0000,0x0000,0x0023,0xAAAA,0xAAAA,0xAA00,
0x0000,0x0000,0x0000,0x0000,0x0003,0x5C5C,0x0E06,0x0E06,
0x5A1A,0x111A,0x1A11,0x003F,0x3C00,0xFF10,0x0020,0x4060,
0x80A0,0xC0E0,0x1078,0xC000,0x0000,0x0000,0x7323,0x0F8C,
0x0000,0x0000,0x0032,0x3232,0x0102,0x0100,0x0101,0x0006,
0x4354,0x0201,0x0282,0x0000,0x0000,0x0000,0x000A,0x0000,
0x0082,0x0020,0x0000,0x0000,0x0400,0x2053,0x5327,0x3600,
0x1000,0xC028,0x252B,0x0309,0x0C0B,0x0A00,0x0000,0x0000,
0x0000,0x0000,0x0000,0x0000,0x0102,0x0304,0x0528,0x252B,
0x0309,0x0C0B,0x0A00,0x0000,0x0000,0x0000,0x0000,0x0000,
0x0000,0x0102,0x0304,0x0528,0x2500,0x030A,0x0B0C,0x0900,
0x0000,0x0000,0x0000,0x0000,0x0000,0x0028,0x2500,0x030A,
0x0B0C,0x0900,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,--0x107
0x0000,0x0000,0x0000,0x0000,0x0051,0x0000,0x0000,0x0000,--0x0041
0x0001,0x0000,0x0000,0x0000,0xffff,0xffff,0xffff,0xffff,--0x110~0x117
0xffff,0xffff,0xffff,0xffff,0xffff,0xffff,--0x0000,0x0000,--0x118-0x11F FS FLAG
};

local tftInitialMeCode = {
	0x7210,0xB1F9,0x04CC,0x1070,0x0706,0x86B0,0x8008,0x0060,
	0x0053,0x00A5,0x4000,0x007F,0x0023,0x2B32,0x7200,0x7840,
	0x0204,0x0000,0x0000,0x0915,0x0915,0x0915,0x0010,0x0000,
	0x0000,0x0000,0x0000,0x0000,0x0000,0x007A,0x8F4F,0x4E28,
	0xAFAF,0x1030,0x1040,0x4040,0xFC48,0x11FF,0xB715,0x111F,
	0x4800,0xD300,0x0006,0x090A,0x0610,0x1720,0x292C,0x2E22,
	0x1B22,0x2D22,0x1C29,0x2C1C,0x0006,0x090A,0x0610,0x1720,
	0x292C,0x2E22,0x1B22,0x2D22,0x1C29,0x2C1C,0x0006,0x090A,
	0x0610,0x1720,0x292C,0x2E22,0x1B22,0x2D22,0x1C29,0x2C1C,
	0x0006,0x090B,0x0711,0x1922,0x2D30,0x3228,0x2227,0x2F23,
	0x1B27,0x2A1A,0x0006,0x090B,0x0711,0x1922,0x2D30,0x3228,
	0x2227,0x2F23,0x1B27,0x2A1A,0x0006,0x090B,0x0711,0x1922,
	0x2D30,0x3228,0x2227,0x2F23,0x1B27,0x2A1A,0x1010,0x1080,
	0x6E70,0x34FF,0x005F,0x000A,0x0000,0x0A00,0x0004,0x0C1C,--0x6569
	0x2C3C,0x5C7C,0xBCFC,0x7CFC,0x0080,0x0040,0x80A0,0xC0D0,
	0xE0F0,0xF8FC,0x0000,0x05AF,0xFFFF,0x0004,0x0C1C,0x2C3C,
	0x5C7C,0xBCFC,0x7CFC,0x0080,0x0040,0x80A0,0xC0D0,0xE0F0,
	0xF8FC,0x0000,0x05AF,0xFFFF,0x0004,0x0C1C,0x2C3C,0x5C7C,
	0xBCFC,0x7CFC,0x0080,0x0040,0x80A0,0xC0D0,0xE0F0,0xF8FC,
	0x0000,0x05AF,0xFFFF,0x1055,0x23FF,0xAAAA,0xAAAA,0xAA00,
	0x0000,0x0000,0x0000,0x0000,0x0023,0xAAAA,0xAAAA,0xAA00,
	0x0000,0x0000,0x0000,0x0000,0x0003,0x5C5C,0x0E06,0x0E06,
	0x5A1A,0x111A,0x1A11,0x003F,0x3C00,0xFF10,0x0020,0x4060,
	0x80A0,0xC0E0,0x1078,0xC000,0x0000,0x0000,0x7323,0x0F8C,
	0x0000,0x0000,0x0032,0x3232,0x0102,0x0100,0x0101,0x0006,
	0x4354,0x0201,0x0282,0x0000,0x0000,0x0000,0x000A,0x0000,
	0x0082,0x0020,0x0000,0x0000,0x0400,0x2053,0x5327,0x3600,
	0x1000,0xC028,0x252B,0x0309,0x0C0B,0x0A00,0x0000,0x0000,
	0x0000,0x0000,0x0000,0x0000,0x0102,0x0304,0x0528,0x252B,
	0x0309,0x0C0B,0x0A00,0x0000,0x0000,0x0000,0x0000,0x0000,
	0x0000,0x0102,0x0304,0x0528,0x2500,0x030A,0x0B0C,0x0900,
	0x0000,0x0000,0x0000,0x0000,0x0000,0x0028,0x2500,0x030A,
	0x0B0C,0x0900,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,
	0x0000,0x0000,0x0000,0x0000,0x0051,0x0000,0x0000,0x0000,--0x0041
	0x0002,0x0002,--0x0002,--0x0000,0x0000,0x0000,0x0000,0x0000,--0x110~0x117
	--0x0000,0x0000,0x0000,0x0000,0x0000,--0x0000,0x0000,0x0000,--0x118-0x11F FS FLAG
	};

local tftInitialDCode = {
0x7210,0xB1F9,0x04CC,0x1070,0x0706,0x86B0,0x8008,0x0060,
0x0053,0x00A5,0x4000,0x007F,0x0023,0x2B32,0x7200,0x7840,
0x0204,0x0000,0x0000,0x0915,0x0915,0x0915,0x0010,0x0000,
0x0000,0x0000,0x0000,0x0000,0x0000,0x007A,0x8F4F,0x4E28,
0xAFAF,0x1030,0x1040,0x4040,0xFC48,0x11FF,0xB715,0x111F,
0x4800,0xD300,0x0006,0x090A,0x0610,0x1720,0x292C,0x2E22,
0x1B22,0x2D22,0x1C29,0x2C1C,0x0006,0x090A,0x0610,0x1720,
0x292C,0x2E22,0x1B22,0x2D22,0x1C29,0x2C1C,0x0006,0x090A,
0x0610,0x1720,0x292C,0x2E22,0x1B22,0x2D22,0x1C29,0x2C1C,
0x0006,0x090B,0x0711,0x1922,0x2D30,0x3228,0x2227,0x2F23,
0x1B27,0x2A1A,0x0006,0x090B,0x0711,0x1922,0x2D30,0x3228,
0x2227,0x2F23,0x1B27,0x2A1A,0x0006,0x090B,0x0711,0x1922,
0x2D30,0x3228,0x2227,0x2F23,0x1B27,0x2A1A,0x1010,0x1080,
0x6E70,0x34FF,0x005F,0x000A,0x0000,0x0A00,0x0004,0x0C1C,--0x6569
0x2C3C,0x5C7C,0xBCFC,0x7CFC,0x0080,0x0040,0x80A0,0xC0D0,
0xE0F0,0xF8FC,0x0000,0x05AF,0xFFFF,0x0004,0x0C1C,0x2C3C,
0x5C7C,0xBCFC,0x7CFC,0x0080,0x0040,0x80A0,0xC0D0,0xE0F0,
0xF8FC,0x0000,0x05AF,0xFFFF,0x0004,0x0C1C,0x2C3C,0x5C7C,
0xBCFC,0x7CFC,0x0080,0x0040,0x80A0,0xC0D0,0xE0F0,0xF8FC,
0x0000,0x05AF,0xFFFF,0x1055,0x23FF,0xAAAA,0xAAAA,0xAA00,
0x0000,0x0000,0x0000,0x0000,0x0023,0xAAAA,0xAAAA,0xAA00,
0x0000,0x0000,0x0000,0x0000,0x0003,0x5C5C,0x0E06,0x0E06,
0x5A1A,0x111A,0x1A11,0x003F,0x3C00,0xFF10,0x0020,0x4060,
0x80A0,0xC0E0,0x1078,0xC000,0x0000,0x0000,0x7323,0x0F8C,
0x0000,0x0000,0x0032,0x3232,0x0102,0x0100,0x0101,0x0006,
0x4354,0x0201,0x0282,0x0000,0x0000,0x0000,0x000A,0x0000,
0x0082,0x0020,0x0000,0x0000,0x0400,0x2053,0x5327,0x3600,
0x1000,0xC028,0x252B,0x0309,0x0C0B,0x0A00,0x0000,0x0000,
0x0000,0x0000,0x0000,0x0000,0x0102,0x0304,0x0528,0x252B,
0x0309,0x0C0B,0x0A00,0x0000,0x0000,0x0000,0x0000,0x0000,
0x0000,0x0102,0x0304,0x0528,0x2500,0x030A,0x0B0C,0x0900,
0x0000,0x0000,0x0000,0x0000,0x0000,0x0028,0x2500,0x030A,
0x0B0C,0x0900,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,
0x0000,0x0000,0x0000,0x0000,0x0051,0x0000,0x0000,0x0000,--0x0041
0x0002,0x0002,0x0002,--0x0000,0x0000,0x0000,0x0000,0x0000,--0x110~0x117
--0x0000,0x0000,0x0000,0x0000,0x0000,--0x0000,0x0000,0x0000,--0x118-0x11F FS FLAG
};

otpFlowModule = {}
------------------------------------宏定义区域---------------------------------------
--------------------------------------BEGIN------------------------------------------
local DEV_CHAN_0 				= 0			--默认设备通道0
local OPT_CHAN_0 				= 0			--默认光学设备通道0

local VDD_POWER_ITEM 			= 0			--VDD电源项
local VDD_POWER_MIN_VOLTAGE		= 3140		--烧录流程中VDD的配置电压不得低于3.14V
local VDD_POWER_SET_VOLTAGE		= 3300		--VDD配置电压值
local VDD_POWER_MIN_VOLTAGE		= 3470		--烧录流程中VDD的配置电压不得高于于3.47V

local MTP_POWER_ITEM 			= 6			--MTP电源项
local MTP_POWER_MIN_VOLTAGE		= 8400		--烧录流程中MTP的配置电压不得低于8.4V
local MTP_POWER_SET_VOLTAGE		= 8600		--MTP配置电压值
local MTP_POWER_MAX_VOLTAGE		= 8800		--烧录流程中MTP的配置电压不得高于8.8V

local INPUT0_POWER_ITEM 		= 10		--输入0电源项（用于回读MTP电压值)

local GPIO_RESETB				= 98--IO2

local VCOM_EEPROM_ADDR_H 			= 0x0028--0x0050(低1位, 8进制:50, 10进制：40, 16进制: 28)	
local VCOM_EEPROM_ADDR_L 			= 0x0029--0x0051(高8位)	

local INIT_REGISTER_START 			= 0x0000
local INIT_REGISTER_END 			= 0x0214
local gDevChan = 0		
---------------------------------------END-------------------------------------------
------------------------------------宏定义区域---------------------------------------

------------------------------------配置变量区域-------------------------------------
--------------------------------------BEGIN------------------------------------------
local bestVcomValue				= 0
local otpProcessFlag			= false
local backOtpTimes				= {0, 0, 0, 0, 0, 0}
local currentOtpTimes			= {0, 0, 0, 0, 0, 0}
 
---------------------------------------END-------------------------------------------
------------------------------------配置变量区域---------------------------------------
--[[
@功能：执行复位IC 
@devChan(number): 设备通道编号
@Return: NA.
]]--								
local function resetIc(devChan)
	if devChan < 2 then 
		luaGpioSet(101, 0)
		luaMSleep(100)
		luaGpioSet(101, 1)
		luaMSleep(100)
	end
end
--[[
@功能：设置GPIO状态
@devChan(number): 设备通道，其范围为0-3
@state(number): gpio状态值，范围0-1
@Return: N/A
]]--
function otpFlowModule.setPanelGpioState(devChan, state)
	if state == 1 then
		if devChan < 2 then 
			
			luaGpioSet(97, state);--EEPEN	IO1
			luaMSleep(60);		
			luaGpioSet(100, state);--RESETB IO4 LR
			luaMSleep(40);
			luaGpioSet(99, state);--IO3 STBY
		end
	else
		if devChan < 2 then 			
			luaGpioSet(97, state);--EEPEN	IO1
			luaMSleep(40);
			
			luaGpioSet(99, state);--IO3 STBY			
			luaMSleep(170);	
			luaGpioSet(100, state);--RESETB IO4 LR
		end
	end
end

function otpFlowModule.getPgTypeName()
	local pgTypeName = "ETS-4032";--luaGetPgTypeName();
	return pgTypeName;
end

--[[
@功能：写数据到IC寄存器
@devChan(number): 设备通道，其范围为0-3
@regAddr(number): IC寄存器地址
@data(table): 写入的数据
@count(number): 写入的数据个数
@Return(boolean): 
]]--
function otpFlowModule.writeICReg(devChan, regAddr, data, count)
	luaSetVSpiByteFormat(devChan, 14);
	luaSetVSpiMode(devChan, 1);--4线制
	luaSetVSpiEdge(devChan, 0);--上升沿
	
	luaSetVSpiCsState(devChan, false); --高电平有效，默认高电平
	
	--setPanelGpioState(devChan, 0);
	--访问BR93H76XXX-2C EEPROM,高位MSB优先传输
	--先设置WEN:可写的
	--WEN 01 0011 A7~A0
	local wVal = {nil};
	wVal[1] = 0x1300;
	luaVSpiWrite(devChan, wVal);

	luaSetVSpiCsState(devChan, true);
	--luaMSleep(1);
	luaSetVSpiCsState(devChan, false); --高电平有效
	--地址位13位设置1 01* A8~A0
	wVal[1] = 0x1400;
	wVal[1] = luaMath.orOp(wVal[1], regAddr);
	
	luaVSpiWrite(devChan, wVal);
	
	--luaSetVSpiCsState(devChan, true);
	--luaMSleep(1);
	--luaSetVSpiCsState(devChan, false); --高电平有效
	--写数据
	local value = {};
	luaSetVSpiByteFormat(devChan, 16);
	for k, v in ipairs(data) do
		value[1] = v;
		luaVSpiWrite(devChan, value);
		--luaPrintLog(false,"wVal:"..value[1],false,true);
	end
	--luaMSleep(1);--写要求
	luaSetVSpiCsState(devChan, true);
	--luaMSleep(2);
	luaSetVSpiCsState(devChan, false);
	--luaMSleep(2);
	local count = 4;
	while(true)do
		luaVSpiRead(devChan, value);
		if value[1] ~= 0x00 then
			--luaPrintLog(false,"rbusy s:"..value[1],false,true);
			break;
		end
		count = count - 1;
		luaMSleep(1);--写保存
		if count <= 0 then
			luaPrintLog(false,"rbusy f:"..value[1],false,true);
			break;
		end
	end
	luaSetVSpiCsState(devChan, true);--拉低CS
	
	--设置WDS:写保护
	-- WDS 01 0000 A7~A0
	luaSetVSpiByteFormat(devChan, 14);
	luaSetVSpiCsState(devChan, false); --高电平有效
	wVal[1] = 0x1000;
	luaVSpiWrite(devChan, wVal);
	
	luaSetVSpiCsState(devChan, true);--拉低CS
	--setPanelGpioState(devChan, 1);
	--luaMSleep(3);--写保存
	return true;
end

--[[
@功能：从IC寄存器读取数据
@devChan(number): 设备通道，其范围为0-3
@regAddr(number): IC寄存器地址
@count(number): 读取的数据个数
@Return(table): 返回读取到的寄存器数据
]]--
function otpFlowModule.readICReg(devChan, regAddr, data, count)
	luaSetVSpiByteFormat(devChan, 14);
	luaSetVSpiMode(devChan, 1);--4线制
	luaSetVSpiEdge(devChan, 0);--上升沿
	luaSetVSpiCsState(devChan, false);
	
	--setPanelGpioState(devChan, 0);
	--访问BR93H76XXX-2C EEPROM,高位MSB优先传输
	--先设置WEN:可写的
	-- WEN 01 0011 A7~A0
	local wVal = {nil};
	--[[
	wVal[1] = 0x1300;
	luaVSpiWrite(devChan, wVal);
	
	luaSetVSpiCsState(devChan, true);
	
	--luaMSleep(1);
	luaSetVSpiCsState(devChan, false); --高电平有效
	]]--
	--地址位13位设置1 10* A8~A0
	wVal[1] = 0x1800;
	wVal[1] = luaMath.orOp(wVal[1], regAddr);
	
	luaVSpiWrite(devChan, wVal);
	
	--数据位16位
	luaSetVSpiByteFormat(devChan, 16);--D15~D0
	--local data = {};
	for k = 1, count, 1 do
		local value = {};

		bSuccess = luaVSpiRead(devChan, value);
		if bSuccess == false then
	  		break;
		end

		data[k] = value[1];
	end
	
	--设置WDS:写保护
	-- WDS 01 0000 A7~A0
	
	luaSetVSpiCsState(devChan, true);
	--luaMSleep(1);
	--[[
	luaSetVSpiByteFormat(devChan, 14);
	luaSetVSpiCsState(devChan, false); --高电平有效
	wVal[1] = 0x1000;
	luaVSpiWrite(devChan, wVal);
	
	luaSetVSpiCsState(devChan, true);
	]]--
	--setPanelGpioState(devChan, 1);
  return data
end

--[[
@功能：执行change Page 
@devChan(number): 设备通道编号
@pageNum(number): 切页的数字
@Return: bRet(bool).
]]--
local function changePage(devChan, pageNum)
	local bRet = true;

	--1. Set request page
	luaWrite2ICReg(devChan, 0x00, {pageNum}, 1)
	return bRet
end	

--[[
@功能：执行OTP Read Vcom Times Flow
@devChan(number): 设备通道编号
@Return: count(number).
]]--
function otpFlowModule.readVcomTimes(devChan)
	local vcomTimes = {};
	local vcomTimes1 = {};
	local times = 0;
	
	luaWrite2ICReg(devChan, 0x00, {2}, 1);   --page 2
	luaReadFromICReg(devChan, 0x1C, vcomTimes,1);
	luaReadFromICReg(devChan, 0x1D, vcomTimes1,1);
	
	if vcomTimes[1]==0x1 then 
	   times= 1;
	end
	if vcomTimes[1]==0x02 then 
	   times= 2;
	end
	if vcomTimes[1]==0x4 then 
	   times= 3;
	end
	if vcomTimes[1]==0x8 then 
	   times= 4;
	end
	if vcomTimes[1]==0x10 then 
	   times= 5;
	end
	if vcomTimes[1]==0x20 then 
	   times= 6;
	end
	if vcomTimes[1]==0x40 then 
	   times= 7;
	end
	if vcomTimes[1]==0x80 then 
	   times= 8;
	end
	if vcomTimes[1]==0x0 then 
		if vcomTimes1[1]==0x1 then 
		   times= 9;
		end
		if vcomTimes1[1]==0x02 then 
		   times= 10;
		end
	end
	
	local str = string.format("vcomTimes=%2d次",times);
	luaPrintLog(false,str,false,true)
	
	return times;
end	

--[[
@功能：执行OTP adjust Vcom Value Flow
@devChan(number): 设备通道编号
@vcomValue(number): vcom写入的数值
@Return: bRet(bool).
]]--
function otpFlowModule.writeICVcom(devChan, vcomValue)
	local bRet = true;
	
	local dataH = (vcomValue / 256);
	local dataL = luaMath.andOp(vcomValue,0xff);
	
	luaWrite2ICReg(devChan, 0x00, {0x02}, 1);	--选择Page2

	luaWrite2ICReg(devChan, 0x17, {dataH}, 1);
	luaWrite2ICReg(devChan, 0x18, {dataL}, 1);
	
	--luaWrite2ICReg(devChan,0x00,{0x15},1); --page15
	--luaWrite2ICReg(devChan,0x01,{0xB},1); --VCOM group]]--
	
	--bestVcomValue = vcomValue;
	
	return bRet;
end	

--[[
@功能：执行OTP read Vcom Value Flow
@devChan(number): 设备通道编号
@Return: vcomValue(number).
]]--
function otpFlowModule.readICVcom(devChan)
	local vcomVal = 0;
	local dataH = {};
	local dataL = {};
	
	luaWrite2ICReg(devChan, 0x00, {2}, 1);  --page 2
	luaReadFromICReg(devChan, 0x17,dataH, 1);
	luaReadFromICReg(devChan, 0x18, dataL,1);

	vcomVal = luaMath.andOp(dataH[1],0x01) * 256 + dataL[1];

	local str = string.format("vcomVal = 0x%2x",vcomVal);
	luaPrintLog(false,str,false,true);

	return vcomVal; 
end	

--[[
@功能：执行OTP adjust Vcom Value Flow
@devChan(number): 设备通道编号
@vcomValue(number): vcom写入的数值
@Return: bRet(bool).
]]--
function otpFlowModule.writeVcom(devChan, vcomValue)
	local bRet = true;
	
	vcomValue = luaMath.andOp(vcomValue,0x1ff);--只允许9位有效
	local dataH = luaMath.rShiftOp(vcomValue,8);
	local dataL = luaMath.lShiftOp(luaMath.andOp(vcomValue,0xff), 8);--将数据移到高8位
	local vcomTemp = {nil};
    dataH = luaMath.orOp(0x4800,dataH);
	otpFlowModule.writeICReg(devChan, VCOM_EEPROM_ADDR_H, {dataH}, 1);
	otpFlowModule.writeICReg(devChan, VCOM_EEPROM_ADDR_L, {dataL}, 1);
	bestVcomValue = vcomValue;
	luaMSleep(100);
	return bRet;
end	

--[[
@功能：执行OTP read Vcom Value Flow
@devChan(number): 设备通道编号
@Return: vcomValue(number).
]]--
function otpFlowModule.readVcom(devChan)
	local vcomVal = 0;
	local vcomTemp = {nil};
	local dataH = {};
	local dataL = {};
	
	otpFlowModule.readICReg(devChan, VCOM_EEPROM_ADDR_H,dataH, 1);
	otpFlowModule.readICReg(devChan, VCOM_EEPROM_ADDR_L,dataL,1);
	
	dataL[1] = luaMath.rShiftOp(dataL[1], 8);
	
	vcomVal = luaMath.andOp(dataH[1],0x01) * 256 + luaMath.andOp(dataL[1], 0xFF);
	vcomVal = luaMath.andOp(vcomVal,0x1ff);
	str = string.format("vcomVal = %#x",vcomVal);
	luaPrintLog(false,str,false,true);

	return vcomVal; 
end	

--[[
@功能：写数据到EEPROM
@devChan(number): 设备通道，其范围为0-3
@regAddr(number): IC寄存器地址
@data(table): 写入的数据
@count(number): 写入的数据个数
@Return(boolean): 
]]--
function otpFlowModule.write2EppReg(devChan, regAddr, data, count)
	otpFlowModule.writeICReg(devChan, regAddr, data, count);
	--luaMSleep(20);--延时20ms
	if 0x0068 == regAddr or 0x010c == regAddr then
		tftInitialDCode[regAddr+1] = data[1];
		--luaPrintLog(false, "tftInitialDCode value:"..tftInitialDCode[regAddr+1], false, true);
	end
end

--[[
@功能：从EEPROM读数据
@devChan(number): 设备通道，其范围为0-3
@regAddr(number): IC寄存器地址
@count(number): 写入的数据个数
@Return(table): 读到数据
]]--
function otpFlowModule.readFromEppReg(devChan, regAddr, count)
	local data = {};
	otpFlowModule.readICReg(devChan, regAddr, data, count);
	luaMSleep(20);--延时20ms
	return data;
end

--[[
@功能：写数据到多个EEPROM Reg
@devChan(number): 设备通道，其范围为0-3
@regAddr(table): IC寄存器地址
@data(table): 写入的数据
@count(number): 写入的数据个数
@Return(boolean): 
]]--
function otpFlowModule.write2EppsRegs(devChan, regAddr, data, count)
	for i= 1, #regAddr do 
		otpFlowModule.writeICReg(devChan, regAddr[i], data[i], count);
		luaMSleep(5);
	end
	--luaPrintLog(false, "++++++++++", false, true);

end

--[[
@功能：核对code初始化值
@devChan(number): 设备通道编号
@flag(bool): true-写入；false-检测.
@Return(boolean): true-比对成功；false-比对失败.
]]--
function otpFlowModule.checkEInitCode(devChan, flag)
	local bReadBack = true;
	local regValueTemp = {nil};
	local reTrycount = 3;
	--otpFlowModule.setPanelGpioState(devChan, 0);
	for i, regValue in ipairs(tftInitialECode) do
		local regAddr = i - 1;
		otpFlowModule.readICReg(devChan, regAddr,regValueTemp, 1);
		luaMSleep(10);
		if regValue ~= regValueTemp[1] then
			if flag == true then
				if 0x28 == regAddr or 0x29 == regAddr then		
					otpFlowModule.writeICReg(devChan,regAddr,{regValue},1);
					--luaPrintLog(false,string.format("EEPROM写入最佳VCOM值,地址:[%#x],值:[%#x]", regAddr, regValueTemp[1]),false,true);
				else
					while (true) do 
						otpFlowModule.writeICReg(devChan,regAddr,{regValue},1);
						--luaPrintLog(false,string.format("EEPROM写入初始化值,地址:[%#x],初始值:[%#x],读取值:[%#x]", regAddr, regValue, regValueTemp[1]),false,true);
						luaMSleep(10);
						otpFlowModule.readICReg(devChan, regAddr,regValueTemp, 1);
						luaMSleep(10);
						if regValue ~= regValueTemp[1] then
							if 0 == reTrycount then
								luaPrintLog(true,string.format("EEPROM写入初始化值失败,地址:[%#x],比对值:[%#x],读取值:[%#x]", regAddr, regValue, regValueTemp[1]),false,true);
								return false;
							end
						else
							reTrycount = 3;
							break;
						end
						reTrycount = reTrycount - 1;
					end
				end
			else
				if 0x28 == regAddr or 0x29 == regAddr or 0x68 == regAddr or 0x10C == regAddr then
					;--bReadBack = true;
				else
					luaPrintLog(true,string.format("EEPROM初始化值检测失败,地址:[%#x],比对值:[%#x],读取值:[%#x]", regAddr, regValue, regValueTemp[1]),false,true);
					bReadBack = false;
				end
				--write2ICReg(devChan,regAddr,{regValue},1);
			end
			luaMSleep(10);
		else
			 if 3 ~= reTrycount then 
				reTrycount = 3;
			 end
			--luaPrintLog(false,string.format("EEPROM初始化值检测,地址:[%#x],比对值:[%#x],读取值:[%#x]", regAddr, regValue, regValueTemp[1]),false,true);
		end
		--luaPrintLog(false,string.format("EEPROM初始化值检测,地址:[0x%4x],比对值:[0x%4x],读取值:[0x%4x]", regAddr, regValue, regValueTemp[1]),false,true);
	end
	--otpFlowModule.setPanelGpioState(devChan, 1);
	return bReadBack;
end

--[[
@功能：核对code初始化值
@devChan(number): 设备通道编号
@flag(bool): true-写入；false-检测.
@Return(boolean): true-比对成功；false-比对失败.
]]--
function otpFlowModule.checkMeInitCode(devChan, flag)
	local bReadBack = true;
	local regValueTemp = {nil};
	local reTrycount = 3;
	--otpFlowModule.setPanelGpioState(devChan, 0);
	for i, regValue in ipairs(tftInitialMeCode) do
		local regAddr = i - 1;
		otpFlowModule.readICReg(devChan, regAddr,regValueTemp, 1);
		luaMSleep(10);
		if regValue ~= regValueTemp[1] then
			if flag == true then
				if 0x28 == regAddr or 0x29 == regAddr then		
					--write2ICReg(devChan,regAddr,{regValue},1);
					luaPrintLog(false,string.format("EEPROM写入最佳VCOM值,地址:[%#x],值:[%#x]", regAddr, regValueTemp[1]),false,true);
				else
					while (true) do 
						otpFlowModule.writeICReg(devChan,regAddr,{regValue},1);
						--luaPrintLog(false,string.format("EEPROM写入初始化值,地址:[%#x],初始值:[%#x],读取值:[%#x]", regAddr, regValue, regValueTemp[1]),false,true);
						luaMSleep(10);
						otpFlowModule.readICReg(devChan, regAddr,regValueTemp, 1);
						luaMSleep(10);
						if regValue ~= regValueTemp[1] then
							if 0 == reTrycount then
								luaPrintLog(true,string.format("EEPROM写入初始化值失败,地址:[%#x],比对值:[%#x],读取值:[%#x]", regAddr, regValue, regValueTemp[1]),false,true);
								return false;
							end
						else
							reTrycount = 3;
							break;
						end
						reTrycount = reTrycount - 1;
					end
				end
			else
				if 0x28 == regAddr or 0x29 == regAddr or 0x68 == regAddr or 0x10C == regAddr then
					;--bReadBack = true;
				else
					luaPrintLog(true,string.format("EEPROM初始化值检测失败,地址:[%#x],比对值:[%#x],读取值:[%#x]", regAddr, regValue, regValueTemp[1]),false,true);
					bReadBack = false;
				end
				--write2ICReg(devChan,regAddr,{regValue},1);
			end
			luaMSleep(10);
		else
			 if 3 ~= reTrycount then 
				reTrycount = 3;
			 end
			--luaPrintLog(false,string.format("EEPROM初始化值检测,地址:[%#x],比对值:[%#x],读取值:[%#x]", regAddr, regValue, regValueTemp[1]),false,true);
		end
		--luaPrintLog(false,string.format("EEPROM初始化值检测,地址:[0x%4x],比对值:[0x%4x],读取值:[0x%4x]", regAddr, regValue, regValueTemp[1]),false,true);
	end
	--otpFlowModule.setPanelGpioState(devChan, 1);
	return bReadBack;
end
--[[
@功能：核对code初始化值
@devChan(number): 设备通道编号
@flag(bool): true-写入；false-检测.
@Return(boolean): true-比对成功；false-比对失败.
]]--
function otpFlowModule.checkDInitCode(devChan, flag)
	local bReadBack = true;
	local regValueTemp = {nil};
	local reTrycount = 3;
	--otpFlowModule.setPanelGpioState(devChan, 0);
	for i, regValue in ipairs(tftInitialDCode) do
		local regAddr = i - 1;
		otpFlowModule.readICReg(devChan, regAddr,regValueTemp, 1);
		luaMSleep(10);
		if regValue ~= regValueTemp[1] then
			if flag == true then
				if 0x28 == regAddr or 0x29 == regAddr then		
					--write2ICReg(devChan,regAddr,{regValue},1);
					luaPrintLog(false,string.format("EEPROM写入最佳VCOM值,地址:[%#x],值:[%#x]", regAddr, regValueTemp[1]),false,true);
				else
					while (true) do 
						otpFlowModule.writeICReg(devChan,regAddr,{regValue},1);
						--luaPrintLog(false,string.format("EEPROM写入初始化值,地址:[%#x],初始值:[%#x],读取值:[%#x]", regAddr, regValue, regValueTemp[1]),false,true);
						luaMSleep(10);
						otpFlowModule.readICReg(devChan, regAddr,regValueTemp, 1);
						luaMSleep(10);
						if regValue ~= regValueTemp[1] then
							if 0 == reTrycount then
								luaPrintLog(true,string.format("EEPROM写入初始化值失败,地址:[%#x],比对值:[%#x],读取值:[%#x]", regAddr, regValue, regValueTemp[1]),false,true);
								return false;
							end
						else
							reTrycount = 3;
							break;
						end
						reTrycount = reTrycount - 1;
					end
				end
			else
				if 0x28 == regAddr or 0x29 == regAddr or 0x68 == regAddr or 0x10C == regAddr then
					;--bReadBack = true;
				else
					luaPrintLog(true,string.format("EEPROM初始化值检测失败,地址:[%#x],比对值:[%#x],读取值:[%#x]", regAddr, regValue, regValueTemp[1]),false,true);
					bReadBack = false;
				end
				--write2ICReg(devChan,regAddr,{regValue},1);
			end
			luaMSleep(10);
		else
			 if 3 ~= reTrycount then 
				reTrycount = 3;
			 end
			--luaPrintLog(false,string.format("EEPROM初始化值检测,地址:[%#x],比对值:[%#x],读取值:[%#x]", regAddr, regValue, regValueTemp[1]),false,true);
		end
		--luaPrintLog(false,string.format("EEPROM初始化值检测,地址:[0x%4x],比对值:[0x%4x],读取值:[0x%4x]", regAddr, regValue, regValueTemp[1]),false,true);
	end
	--otpFlowModule.setPanelGpioState(devChan, 1);
	return bReadBack;
end

--[[
@功能：执行屏时序流程
@devChan(number): 设备通道编号
@flag(bool): true-上电；false-下电.
@doprocessFunction(function): 处理流程函数.
@Return(boolean): true-烧录成功；false-烧录失败.
]]--
function otpFlowModule.pgTimingProcess(devChan, flag, picName, doprocessFunction, addr, data, count)
	local bRet = true;
	
	if true == flag then
		--luaGpioSet(97, 1);--EEPEN	IO1
		luaMSleep(10);
		luaSetPwrOutputVoltage(devChan, 0, 3450);
		luaSetPwrOutput(devChan,0,true);

		luaMSleep(10);
		luaSetPwrOutputVoltage(devChan, 1, 3300);
		luaSetPwrOutput(devChan,1,true);
		luaMSleep(300);
		
		luaGpioSet(97, 1);--EEPEN	IO1
		
		luaMSleep(10);
		luaGpioSet(101, 1);--IO5
		
		luaMSleep(50);--50
		luaGpioSet(100, 1);--RESETB IO4 LR
		
		luaMSleep(2570);--70
		luaGpioSet(99, 1);--IO3 STBY
		
		luaMSleep(160);
		luaSetSignalOutput(true);
		luaMSleep(200);
		--luaShowRGB(255, 255, 255);--show black
		if picName ~= nil then
			luaShowImage(picName);
		end
		luaMSleep(500);
		--luaSetPwrOutputVoltage(devChan, 5, 1200);
		--luaSetPwrOutput(devChan,5,true);
		luaStartDevChanTask(devChan);
	else
		if count == 0 then
			--bRet = doprocessFunction(devChan);
			luaStopDevChanTask(devChan);
		else
			if addr[1] == nil then
				--bRet = doprocessFunction(devChan, data);--执行处理流程(EEPEN,RESETB为low)
				luaStopDevChanTask(devChan);
			else
				--bRet = doprocessFunction(devChan, addr, data, count);--执行处理流程(EEPEN,RESETB为low)
			end
		end

		luaGpioSet(97, 0);--EEPEN	IO1
		
		luaMSleep(10);
		luaGpioSet(99, 0);--IO3 STBY
		--luaShowRGB(0, 0, 0);--show black
		if picName ~= nil then
			luaShowImage(picName);
		else
			luaShowRGB(0, 0, 0);--show black
		end
		
		luaMSleep(50);
		luaGpioSet(101, 0);--IO5
		
		luaMSleep(130);	
		luaGpioSet(100, 0);--RESETB IO4 LR
		
		luaMSleep(50);--20
		luaSetSignalOutput(false);
		luaMSleep(20);
		
		if count == 0 then
			if doprocessFunction == nil then
				;
			else
				bRet = doprocessFunction(devChan);
			end
			--luaStopDevChanTask(devChan);
		else
			if addr[1] == nil then
				bRet = doprocessFunction(devChan, data);--执行处理流程(EEPEN,RESETB为low)
				--luaStopDevChanTask(devChan);
			else
				bRet = doprocessFunction(devChan, addr, data, count);--执行处理流程(EEPEN,RESETB为low)
				--luaPrintLog(false, "=====:", false, true);
			end
		end

		luaMSleep(10);
		--luaSetPwrOutputVoltage(devChan, 2, 0);
		luaSetPwrOutput(devChan,1,false);
		luaMSleep(130);
		--luaSetPwrOutputVoltage(devChan, 1, 0);
		luaSetPwrOutput(devChan,0,false);
		
		
		luaMSleep(400);--tpon ？？

	end
	return bRet;
end
--[[
@功能：执行烧录流程
@devChan(number): 设备通道编号
@vcomValue(number): 烧录的vcom值
@Return(boolean): true-烧录成功；false-烧录失败.
]]--
function otpFlowModule.doBurn(devChan, vcomValue)
	local bRet = true;
	local powerInfo = {};
	--1. 启用Mtp电压
	luaSetPwrOutputVoltage(devChan, MTP_POWER_ITEM, MTP_POWER_SET_VOLTAGE);
	luaSetPwrOutput(devChan,MTP_POWER_ITEM,true);
	--2. 延时10ms等待电压稳定
	luaMSleep(30);
	
	luaReadRealTimePowerItem(devChan, MTP_POWER_ITEM, powerInfo)	--读取VMTP实时电源项信息
	if powerInfo[1] < MTP_POWER_MIN_VOLTAGE or powerInfo[1] > MTP_POWER_MAX_VOLTAGE then
		local str = string.format("VMTP电压值[%.3fmV]不在(%.3f~%.3f)mV卡控范围内", powerInfo[1], MTP_POWER_MIN_VOLTAGE, MTP_POWER_MAX_VOLTAGE);
		luaPrintLog(true, str, false, true);
		luaSetPwrOutput(devChan,MTP_POWER_ITEM,false);
		return false;
	else
		local str = string.format("VMTP电压值[%.3fmV]在(%.3f~%.3f)mV卡控范围内", powerInfo[1], MTP_POWER_MIN_VOLTAGE, MTP_POWER_MAX_VOLTAGE);
		luaPrintLog(false, str, false, true);
	end
	--4. 循环烧录操作
	--4.1 写入需要烧录的数据
	writeVcom(devChan, vcomValue);
	
	--4.1 选择烧录Page
	luaMSleep(100);
	luaWrite2ICReg(devChan,0x00,{0x15},1); --page15
	
	--4.2 写password
	luaWrite2ICReg(devChan,0x02,{0x66},1); 
	
	--4.3 使能Standby模式
	luaWrite2ICReg(devChan,0x00,{0x00},1); --page0
	luaWrite2ICReg(devChan,0x1E,{0x55},1); --使能Standby模式
	luaMSleep(10);
	
	--4.4 选择烧录项Group
	luaWrite2ICReg(devChan,0x00,{0x15},1); --page15
	luaWrite2ICReg(devChan,0x01,{0xB},1); --VCOM group
	
	--4.5 写烧录标志
	luaWrite2ICReg(devChan,0x03,{0x01},1); --设置OTP_WR为1
	
	--4.6 延时15ms等待烧录完成标志
	luaMSleep(20);
	
	--4.7 读取OTP相关标志
	local tempValue = {};
	luaWrite2ICReg(devChan,0x00,{0x02},1); --page2
	luaReadFromICReg(devChan, 0x12, tempValue, 1);
	if 0 == luaMath.andOp(tempValue[1], 0x40) then
		luaReadFromICReg(devChan, 0x1A, tempValue, 1);
		if 0 == luaMath.andOp(tempValue[1], 0x40) then
			luaPrintLog(true, "读取OTP_TRIM_FLAG失败，程序异常关电", false, true);
			luaSetPwrOutput(devChan,MTP_POWER_ITEM,false);
			return false;
		end
	end
	
	--4.8 进入4.1继续烧录其他项
	
	--5. 禁用Mtp电压
	luaSetPwrOutput(devChan,MTP_POWER_ITEM,false);
	
	--6 失能Standby模式
	luaWrite2ICReg(devChan,0x00,{0x00},1); --page0
	luaWrite2ICReg(devChan,0x1E,{0x00},1); --使能Standby模式
	luaMSleep(10);
	
	--7 写password
	luaWrite2ICReg(devChan,0,{0x15},1); --page15
	luaWrite2ICReg(devChan,2,{0x00},1); 
	
	--8. 硬复位
	resetIc(devChan);
	luaMSleep(100);
	
	--9. 烧录回读比对
	local newVcom = readVcom(devChan);
	
	str = string.format("newVcom:0x%2x,setVcom:0x%2x",newVcom,vcomVal);
	luaPrintLog(false, str, true, true);
	
	if newVcom == vcomVal then
		bSucess	= true
		luaPrintLog(false, "vcom烧录成功", false, false);
	end	
	--marginRead(devChan, vcomValue);
	
	--luaSendInitCode(devChan);
	luaMSleep(10);
	return bRet
end

function otpFlowModule.readMcuVer(devChan)
	slaveAddr = 0x18
	local data = {};
	local mcuVerInfo = {{"V5",101},{"V5",102},{"V3",103},{"V4",104}};
	luaI2CWrite(devChan, 0x18, {0x87}, {0x00}, 1);
	luaMSleep(500);
    luaI2CRead(devChan, 0x18, {0x87}, data, 3);
	luaPrintLog(false, string.format("%d%d%d", data[1],data[2],data[3]), false, false);
	local mcuVer = tonumber(string.format("%d%d%d",data[1],data[2],data[3]));
	if mcuVer > 100 then
		return mcuVerInfo[mcuVer-100];
	else
		return {"Vnil",-1};
	end
end

local RTC_SLAVE_ADDR 	= 0x68;--;0x68		--7bit的RTC从机地址
--local RTC_TIME_REG = {0x06,0x05,0x04,0x02,0x01,0x00,0x03};--年，月,日，时，分，秒，星期
local RTC_TIME_REG = {0x06,0x05,0x04,0x02,0x01,0x00};--年,月,日,时,分,秒
local rtcTimeName = {"年","月","日","时","分","秒"};--"星期"
local readRtcData = {};
local writeRtcTime = {};--年,月,日,时,分,秒
local stTimeValue = {99,12,31,24,59,59};--7


--local sWrRtcTime = "";
local function doReadRtc()
	local data = {};
	local bRet = true;
	--[[
	luaI2CWrite(gDevChan, RTC_SLAVE_ADDR, {0x00}, {0x80}, 1);
	luaMSleep(30);
	luaI2CWrite(gDevChan, RTC_SLAVE_ADDR, {0x00}, {0x00}, 1);
	luaMSleep(30);
	]]--
	local mcuVerInfo = otpFlowModule.readMcuVer(gDevChan);
	luaPrintLog(false, string.format("MCU %s:%d", mcuVerInfo[1],mcuVerInfo[2]), false, false);
	if mcuVerInfo[2] ~= 102 and mcuVerInfo[2] ~= 101 then
		for i = 1, #RTC_TIME_REG do
			--luaI2CWrite(gDevChan, RTC_SLAVE_ADDR, {0x22}, {0x01}, 1);
			--luaI2CRead(gDevChan, RTC_SLAVE_ADDR, {0x22}, data, 7);
			luaI2CRead(gDevChan, RTC_SLAVE_ADDR, {RTC_TIME_REG[i]}, data, 1);
			if nil ~= data[1] then
				if (i == 5 and (data[1]&0xF == 0x09)) then
					data = {nil};
					luaMSleep(500);
					luaI2CRead(gDevChan, RTC_SLAVE_ADDR, {RTC_TIME_REG[i]}, data, 1);
				end
				if nil ~= data[1] then
					readRtcData[i] = data[1];
				end
			else
				return false;
			end
			luaMSleep(30);
		end
		readRtcData[6] = tonumber(string.format("%d%d",luaMath.rShiftOp(readRtcData[6],4)&0x7,readRtcData[6]&0xF));
		readRtcData[5] = tonumber(string.format("%d%d",luaMath.rShiftOp(readRtcData[5],4)&0x7,readRtcData[5]&0xF));
		readRtcData[4] = tonumber(string.format("%d%d",luaMath.rShiftOp(readRtcData[4],4)&0x3,readRtcData[4]&0xF));
		--readRtcData[4] = tonumber(string.format("%d",readRtcData[4]&0x7));
		readRtcData[3] = tonumber(string.format("%d%d",luaMath.rShiftOp(readRtcData[3],4)&0x3,readRtcData[3]&0xF));
		readRtcData[2] = tonumber(string.format("%d%d",luaMath.rShiftOp(readRtcData[2],4)&0x1,readRtcData[2]&0xF));
		readRtcData[1] = tonumber(string.format("%d%d",luaMath.rShiftOp(readRtcData[1],4)&0xF,readRtcData[1]&0xF));
	else
		--local writeData = {0x22, 0x09,0x07,0x19,0x12,0x30,0x03}--写入数据格式为8421BCD码格式
		local writeData = {0x00};
		luaI2CWrite(gDevChan, 0x18, {0x22}, writeData, #writeData);
		luaMSleep(500);
		luaI2CRead(gDevChan, 0x18, {0x22}, readRtcData, 7);
	end
	for i = 1, #RTC_TIME_REG do
		--luaPrintLog(false,string.format("rtc 地址:[0X%02X],[%s]:[%02d]", RTC_TIME_REG[i], rtcTimeName[i],readRtcData[i]),false,true);
		if stTimeValue[i] < readRtcData[i] then
			bRet = false;
		else
			if i == 1 then
				writeRtcTime[i] = readRtcData[i]+2000;
			else
				writeRtcTime[i] = readRtcData[i];
			end
			--luaPrintLog(false,string.format("写入RTC时间[%s]:[%d]", rtcTimeName[i],writeRtcTime[i]),false,true);
		end
	end
	return bRet;
end

function otpFlowModule.doreadSysTime()
	local RTC = true 
	local tempDate = os.date("*t", os.time());
	local year = tonumber(tempDate.year);
	if year < 2022 then
		--luaPrintLog(false,string.format("powerOnFlag:false"),false,true);
		luaMSleep(5000);
		if false == doReadRtc() then
			luaPrintLog(true,string.format("RTC时间获取错误,请重新校正获取!"),false,true);
			--luaTriggerPowerOff(false) --异常关电
			   RTC = false
			return false;
		else
			--luaPrintLog(false,string.format("RTC时间获取成功!"),false,true);
			if false==luaSetSystemTime(writeRtcTime) then
				luaPrintLog(true,string.format("SYS系统时间设置失败,请重新设置!"),false,true);
				return false;
			else
				tempDate = os.date("*t", os.time());
				year = tonumber(tempDate.year);
				local readSysTime=os.date("%Y/%m/%d %H:%M:%S");--"%Y/%m/%d %A %p %H:%M:%S"
				if year < 2022 then
					luaPrintLog(true,string.format("系统时间为:%s异常,请校准!",readSysTime),false,true);
					return false;
				else
					luaPrintLog(false,string.format("系统时间:%s,校准成功!",readSysTime),false,true);
				end
			end
		end
	else
		local readSysTime=os.date("%Y/%m/%d %H:%M:%S");--"%Y/%m/%d %A %p %H:%M:%S"
		luaPrintLog(false,string.format("系统时间:%s,获取成功!",readSysTime),false,true);
	end
	
	return RTC ;
end

return otpFlowModule