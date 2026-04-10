-- Telescope integration for project picker
local M = {}

local has_telescope, _ = pcall(require, "telescope")
if not has_telescope then
    return M
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")

local scanner = require("zet.projects.scanner")
local utils = require("zet.utils")

local function make_display(entry)
    local filename = utils.basename(entry.filename)
    local status = entry.checked and "[x]" or "[ ]"

    local text_width = 50
    local display_text = entry.text
    if #display_text > text_width then
        display_text = display_text:sub(1, text_width - 3) .. "..."
    end

    local displayer = entry_display.create({
        separator = " | ",
        items = {
            { width = 3 },
            { width = text_width },
            { remaining = true },
        },
    })

    return displayer({
        { status, entry.checked and "Comment" or "Title" },
        display_text,
        { filename, "Comment" },
    })
end

function M.project_picker(opts)
    opts = opts or {}
    local projects = scanner.projects or {}

    if #projects == 0 then
        vim.notify("No projects found.", vim.log.levels.INFO)
        return
    end

    pickers.new(opts, {
        prompt_title = opts.prompt_title or "Projects",
        finder = finders.new_table({
            results = projects,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = make_display,
                    ordinal = entry.text,
                    filename = entry.file,
                    lnum = entry.line_number,
                    text = entry.text,
                    checked = entry.checked,
                }
            end,
        }),
        sorter = conf.generic_sorter(opts),
        previewer = conf.grep_previewer(opts),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                if selection then
                    vim.cmd("edit " .. vim.fn.fnameescape(selection.filename))
                    vim.cmd("normal! " .. selection.lnum .. "G")
                end
            end)
            return true
        end,
    }):find()
end

return M
