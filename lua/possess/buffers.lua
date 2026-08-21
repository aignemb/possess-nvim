local possess = require("possess")

local M = {}

M.buf1 = {
	name = "buf1",
	window = "float",
	fn = function(buf)
		print("hello from buf1")
	end,
}
function M.init_buf1()
	possess.init_buf(M.buf1)
end

M.buf2 = {
	name = "buf2",
	window = "vsplit",
	fn = function(buf)
		print("hello from buf2")
	end,
}
function M.init_buf2()
	possess.init_buf(M.buf2)
end

M.terminal = {
	name = "terminal",
	window = "float",
	fn = function(buf)
		vim.bo[buf].buftype = "terminal"
		vim.api.nvim_open_term(buf, { cmd = { vim.o.shell } })
	end,
}
function M.init_terminal()
	possess.init_buf(M.terminal)
end

return M
