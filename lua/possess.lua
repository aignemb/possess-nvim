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

local function resolve_dim(val, total)
	if val == nil then
		return nil
	elseif val <= 1 then
		return math.floor(total * val)
	end
	return math.floor(val)
end

local function open_float(buf, opts)
	opts = opts or {}
	local total_w = vim.o.columns
	local total_h = vim.o.lines
	local width = resolve_dim(opts.width, total_w) or math.floor(total_w * 0.8)
	local height = resolve_dim(opts.height, total_h) or math.floor(total_h * 0.6)
	local row = math.floor((total_h - height) / 2)
	local col = math.floor((total_w - width) / 2)

	return vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		border = opts.border or "rounded",
	})
end

local function show_in_window(window, buf)
	local wtype, opts = window, {}
	if type(window) == "table" then
		wtype, opts = window.type, window
	end

	if wtype == nil or wtype == "current" then
		vim.api.nvim_win_set_buf(0, buf)
	elseif wtype == "split" then
		vim.cmd("belowright split")
		vim.api.nvim_win_set_buf(0, buf)
	elseif wtype == "vsplit" then
		vim.cmd("belowright vsplit")
		vim.api.nvim_win_set_buf(0, buf)
	elseif wtype == "float" then
		open_float(buf, opts)
	else
		error("possess: unknown window type " .. tostring(wtype))
	end
end

local function find_win_for_buf(buf)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
			return win
		end
	end
end

function M.init_buf(def)
	def = def or {}
	local name = def.name
	if not name then
		error("possess.init_buf: missing buffer name")
	end

	local existing = vim.fn.bufnr(name)
	if existing ~= -1 and vim.api.nvim_buf_is_valid(existing) then
		local win = find_win_for_buf(existing)
		if win then
			vim.api.nvim_set_current_win(win)
		else
			show_in_window(def.window, existing)
		end
		return
	end

	local buf = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_buf_set_name(buf, name)
	show_in_window(def.window, buf)

	if def.fn then
		def.fn(buf)
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
