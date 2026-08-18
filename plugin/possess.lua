vim.api.nvim_create_user_command("Possess", function(opts)
	require("possess").connect(opts.fargs[1], opts.fargs[2])
end, { nargs = "+" })

vim.api.nvim_create_user_command("PossessUnmount", function(opts)
	require("possess").unmount(opts.fargs[1])
end, { nargs = 1 })
