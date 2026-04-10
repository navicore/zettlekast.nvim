-- Project scanner: discovers and filters #project lines across vault directories
local M = {}

M.projects = {}

-- Parse a line for a project entry, return description, is_checked
local function parse_project_line(line)
    local is_checked = line:match("%* %[%s?[xX]%s?%]") ~= nil
    local desc = line:match("#project:%s*(.+)")
    return desc, is_checked
end

-- Scan a single file for project lines
local function scan_file(file_path, include_checked)
    local lines = vim.fn.readfile(file_path)
    for i, line in ipairs(lines) do
        local desc, is_checked = parse_project_line(line)
        if desc and (include_checked or not is_checked) then
            table.insert(M.projects, {
                file = file_path,
                line_number = i,
                text = desc,
                checked = is_checked,
            })
        end
    end
end

--- Get scan dirs from zet config
local function get_scan_dirs()
    local cfg = require("zet.config").get()
    return cfg.scan_dirs or { cfg.home }
end

-- Scan all configured paths for open (unchecked) projects
function M.scan_paths(paths)
    paths = paths or get_scan_dirs()
    M.projects = {}
    for _, path in ipairs(paths) do
        local files = vim.fn.globpath(path, "**/*.md", false, true)
        for _, file in ipairs(files) do
            scan_file(file, false)
        end
    end
end

-- Scan all configured paths for all projects (open and checked)
function M.scan_paths_all(paths)
    paths = paths or get_scan_dirs()
    M.projects = {}
    for _, path in ipairs(paths) do
        local files = vim.fn.globpath(path, "**/*.md", false, true)
        for _, file in ipairs(files) do
            scan_file(file, true)
        end
    end
end

return M
