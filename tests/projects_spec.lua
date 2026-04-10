describe("projects", function()
    local autocmds = require("zet.projects.autocmds")
    local scanner = require("zet.projects.scanner")

    describe("autocmds process_project_line", function()
        -- Access the local function via process_file indirection:
        -- We test the rewrite behavior by setting up a buffer and calling process_file.
        -- But first, test the line-level logic by examining the module's behavior.

        -- We'll test via a buffer round-trip since process_project_line is local
        local function rewrite_line(input)
            -- Create a temp file in a temp dir so process_file recognizes it
            local tmpdir = vim.fn.tempname()
            vim.fn.mkdir(tmpdir, "p")
            local tmpfile = tmpdir .. "/test.md"
            vim.fn.writefile({ input }, tmpfile)

            -- Override config to use our temp dir
            local config = require("zet.config")
            local orig = config.get()
            config.config = vim.tbl_deep_extend("force", {}, orig, {
                home = tmpdir,
                scan_dirs = { tmpdir },
                projects = { enabled = true },
            })

            -- Open the file in a buffer
            vim.cmd("edit " .. vim.fn.fnameescape(tmpfile))
            autocmds.process_file()
            local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)[1]

            -- Cleanup
            vim.cmd("bdelete!")
            vim.fn.delete(tmpfile)
            vim.fn.delete(tmpdir, "rf")
            config.config = orig

            return result
        end

        it("should add checkbox prefix to raw #project line", function()
            local result = rewrite_line("#project migrate off github")
            assert.are.equal("* [ ] #project: migrate off github", result)
        end)

        it("should not change already-formatted unchecked line", function()
            local input = "* [ ] #project: migrate off github"
            local result = rewrite_line(input)
            assert.are.equal(input, result)
        end)

        it("should not change checked line", function()
            local input = "* [x] #project: migrate off github"
            local result = rewrite_line(input)
            assert.are.equal(input, result)
        end)

        it("should handle #project with colon already present", function()
            local result = rewrite_line("#project: migrate off github")
            assert.are.equal("* [ ] #project: migrate off github", result)
        end)

        it("should not touch lines without #project", function()
            local input = "just a normal line of text"
            local result = rewrite_line(input)
            assert.are.equal(input, result)
        end)
    end)

    describe("scanner", function()
        it("should find unchecked projects", function()
            local tmpdir = vim.fn.tempname()
            vim.fn.mkdir(tmpdir, "p")

            vim.fn.writefile({
                "* [ ] #project: migrate off github",
                "* [x] #project: old finished thing",
                "* [ ] #project: learn rust",
                "some other line",
            }, tmpdir .. "/test.md")

            scanner.scan_paths({ tmpdir })

            assert.are.equal(2, #scanner.projects)
            assert.are.equal("migrate off github", scanner.projects[1].text)
            assert.are.equal("learn rust", scanner.projects[2].text)
            assert.is_false(scanner.projects[1].checked)

            vim.fn.delete(tmpdir, "rf")
        end)

        it("should find all projects when include_checked", function()
            local tmpdir = vim.fn.tempname()
            vim.fn.mkdir(tmpdir, "p")

            vim.fn.writefile({
                "* [ ] #project: migrate off github",
                "* [x] #project: old finished thing",
            }, tmpdir .. "/test.md")

            scanner.scan_paths_all({ tmpdir })

            assert.are.equal(2, #scanner.projects)

            vim.fn.delete(tmpdir, "rf")
        end)

        it("should return empty list when no projects", function()
            local tmpdir = vim.fn.tempname()
            vim.fn.mkdir(tmpdir, "p")

            vim.fn.writefile({
                "just some notes",
                "#reminder 2025-01-01T00:00:00Z: do something",
            }, tmpdir .. "/test.md")

            scanner.scan_paths({ tmpdir })

            assert.are.equal(0, #scanner.projects)

            vim.fn.delete(tmpdir, "rf")
        end)
    end)
end)
