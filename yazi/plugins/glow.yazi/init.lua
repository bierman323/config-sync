local M = {}

function M:peek(job)
	local child = Command("glow")
		:args({ "-s", "dark", "-w", tostring(job.area.w), tostring(job.file.url) })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()

	local output = child:wait_with_output()
	if output and output.status and output.status.success then
		ya.preview_widgets(self, { ui.Text.parse(output.stdout):area(job.area) })
	else
		require("code"):peek(job)
	end
end

function M:seek(job)
	require("code"):seek(job)
end

return M
