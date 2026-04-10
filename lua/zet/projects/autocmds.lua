-- Autocommands for project processing: auto-format #project lines on save
local M = {}

-- Rewrite a line containing #project to ensure checkbox markdown prefix
local function process_project_line(line)
    -- Already has checkbox prefix — leave it alone
    if line:match("%* %[%s?[ xX]?%s?%] #project") then
        return line
    end

    -- Raw #project tag — add prefix and colon delimiter
    local desc = line:match("#project[:%s]+(.+)")
    if desc then
        return "* [ ] #project: " .. desc
    end

    return line
end

-- Process all lines in the current buffer
function M.process_file()
    local cfg = require("zet.config").get()
    local current_file = vim.fn.expand("%:p")

    for _, dir in ipairs(cfg.scan_dirs or { cfg.home }) do
        local abs_dir = vim.fn.fnamemodify(dir, ":p")
        if current_file:sub(1, #abs_dir) == abs_dir then
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            for i, line in ipairs(lines) do
                lines[i] = process_project_line(line)
            end
            vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
            break
        end
    end
end

-- Set up autocmds scoped to zet markdown files
function M.setup_autocmds()
    local cfg = require("zet.config").get()
    if not cfg.projects or not cfg.projects.enabled then
        return
    end

    local group = vim.api.nvim_create_augroup("ZetProjects", { clear = true })

    vim.api.nvim_create_autocmd("BufWritePre", {
        group = group,
        pattern = "*.md",
        callback = function()
            M.process_file()
        end,
    })
end

return M
