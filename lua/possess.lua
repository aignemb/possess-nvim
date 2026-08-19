local M = {}

local function ssh_config_exists(name)
	local f = io.open(vim.fn.expand("~/.ssh/config"), "r")
	if not f then
		return false
	end
	local content = f:read("*a") .. "\n"
	f:close()

	for line in content:gmatch("[^\n]+") do
		local hosts = line:match("^%s*[Hh]ost%s+(.+)$")
		if hosts then
			for h in hosts:gmatch("%S+") do
				if h == name then
					return true
				end
			end
		end
	end
	return false
end

local function add_ssh_host(name, hostname, username, port)
	if ssh_config_exists(name) then
		return
	end

	local block = "\nHost " .. name .. "\n"
	if port and port ~= "22" then
		block = block .. "  Port " .. port .. "\n"
	end
	block = block .. "  HostName " .. hostname .. "\n"
	if username then
		block = block .. "  User " .. username .. "\n"
	end

	local f = io.open(vim.fn.expand("~/.ssh/config"), "a")
	if f then
		f:write(block)
		f:close()
		vim.notify("added " .. name .. " to ~/.ssh/config", vim.log.levels.INFO)
	end
end

local function do_mount(connection, alias)
	local mount_path = vim.fn.expand("~/possess/" .. alias)
	vim.fn.mkdir(mount_path, "p")

	vim.fn.system({ "mountpoint", "-q", mount_path })
	if vim.v.shell_error == 0 then
		vim.notify("already mounted at " .. mount_path, vim.log.levels.INFO)
	else
		local result = vim.fn.system({
			"sshfs",
			"-o", "reconnect,ServerAliveInterval=15,ServerAliveCountMax=3",
			connection .. ":",
			mount_path,
		})
		if vim.v.shell_error ~= 0 then
			error(vim.trim(result))
		end
		vim.notify("mounted " .. connection .. " -> " .. mount_path, vim.log.levels.INFO)
	end

	vim.fn.chdir(mount_path)
	vim.cmd("Oil " .. vim.fn.fnameescape(mount_path))
end

function M.connect(args)
	local user, host, alias, port
	local positional = {}

	for _, arg in ipairs(args) do
		local k, v = arg:match("^(%w+)=(.+)$")
		if k == "user" then
			user = v
		elseif k == "host" then
			host = v
		elseif k == "alias" then
			alias = v
		elseif k == "port" then
			port = v
		else
			table.insert(positional, arg)
		end
	end

	if host and alias then
		local connection = user and (user .. "@" .. host) or host
		add_ssh_host(alias, host, user, port)
		do_mount(connection, alias)
		return
	end

	if #positional == 1 then
		local raw = positional[1]
		alias = raw:match("^[^@]+@(.+)$") or raw
		do_mount(raw, alias)
		return
	end

	error("usage: Possess user=<u> host=<h> alias=<a>  |  Possess <alias>  |  Possess <user@host>")
end

function M.new_window()
	vim.cmd("split")
	local buf = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_buf_set_name(buf, "test")
	vim.api.nvim_win_set_buf(0, vim.fn.bufnr("test"))
	print("hello")
end

function M.init_buf(name, fn)
	local existing = vim.fn.bufnr(name)
	if existing ~= -1 then
		vim.api.nvim_win_set_buf(0, existing)
		return
	end

	local buf = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_buf_set_name(buf, name)
	vim.api.nvim_win_set_buf(0, vim.fn.bufnr(name))

	if fn then
		fn(buf)
	end
end

function M.unmount(alias)
	alias = alias or ""
	local mount_path = vim.fn.expand("~/possess/" .. alias)

	vim.fn.system({ "mountpoint", "-q", mount_path })
	if vim.v.shell_error ~= 0 then
		vim.notify(mount_path .. " is not mounted", vim.log.levels.WARN)
		return
	end

	local result = vim.fn.system({ "fusermount", "-u", mount_path })
	if vim.v.shell_error ~= 0 then
		error(vim.trim(result))
	end

	vim.notify("unmounted " .. mount_path, vim.log.levels.INFO)

	if vim.startswith(vim.fn.getcwd(), mount_path) then
		vim.fn.chdir(vim.fn.expand("~"))
	end
end

return M
