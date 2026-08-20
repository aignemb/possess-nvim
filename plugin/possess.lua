vim.api.nvim_create_user_command("Possess", function(opts)
	require("possess").connect(opts.fargs)
end, { nargs = "+" })

vim.api.nvim_create_user_command("PossessNew", function()
	require("possess").new_window()
end, {})

vim.api.nvim_create_user_command("PossessBuf", function(opts)
	local name = opts.fargs[1]
	local def = require("possess.buffers")[name]
	if def then
		require("possess").init_buf(def)
	else
		require("possess").init_buf({ name = name })
	end
end, {
	nargs = 1,
	complete = function()
		return vim.tbl_keys(require("possess.buffers"))
	end,
})

require("possess.buffers")

vim.api.nvim_create_user_command("PossessUnmount", function(opts)
	require("possess").unmount(opts.fargs[1])
end, { nargs = 1 })
