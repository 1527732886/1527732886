
require("os")
--[[
--调用系统的sleep函数，不消耗CPU，但是Windows系统中没有内置这个命令（如果你又安装Cygwin神马的也行）。推荐在Linux系统中使用该方法
local function sleep(n)
   os.execute("sleep " .. n)
end

--虽然Windows没有内置sleep命令，但是我们可以稍微利用下ping命令的性质
local function sleep(n)
   if n > 0 then os.execute("ping -n " .. tonumber(n + 1) .. " localhost > NUL") end
end
]]--
--使用socket库中select函数，可以传递0.1给n，使得休眠的时间精度达到毫秒级别。
--require("socket")
--[[
local function sleep(n)
	socket.select(nil, nil, n)
end
]]--

local Rx = {1};
local Ry = {2};
local Gx = {3};
local Gy = {4};
local Bx = {5};
local By = {6};
local Wx = {7};
local Wy = {8};
local W_Lv = {800};

logAccess = {};

local tPanelId = {
"LS132D5LX04",
};

FILE_PATH = '\\data\\log\\';--lfs.currentdir()..'\\data\\log\\';

function logAccess.file_exists(path)
  local file = io.open(path, "rb")
  if file then file:close() end
  return file ~= nil
end

local function ParseLine(strline)
	strline = strline .. ',';  -- ending comma
	local t = {};  -- table to collect fields
	local fieldstart = 1;

	repeat
		-- next field is quoted? (start with `"'?)
		if string.find(strline, '^"', fieldstart) then
			local a, c;
			local i  = fieldstart;
			repeat
			-- find closing quote
				a, i, c = string.find(strline, '"("?)', i+1);
			until c ~= '"'; -- quote not followed by quote?
			if not i then
				print('unmatched "');
			end
			local f = string.sub(strline, fieldstart+1, i-1);
			--print("f前:"..f.."t前:"..t);
			table.insert(t, (string.gsub(f, '""', '"')));
			--print("f后:"..f.."t后:"..t);
			fieldstart = string.find(strline, ',', i) + 1;
		else    -- unquoted; find next comma
			local nexti = string.find(strline, ',', fieldstart);
			local temp = string.sub(strline, fieldstart, nexti-1);
			if string.len(temp) ~= 0 then
				--print("temp:"..temp.." nexti:"..nexti);
			end
			table.insert(t, temp);

			fieldstart = nexti + 1;
		end
	until fieldstart > string.len(strline);
	return t;
end

function logAccess.readCsv(strFileName)
    local file = assert(io.open(strFileName, "r"));
	local line = {};
	local outresults = {};
	local linecontent = {};

	while true do
		line = file:read(); --默认按行读取,返回的是字符串
		if nil ~= line then
			-- print("line:"..line);
			linecontent = ParseLine(line);
			table.insert(outresults, linecontent);
		else
			file:close();
			break;
		end
	end

	return outresults;
end

local function escapeCSV(s)
	if string.find(s, '[,"]') then
		s = '"' .. string.gsub(s, '"', '""') .. '"';
	end
	return s;
end

function logAccess.writeCsv(strFileName, tContent)
	local file = assert(io.open(strFileName, "a+"));
	--print("1====="..tContent);
	for k, v in ipairs(tContent) do
		local line = "";
		for i, j in ipairs(v) do
			if "" == line then
				--print("line前====="..j);
				line = escapeCSV(j);
				--print("line后====="..line);
			else
				line = line .. "," .. escapeCSV(j);
				--print("line normal====="..line);
			end
		end
		file:write(line .. "\n");
	end

	file:close();
end

CSV = {
	READ = logAccess.readCsv,
	WRITE = logAccess.writeCsv,
}

local function doProcess()
  local strHead;
  if logAccess.file_exists(FILE_PATH) == false then
	os.execute("mkdir "..FILE_PATH);
  end
  local path = FILE_PATH..tPanelId[1].."_"..os.date("%Y%m%d")..".csv";

  file = io.open(path , "rb");

  if file == nil then
   strHead = "id,time,SN,R_X,R_Y,G_X,G_Y,B_X,B_Y,W_X,W_Y,W_LV\n";
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
]]--
  local time=os.date("%Y/%m/%d %A %p %H:%M:%S");

  -- print(time);
  --[[file = io.open(path,"a+");
  io.output(file) ;
  local str = IDnumber..","..time..","..tPanelId[1]..","..Rx[1]..","..Ry[1]..","..Gx[1]..","..Gy[1]..","..Bx[1]..","..By[1]..","..Wx[1]..","..Wy[1]..","..W_Lv[1].."\n";
  io.write(str);
  io.close(file);]]--
   local temp = {};
   local logData = {};
   --table.insert(temp,n);
   table.insert(temp,time);
   --[[
   table.insert(temp,tPanelId[1]);
   table.insert(temp,Rx[1]);
   table.insert(temp,Ry[1]);
   table.insert(temp,Gx[1]);
   table.insert(temp,Gy[1]);
   table.insert(temp,Bx[1]);
   table.insert(temp,By[1]);
   table.insert(temp,Wx[1]);
   table.insert(temp,Wy[1]);
   table.insert(temp,W_Lv[1]);
   ]]--
   --Wlv= tonumber(txyLv["Lv"]);
   table.insert(logData,temp);
   CSV.WRITE(path, logData);
   sleep(1);
   CSV.READ(path);
end
--print(lfs.currentdir());
--doProcess();
return logAccess;
