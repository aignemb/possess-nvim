local M = {}

function M.connect(raw, alias)
	alias = alias or raw:match("^[^@]+@(.+)$") or raw
	local mount_path = vim.fn.expand("~/possess/" .. alias)

	vim.fn.mkdir(mount_path, "p")

	vim.fn.system({ "mountpoint", "-q", mount_path })
	if vim.v.shell_error == 0 then
		vim.notify("already mounted at " .. mount_path, vim.log.levels.INFO)
		vim.cmd("cd " .. mount_path)
		return
	end

	local result = vim.fn.system({
		"sshfs",
		"-o", "reconnect,ServerAliveInterval=15,ServerAliveCountMax=3",
		raw .. ":",
		mount_path,
	})
	if vim.v.shell_error ~= 0 then
		error(vim.trim(result))
	end

	vim.notify("mounted " .. raw .. " -> " .. mount_path, vim.log.levels.INFO)
	vim.cmd("cd " .. mount_path)
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

	local cwd = vim.fn.getcwd()
	if vim.startswith(cwd, mount_path) then
		vim.cmd("cd " .. vim.fn.expand("~"))
	end
end

return M
