local possess = require("possess")

local M = {}

M.buf1 = {
	name = "buf1",
	window = "float",
	fn = function(buf)
		print("hello from buf1")
	end,
}

M.buf2 = {
	name = "buf2",
	window = "vsplit",
	fn = function(buf)
		print("hello from buf2")
	end,
}

return M
