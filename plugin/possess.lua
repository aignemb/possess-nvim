vim.api.nvim_create_user_command("Possess", function(opts)
	require("possess").connect(opts.fargs)
end, { nargs = "+" })

vim.api.nvim_create_user_command("PossessNew", function()
	require("possess").new_window()
end, {})

vim.api.nvim_create_user_command("PossessBuf", function(opts)
	require("possess").init_buf(opts.fargs[1], function()
		print("hello")
	end)
end, { nargs = 1 })

require("possess.buffers")

vim.api.nvim_create_user_command("PossessUnmount", function(opts)
	require("possess").unmount(opts.fargs[1])
end, { nargs = 1 })
