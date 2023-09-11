--定义了一个扩展的Math库，其中包含位与、或、异或、取反、左移、右移
luaMath = {}   
function luaMath.__andBit(left,right)    --1位与  
    return (left == 1 and right == 1) and 1 or 0  
end  
  
function luaMath.__orBit(left, right)    --1位或  
    return (left == 1 or right == 1) and 1 or 0  
end  
  
function luaMath.__xorBit(left, right)   --1位异或  
    return (left + right) == 1 and 1 or 0  
end  
  
function luaMath.__base(left, right, op) --对每一位进行op运算，然后将值返回  
    if left < right then  
        left, right = right, left  
    end  
    local res = 0  
    local shift = 1  
    while left ~= 0 do  
        local ra = left % 2    --取得每一位(最右边)  
        local rb = right % 2     
        res = shift * op(ra,rb) + res  
        shift = shift * 2  
        left = math.modf(left / 2)  --右移  
        right = math.modf(right / 2)  
    end  
    return res  
end  
  
function luaMath.andOp(left, right)		--位与(等同于c/c++ &)  
    return luaMath.__base(left, right, luaMath.__andBit)  
end  
  
function luaMath.xorOp(left, right)		--位异或(等同于c/c++ ^)  
    return luaMath.__base(left, right, luaMath.__xorBit)  
end  
  
function luaMath.orOp(left, right)		--位或(等同于c/c++ |)  
    return luaMath.__base(left, right, luaMath.__orBit)  
end  
  
function luaMath.notOp(left)	--取反(等同于c/c++ ~)	  
    return left > 0 and -(left + 1) or -left - 1  
end  
  
function luaMath.lShiftOp(left, num)  --左移(等同于c/c++ <<)
    return left * (2 ^ num)  
end  
  
function luaMath.rShiftOp(left,num)  --右移(等同于c/c++ >>)
    return math.floor(left / (2 ^ num))  
end

function luaMath.__Char2Val(val)
	local stVal = string.byte("A");
	local endVal = string.byte("F");
	if val >= stVal and val <= endVal then
		return val - stVal + 0x0A;
	else
		return val - string.byte("0");
	end
end

function luaMath.string2BinForEdid(edidStr)
	local data = {nil};
	for i = 1, #edidStr/2 do
		local stIndex = (i - 1)*2 + 1;
		local endIndex = stIndex + 1;
		
		local hVal = luaMath.__Char2Val(string.byte(edidStr, stIndex));
		local lVal = luaMath.__Char2Val(string.byte(edidStr, endIndex));
		
		local val = luaMath.orOp(luaMath.lShiftOp(hVal, 4), lVal);
		data[#data + 1] = val;
	end
		
	return data;
end

return luaMath