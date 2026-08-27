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
		local call_def = def
		if opts.fargs[2] then
			call_def = vim.tbl_extend("force", {}, def, { alias = opts.fargs[2] })
			if name == "ssh" then
				call_def.name = "possess-ssh://" .. opts.fargs[2]
			end
		end
		require("possess").init_buf(call_def)
	else
		require("possess").init_buf({ name = name })
	end
end, {
	nargs = "+",
	complete = function(arg_lead, cmd_line, _)
		local parts = vim.split(cmd_line, "%s+")
		if #parts >= 3 then
			if parts[2] == "ssh" then
				local path = vim.fn.expand("~/possess")
				local entries = vim.fn.readdir(path)
				local aliases = {}
				for _, entry in ipairs(entries) do
					if vim.fn.isdirectory(path .. "/" .. entry) == 1 then
						aliases[#aliases + 1] = entry
					end
				end
				return vim.tbl_filter(function(a)
					return vim.startswith(a, arg_lead)
				end, aliases)
			end
			return {}
		end
		return vim.tbl_filter(function(n)
			return vim.startswith(n, arg_lead)
		end, vim.tbl_keys(require("possess.buffers")))
	end,
})

require("possess.buffers")

vim.api.nvim_create_user_command("PossessUnmount", function(opts)
	require("possess").unmount(opts.fargs[1])
end, { nargs = 1 })
