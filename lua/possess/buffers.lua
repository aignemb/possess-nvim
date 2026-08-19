local possess = require("possess")

local buf1 = {
	name = "buf1",
	fn = function()
		print("hello from buf1")
	end,
}
local function init_buf1()
	possess.init_buf(buf1.name, buf1.fn)
end


local buf2 = {
	name = "buf2",
	fn = function()
		print("hello from buf2")
	end,
}
local function init_buf2()
	possess.init_buf(buf2.name, buf2.fn)
end

return {
	buf1 = buf1,
	buf2 = buf2,
	init_buf1 = init_buf1,
	init_buf2 = init_buf2,
}
