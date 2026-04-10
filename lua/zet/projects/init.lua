-- Project subsystem orchestration and commands
local M = {}

local scanner = require("zet.projects.scanner")

--- Scan and show open projects via Telescope
function M.scan()
    local cfg = require("zet.config").get()
    local paths = cfg.scan_dirs or { cfg.home }

    scanner.scan_paths(paths)

    local telescope_projects = require("zet.projects.telescope")
    telescope_projects.project_picker({
        prompt_title = "Open Projects",
    })
end

--- Scan and show all projects (open + checked)
function M.scan_all()
    local cfg = require("zet.config").get()
    local paths = cfg.scan_dirs or { cfg.home }

    scanner.scan_paths_all(paths)

    local telescope_projects = require("zet.projects.telescope")
    telescope_projects.project_picker({
        prompt_title = "All Projects",
    })
end

--- Setup project autocmds
function M.setup()
    local cfg = require("zet.config").get()
    if not cfg.projects or not cfg.projects.enabled then
        return
    end

    require("zet.projects.autocmds").setup_autocmds()
end

return M
