-- luacheck: globals vim
-- Plugin definitions

-- Load local config for feature flags (if exists)
local local_config = {}
pcall(function()
  local_config = require('local')
end)

-- Helper to check if feature is enabled (default true for backward compatibility)
local function is_enabled(feature)
  if local_config[feature] == nil then
    return true  -- Default enabled if not specified
  end
  return local_config[feature]
end

local plugins = {
  -- Dashboard (optional)
  is_enabled('enable_dashboard') and {
    'nvimdev/dashboard-nvim',
    event = 'VimEnter',
    config = function()
      require('dashboard').setup {
        theme = 'hyper',
        config = {
          week_header = {
            enable = true,
          },
          project = {
            enable = true,
            limit = 8,
            icon = '󰉋 ',
            label = ' Recent Projects:',
            action = function(path)
              vim.cmd('cd ' .. path)
            end
          },
          shortcut = {
            {
              desc = '󰊳 Update',
              group = '@property',
              action = 'Lazy update',
              key = 'u'
            },
            {
              icon = ' ',
              icon_hl = '@variable',
              desc = 'Files',
              group = 'Label',
              action = 'Telescope find_files',
              key = 'f',
            },
          },
        },
      }
    end,
    dependencies = { { 'nvim-tree/nvim-web-devicons' } }
  } or nil,

  -- Catppuccin colorscheme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      transparent_background = true,
      integrations = {
        lualine = true,
      },
    },
  },

  -- Tokyo Night colorscheme
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      style = "night", -- storm, moon, night, day
      transparent = true,
      terminal_colors = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },

  -- OKLCH Color Picker (optional, requires GUI)
  is_enabled('enable_colorpicker') and {
    "eero-lehtinen/oklch-color-picker.nvim",
    event = "VeryLazy",
    version = "*",
    keys = {
      {
        "<leader>v",
        function() require("oklch-color-picker").pick_under_cursor() end,
        desc = "Color pick under cursor",
      },
    },
    opts = {},
  } or nil,

  -- Lualine (status bar)
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- Ensure functions are available before setup
      if not _G.CodeStatsXP then
        _G.CodeStatsXP = function() return '' end
      end
      if not _G.GamifyStreak then
        _G.GamifyStreak = function() return '' end
      end

      local custom_theme = require("lualine.themes.catppuccin")

      -- Set custom background color #42455A for all sections
      for _, mode in pairs(custom_theme) do
        if mode.c then
          mode.c.bg = '#42455A'
        end
      end

      -- Replace blue #7FA1E3 with purple #BE94F9 in mode sections
      if custom_theme.normal and custom_theme.normal.a then
        custom_theme.normal.a.bg = '#BE94F9'
        custom_theme.normal.a.fg = '#1e1e2e'
      end

      local ok, err = pcall(function()
        require('lualine').setup({
          options = {
            theme = custom_theme,
            icons_enabled = true,
            component_separators = { left = '', right = '' },
            section_separators = { left = '', right = '' },
          },
          sections = {
            lualine_a = { 'mode' },
            lualine_b = { 'branch', 'diff', 'diagnostics' },
            lualine_c = { 'filename' },
            lualine_x = (function()
            local sections = {
              {
                function()
                  -- Code::Stats XP (always enabled)
                  local ok, result = pcall(_G.CodeStatsXP)
                  return ok and result or ''
                end,
                color = { fg = '#F9E2AF', gui = 'bold' } -- Modern yellow with bold
              },
            }

            -- Add Gamify streak only if enabled
            local ok, local_config = pcall(require, 'local')
            if not ok or local_config.enable_gamify ~= false then
              table.insert(sections, {
                function()
                  local ok2, result = pcall(_G.GamifyStreak)
                  return ok2 and result or ''
                end,
                color = { fg = '#E4DDA3' } -- Custom streak color (lighter)
              })
            end

            -- Add standard components
            table.insert(sections, 'encoding')
            table.insert(sections, 'fileformat')
            table.insert(sections, 'filetype')

            return sections
          end)(),
            lualine_y = { 'progress' },
            lualine_z = { 'location' }
          },
        })
      end)

      if not ok then
        vim.notify('Lualine setup failed: ' .. tostring(err), vim.log.levels.ERROR)
      end
    end,
  },

  -- Barbar (buffer tabs)
  {
    'romgrk/barbar.nvim',
    dependencies = {
      'lewis6991/gitsigns.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    init = function()
      vim.g.barbar_auto_setup = false
    end,
    config = function()
      require('barbar').setup({
        animation = true,
        auto_hide = 1, -- Hide tabline when only one buffer is open
        icons = {
          preset = 'default',
          separator = { left = '', right = '' },
          button = '',
        },
        hide = {
          extensions = true,
          inactive = false,
        },
        focus_on_close = 'left',
        semantic_letters = true,
        maximum_padding = 1,
        minimum_padding = 1,
        sidebar_filetypes = {
          ['mini-files'] = true,
        },
      })

      -- Custom colors: dim grey background, purple bottom border for active tab
      local dim_grey = '#1e1e2e' -- Very dim grey
      local purple = '#BE94F9'   -- Purple for active tab bottom border
      local bg = '#11111b'       -- Darker background for tabline

      -- Set custom highlights for barbar
      vim.api.nvim_set_hl(0, 'BufferCurrent', { bg = dim_grey, fg = '#cdd6f4', underline = true, sp = purple })
      vim.api.nvim_set_hl(0, 'BufferCurrentIndex', { bg = dim_grey, fg = purple, underline = true, sp = purple })
      vim.api.nvim_set_hl(0, 'BufferCurrentMod', { bg = dim_grey, fg = '#f9e2af', underline = true, sp = purple })
      vim.api.nvim_set_hl(0, 'BufferCurrentSign', { bg = dim_grey, fg = purple, underline = true, sp = purple })
      vim.api.nvim_set_hl(0, 'BufferCurrentTarget', { bg = dim_grey, fg = '#f38ba8', underline = true, sp = purple })

      vim.api.nvim_set_hl(0, 'BufferVisible', { bg = bg, fg = '#7f849c' })
      vim.api.nvim_set_hl(0, 'BufferVisibleIndex', { bg = bg, fg = '#7f849c' })
      vim.api.nvim_set_hl(0, 'BufferVisibleMod', { bg = bg, fg = '#f9e2af' })
      vim.api.nvim_set_hl(0, 'BufferVisibleSign', { bg = bg, fg = '#7f849c' })
      vim.api.nvim_set_hl(0, 'BufferVisibleTarget', { bg = bg, fg = '#f38ba8' })

      vim.api.nvim_set_hl(0, 'BufferInactive', { bg = bg, fg = '#585b70' })
      vim.api.nvim_set_hl(0, 'BufferInactiveIndex', { bg = bg, fg = '#585b70' })
      vim.api.nvim_set_hl(0, 'BufferInactiveMod', { bg = bg, fg = '#f9e2af' })
      vim.api.nvim_set_hl(0, 'BufferInactiveSign', { bg = bg, fg = '#585b70' })
      vim.api.nvim_set_hl(0, 'BufferInactiveTarget', { bg = bg, fg = '#f38ba8' })

      vim.api.nvim_set_hl(0, 'BufferTabpageFill', { bg = bg })
      vim.api.nvim_set_hl(0, 'BufferTabpages', { bg = bg, fg = '#7f849c' })
    end,
    version = '^1.0.0',
  },

  -- Auto-session - auto-save and auto-restore sessions per directory
  {
    "rmagatti/auto-session",
    lazy = false,
    opts = {
      suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" }, -- Don't create sessions in these dirs
      auto_save = true, -- Auto-save session on exit
      auto_restore = true, -- Auto-restore session when opening nvim in a project dir
      auto_create = false, -- Don't auto-create session (only save when you have files open)
      session_lens = {
        load_on_setup = false, -- Don't load session-lens picker
      },
      cwd_change_handling = false, -- Disable to avoid conflicts with cd-project position restoration
    },
    config = function(_, opts)
      require("auto-session").setup(opts)

      -- Clean up empty unnamed buffers after session restore
      vim.api.nvim_create_autocmd("SessionLoadPost", {
        callback = function()
          vim.defer_fn(function()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              local ok, name = pcall(vim.api.nvim_buf_get_name, buf)
              if ok and vim.api.nvim_buf_is_loaded(buf) and name == '' then
                local ok2, buftype = pcall(vim.api.nvim_get_option_value, 'buftype', { buf = buf })
                local ok3, ft = pcall(vim.api.nvim_get_option_value, 'filetype', { buf = buf })
                if ok2 and ok3 and buftype == '' and ft == '' then
                  pcall(vim.api.nvim_buf_delete, buf, { force = false })
                end
              end
            end
          end, 100)
        end,
      })
    end,
    init = function()
      -- Recommended sessionoptions for auto-session (without blank to avoid empty buffers)
      vim.o.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
    end,
  },

  -- cd-project.nvim - VSCode-like project manager with manual project saving
  {
    "LintaoAmons/cd-project.nvim",
    config = function()
      require("cd-project").setup({
        projects_config_filepath = vim.fn.stdpath("config") .. "/cd-project.nvim.json",
        project_dir_pattern = { ".git", ".gitignore", "Cargo.toml", "package.json", "go.mod", "composer.json" },
        choice_format = "both", -- Show both name and path
        projects_picker = "telescope",
        auto_register_project = false, -- Only manually saved projects
        -- Disable position restoration to avoid barbar conflicts
        use_file_history_after_cd = false,
      })
    end,
  },

  -- Telescope fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-frecency.nvim",
    },
    config = function()
      require('telescope').setup({
        defaults = {
          layout_strategy = 'horizontal',
          layout_config = {
            horizontal = {
              prompt_position = 'top',
              preview_width = 0.55,
            },
            width = 0.87,
            height = 0.80,
            preview_cutoff = 120,
          },
          sorting_strategy = 'ascending',
          file_ignore_patterns = { "node_modules", ".git/" },
        },
      })
      require('telescope').load_extension('frecency')
    end,
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "Live Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",    desc = "Buffers" },
    },
  },

  -- Telescope frecency extension for recent files
  {
    "nvim-telescope/telescope-frecency.nvim",
    dependencies = { "kkharji/sqlite.lua" },
  },

  -- Project management
  -- Gamify.nvim - Gamifies coding with achievements (optional)
  is_enabled('enable_gamify') and {
    "GrzegorzSzczepanek/gamify.nvim",
    lazy = false,
    config = function()
      require("gamify")
      -- Add streak to airline statusline
      vim.g.gamify_show_streak = 1
    end,
  } or nil,

  -- Gitsigns - Git signs in gutter, inline blame, hunk actions
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require('gitsigns').setup({
        signs = {
          add          = { text = '┃' },
          change       = { text = '┃' },
          delete       = { text = '_' },
          topdelete    = { text = '‾' },
          changedelete = { text = '~' },
          untracked    = { text = '┆' },
        },
        current_line_blame = true,
        current_line_blame_opts = {
          delay = 0,
          virt_text_pos = 'eol',
        },
        current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map('n', ']c', function()
            if vim.wo.diff then return ']c' end
            vim.schedule(function() gs.next_hunk() end)
            return '<Ignore>'
          end, { expr = true, desc = "Next hunk" })

          map('n', '[c', function()
            if vim.wo.diff then return '[c' end
            vim.schedule(function() gs.prev_hunk() end)
            return '<Ignore>'
          end, { expr = true, desc = "Previous hunk" })

          -- Actions
          map('n', '<leader>hs', gs.stage_hunk, { desc = "Stage hunk" })
          map('n', '<leader>hr', gs.reset_hunk, { desc = "Reset hunk" })
          map('v', '<leader>hs', function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end, { desc =
          "Stage hunk" })
          map('v', '<leader>hr', function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end, { desc =
          "Reset hunk" })
          map('n', '<leader>hS', gs.stage_buffer, { desc = "Stage buffer" })
          map('n', '<leader>hu', gs.undo_stage_hunk, { desc = "Undo stage hunk" })
          map('n', '<leader>hR', gs.reset_buffer, { desc = "Reset buffer" })
          map('n', '<leader>hp', gs.preview_hunk, { desc = "Preview hunk" })
          map('n', '<leader>hb', function() gs.blame_line { full = true } end, { desc = "Blame line" })
          map('n', '<leader>hd', gs.diffthis, { desc = "Diff this" })
          map('n', '<leader>hD', function() gs.diffthis('~') end, { desc = "Diff this ~" })
          map('n', '<leader>td', gs.toggle_deleted, { desc = "Toggle deleted" })

          -- Text object
          map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = "Select hunk" })
        end
      })
    end,
  },

  -- mini.files - Lightweight file explorer
  {
    'echasnovski/mini.files',
    version = '*',
    config = function()
      require('mini.files').setup({
        windows = {
          preview = true,
          width_focus = 30,
          width_preview = 30,
        },
        options = {
          use_as_default_explorer = false, -- Don't auto-open when opening directories
        },
      })
    end,
  },

  -- Which-key - Shows keybindings
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.setup({
        plugins = {
          marks = true,
          registers = true,
          spelling = {
            enabled = true,
            suggestions = 20,
          },
        },
        icons = {
          breadcrumb = "»",
          separator = "➜",
          group = "+",
        },
        win = {
          border = "rounded",
        },
      })

      -- Register group names
      wk.add({
        { "<leader>f", group = "Find" },
        { "<leader>h", group = "Git Hunks" },
        { "<leader>q", group = "Session" },
        { "<leader>t", group = "Toggle" },
      })
    end,
    keys = {
      { "<leader>?", function() require("which-key").show({ global = false }) end, desc = "Buffer Local Keymaps" },
    },
  },

  -- Discord Rich Presence (optional)
  is_enabled('enable_discord') and {
    "andweeb/presence.nvim",
    config = function()
      require("presence").setup({
        -- General options
        neovim_image_text = "Neovim",
        main_image = "neovim",

        -- Hide file and project details, show generic messages
        editing_text = "Coding",
        file_explorer_text = "Browsing files",
        git_commit_text = "Committing changes",
        plugin_manager_text = "Managing plugins",
        reading_text = "Reading",
        workspace_text = "Working on a project",
        line_number_text = "Line %s out of %s",

        -- Hide file name and type
        enable_line_number = false,
        show_time = true,
      })
    end,
  } or nil,

  -- Notification plugin
  {
    "rcarriga/nvim-notify",
    config = function()
      require("notify").setup({
        background_colour = "#000000",
      })
      vim.notify = require("notify")
    end,
  },

  -- Linting
  {
    "mfussenegger/nvim-lint",
    dependencies = { "rcarriga/nvim-notify" },
    config = function()
      local lint = require('lint')

      -- Build linters_by_ft dynamically based on enabled linters
      lint.linters_by_ft = {}

      if is_enabled('enable_phpcs') then
        lint.linters_by_ft.php = { 'phpcs' }
      end

      if is_enabled('enable_stylelint') then
        lint.linters_by_ft.css = { 'stylelint' }
        lint.linters_by_ft.scss = { 'stylelint' }
      end

      if is_enabled('enable_flake8') then
        lint.linters_by_ft.python = { 'flake8' }
      end

      if is_enabled('enable_luacheck') then
        lint.linters_by_ft.lua = { 'luacheck' }
      end

      if is_enabled('enable_jsonlint') then
        lint.linters_by_ft.json = { 'jsonlint' }
      end

      if is_enabled('enable_eslint') then
        lint.linters_by_ft.javascript = { 'eslint' }
      end

      -- Helper function to find project root
      local function find_project_root(start_path, markers)
        local path = start_path
        while path ~= '/' do
          for _, marker in ipairs(markers) do
            local full_path = path .. '/' .. marker
            if vim.fn.filereadable(full_path) == 1 or vim.fn.isdirectory(full_path) == 1 then
              return path
            end
          end
          path = vim.fn.fnamemodify(path, ':h')
        end
        return nil
      end

      -- Wrap linting to set proper working directory
      local original_try_lint_before_wrap = lint.try_lint
      lint.try_lint = function(...)
        -- Save current directory
        local saved_cwd = vim.fn.getcwd()

        -- Try to find project root and change to it
        local buffer_dir = vim.fn.expand('%:p:h')
        local ft = vim.bo.filetype

        if ft == 'php' and is_enabled('enable_phpcs') then
          local project_root = find_project_root(buffer_dir, {'phpcs.xml', 'phpcs.xml.dist', 'vendor'})
          if project_root then
            vim.cmd('cd ' .. vim.fn.fnameescape(project_root))
          end
        elseif (ft == 'javascript' or ft == 'typescript' or ft == 'javascriptreact' or ft == 'typescriptreact')
               and is_enabled('enable_eslint') then
          local project_root = find_project_root(buffer_dir, {'node_modules', 'package.json'})
          if project_root then
            vim.cmd('cd ' .. vim.fn.fnameescape(project_root))
          end
        end

        -- Call original try_lint
        original_try_lint_before_wrap(...)

        -- Restore directory
        vim.cmd('cd ' .. vim.fn.fnameescape(saved_cwd))
      end

      -- Installation instructions for each linter
      local linter_install_cmds = {
        phpcs = "composer global require squizlabs/php_codesniffer",
        stylelint = "npm install -g stylelint",
        flake8 = "pip install flake8",
        luacheck = "luarocks install luacheck",
        jsonlint = "npm install -g jsonlint",
        eslint = "npm install -g eslint",
      }

      -- Track notified missing linters to avoid spam
      local notified_linters = {}

      -- Override try_lint to suppress error messages and show notifications instead
      local original_try_lint = lint.try_lint
      lint.try_lint = function(...)

        -- Temporarily override vim.notify to intercept nvim-lint errors
        local original_notify = vim.notify
        local captured_error = nil

        vim.notify = function(msg, level, opts)
          if type(msg) == "string" and msg:match("Error running") and msg:match("ENOENT") then
            captured_error = msg
          else
            original_notify(msg, level, opts)
          end
        end

        -- Run the linter
        pcall(original_try_lint, ...)

        -- Restore vim.notify
        vim.notify = original_notify

        -- Show custom notification if we captured an error
        if captured_error then
          local linter = captured_error:match("Error running ([^:]+):")
          if linter and not notified_linters[linter] then
            local install_cmd = linter_install_cmds[linter] or "Check documentation for installation"
            vim.notify(
              string.format("Linter '%s' is not installed\nInstall: %s", linter, install_cmd),
              vim.log.levels.WARN,
              { title = "Missing linter" }
            )
            notified_linters[linter] = true
          end
        end
      end

      -- Run linter on file open, edit, and save (only if at least one linter is enabled)
      local has_any_linter = is_enabled('enable_phpcs') or is_enabled('enable_stylelint') or
                              is_enabled('enable_flake8') or is_enabled('enable_luacheck') or
                              is_enabled('enable_jsonlint') or is_enabled('enable_eslint')

      if has_any_linter then
        vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "TextChanged", "TextChangedI" }, {
          callback = function()
            lint.try_lint()
          end,
        })
      end
    end,
  },

  -- Auto-formatting on save
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          css = { "stylelint", "prettier" },  -- Run stylelint --fix first, then prettier
          scss = { "stylelint", "prettier" }, -- Run stylelint --fix first, then prettier
          javascript = { "prettier" },
          typescript = { "prettier" },
          json = { "prettier" },
          html = { "prettier" },
          markdown = { "prettier" },
          lua = { "stylua" },
          python = { "black" },
        },
        formatters = {
          stylelint = {
            command = "npx",
            args = { "stylelint", "--fix", "$FILENAME" },
            stdin = false,
            cwd = require("conform.util").root_file({
              ".stylelintrc", ".stylelintrc.json",
              "stylelint.config.js", "package.json"
            }),
          },
        },
        format_on_save = {
          lsp_format = "fallback",
          timeout_ms = 300000, -- 5 minutes - effectively unlimited for large files
        },
      })
    end,
  },

  -- Indent guides
  {
    "nvimdev/indentmini.nvim",
    config = function()
      require("indentmini").setup({
        char = "│",
        only_current = false, -- Show all indent lines
      })
      -- Set highlight colors (Dracula purple theme with more subtle ghost lines)
      vim.cmd.highlight('IndentLine guifg=#282a36')        -- Very dim ghost lines (more subtle)
      vim.cmd.highlight('IndentLineCurrent guifg=#bd93f9') -- Dracula purple for current scope
    end,
  },

  -- Inline diagnostics
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    config = function()
      require("tiny-inline-diagnostic").setup({
        options = {
          show_all_diags_on_cursorline = true,
        }
      })
      -- Enable virtual_text to show all diagnostics in file
      vim.diagnostic.config({
        virtual_text = {
          spacing = 4,
          prefix = '●',
        },
        signs = true,
        underline = true,
        update_in_insert = false,
      })
    end,
  },

  -- Trouble - diagnostics panel
  {
    "folke/trouble.nvim",
    lazy = false, -- Load on startup so custom keymaps work
    config = function()
      require("trouble").setup({
        modes = {
          diagnostics = {
            auto_open = false, -- Don't automatically open
            auto_close = true, -- Close when there are no more diagnostics
          },
        },
      })
    end,
  },

  -- Dropbar - winbar with context-aware breadcrumbs
  {
    "Bekaboo/dropbar.nvim",
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make"
    },
  },

  -- Treesitter - better syntax highlighting and code understanding
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master", -- Must specify master branch
    lazy = false,      -- Cannot be lazy-loaded
    build = ":TSUpdate",
    config = function()
      -- Ensure all required directories exist with proper permissions
      local data_dir = vim.fn.stdpath("data")
      local cache_dir = vim.fn.stdpath("cache")

      local required_dirs = {
        data_dir .. "/lazy/nvim-treesitter",
        data_dir .. "/lazy/nvim-treesitter/parser",
        cache_dir .. "/nvim-treesitter",
      }

      for _, dir in ipairs(required_dirs) do
        vim.fn.mkdir(dir, "p")
        -- Verify directory is writable
        if vim.fn.isdirectory(dir) == 0 or vim.fn.filewritable(dir) ~= 2 then
          vim.notify(
            "Warning: Cannot create/write to directory: " .. dir .. "\n" ..
            "Treesitter may fail to install parsers.\n" ..
            "Check permissions with: ls -la " .. vim.fn.fnamemodify(dir, ":h"),
            vim.log.levels.WARN,
            { title = "Treesitter Setup" }
          )
        end
      end

      local ok, err = pcall(function()
        require("nvim-treesitter.configs").setup({
          -- Minimal recommended parsers
          ensure_installed = { "c", "lua", "vim", "vimdoc", "query" },

          -- Auto-install missing parsers when opening files
          auto_install = true,

          -- Deprecated fields (kept for compatibility)
          sync_install = false,
          ignore_install = {},
          modules = {},

          -- Enable treesitter highlighting
          highlight = { enable = true },
        })
      end)

      if not ok then
        vim.notify(
          "Treesitter setup failed: " .. tostring(err) .. "\n" ..
          "You may need to manually run :TSUpdate",
          vim.log.levels.WARN,
          { title = "Treesitter" }
        )
      end
    end,
  },

  -- Blink.cmp - completion plugin
  {
    'saghen/blink.cmp',
    dependencies = { 'rafamadriz/friendly-snippets' },
    version = '1.*',
    opts = function()
      local sources = { 'lsp', 'path', 'snippets', 'buffer' }
      local providers = {}

      -- Add minuet source if AI completion is enabled
      if is_enabled('enable_ai_completion') then
        table.insert(sources, 'minuet')
        providers.minuet = {
          name = 'minuet',
          module = 'minuet.blink',
          score_offset = 100,
        }
      end

      return {
        keymap = { preset = 'default' },
        appearance = {
          nerd_font_variant = 'mono'
        },
        completion = { documentation = { auto_show = true } },
        sources = {
          default = sources,
          providers = providers,
        },
        fuzzy = { implementation = "prefer_rust_with_warning" }
      }
    end,
    opts_extend = { "sources.default" }
  },

  -- Minuet AI - AI completion with OpenRouter
  is_enabled('enable_ai_completion') and {
    'milanglacier/minuet-ai.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'rcarriga/nvim-notify' },
    config = function()
      local secrets = require('secrets')

      require('minuet').setup({
        provider = 'openai_fim_compatible',
        n_completions = 1,
        context_window = 8192,
        provider_options = {
          openai_fim_compatible = {
            api_key = function() return secrets.openrouter_api_key end,
            name = 'OpenRouter',
            end_point = 'https://openrouter.ai/api/v1/completions',
            model = 'anthropic/claude-3.7-sonnet',
            optional = {
              max_tokens = 128,
              top_p = 0.9,
              temperature = 0.2,
            },
          },
        },
      })
    end,
  } or nil,

  -- Simple Neovim AI helper - minimal floating window (no plugin needed)
  {
    "nvim-lua/plenary.nvim", -- For curl
    config = function()
      -- Simple Neovim helper - minimal floating window
      vim.api.nvim_create_user_command("Nv", function()
        vim.ui.input({ prompt = "Ask about Neovim: " }, function(question)
          if not question or question == "" then return end

          -- Create minimal floating window for answer
          local buf = vim.api.nvim_create_buf(false, true)
          local width = math.floor(vim.o.columns * 0.5)
          local height = 15 -- Fixed compact height
          local win = vim.api.nvim_open_win(buf, true, {
            relative = 'editor',
            width = width,
            height = height,
            col = math.floor((vim.o.columns - width) / 2),
            row = math.floor((vim.o.lines - height) / 2),
            style = 'minimal',
            border = 'rounded',
            title = ' Neovim helper ',
            title_pos = 'center',
          })

          -- Set buffer options
          vim.bo[buf].filetype = 'markdown'
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
            'Q: ' .. question,
            '',
            'Waiting for answer...'
          })

          -- Close with q or Esc
          vim.keymap.set('n', 'q', ':q<CR>', { buffer = buf, silent = true })
          vim.keymap.set('n', '<Esc>', ':q<CR>', { buffer = buf, silent = true })

          -- Call OpenRouter API
          local secrets = require('secrets')
          local curl = require('plenary.curl')

          curl.post('https://openrouter.ai/api/v1/chat/completions', {
            headers = {
              ['Content-Type'] = 'application/json',
              ['Authorization'] = 'Bearer ' .. secrets.openrouter_api_key,
              ['HTTP-Referer'] = 'https://github.com/rolle',
            },
            body = vim.json.encode({
              model = 'openrouter/auto',
              messages = {
                { role = 'system', content = 'You are a Neovim expert. Give concise answers with exact commands.' },
                { role = 'user', content = question }
              }
            }),
            callback = vim.schedule_wrap(function(response)
              if response.status ~= 200 then
                vim.api.nvim_buf_set_lines(buf, 2, -1, false, { 'Error: ' .. response.status })
                return
              end

              local data = vim.json.decode(response.body)
              local answer = data.choices[1].message.content
              local tokens = (data.usage.total_tokens or 0)

              -- Format answer
              local lines = { 'Q: ' .. question, '' }
              vim.list_extend(lines, vim.split(answer, '\n'))
              vim.list_extend(lines, { '', '─────────────', 'Tokens: ' .. tokens })

              vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            end)
          })
        end)
      end, {
        desc = "Quick Neovim question",
      })
    end,
    keys = {
      { "<leader>nv", "<cmd>Nv<cr>", mode = "n", desc = "Ask Neovim Question" },
      { "<C-?>", "<cmd>Nv<cr>", mode = "n", desc = "Ask Neovim Question (Ctrl+Shift+? / Cmd+Shift+?)" },
    },
  },

  -- Comment.nvim - toggle comments
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
  },

  -- Leap.nvim - jump to any location with 2-4 keystrokes
  {
    "ggandor/leap.nvim",
    config = function()
      -- Use <leader>s for leap to avoid conflicts with normal 's' command
      vim.keymap.set({'n', 'x', 'o'}, '<leader>s', '<Plug>(leap)')
      vim.keymap.set('n', '<leader>S', '<Plug>(leap-from-window)')
    end,
  },


  -- Mason for managing LSP servers (optional - requires Node.js/npm)
  is_enabled('enable_lsp') and {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  } or nil,

  -- Mason-lspconfig bridge (optional - requires Node.js/npm)
  is_enabled('enable_lsp') and {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",  -- Lua
          "pyright", -- Python
          "ts_ls",   -- JavaScript/TypeScript
          "cssls",   -- CSS
          "jsonls",  -- JSON
          "html",    -- HTML
        },
        automatic_installation = true,
      })
    end,
  } or nil,

  -- LSP Configuration (using modern Neovim 0.11+ API)
  is_enabled('enable_lsp') and {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      -- Get blink.cmp capabilities for LSP
      local capabilities = require('blink.cmp').get_lsp_capabilities()

      -- Configure language servers with blink.cmp capabilities
      vim.lsp.config('*', { capabilities = capabilities })

      -- Configure lua_ls to recognize Neovim and Hammerspoon globals
      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            runtime = {
              version = 'LuaJIT',
            },
            diagnostics = {
              globals = { 'vim', 'hs', 'clickHandler', 'dragHandler', 'cancelHandler' },
              disable = { 'lowercase-global' },
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            telemetry = {
              enable = false,
            },
          },
        },
      })

      -- Disable TypeScript LSP diagnostics (use ESLint instead)
      vim.lsp.config('ts_ls', {
        on_attach = function(client)
          -- Disable all diagnostics from TypeScript LSP
          client.server_capabilities.diagnosticProvider = false
        end,
        handlers = {
          ['textDocument/publishDiagnostics'] = function() end,
        },
      })

      -- Enable language servers using modern vim.lsp.enable
      vim.lsp.enable('lua_ls')
      vim.lsp.enable('pyright')
      vim.lsp.enable('ts_ls')
      vim.lsp.enable('cssls')
      vim.lsp.enable('jsonls')
      vim.lsp.enable('html')
    end,
  } or nil,
}

-- Filter out nil values (from disabled optional features)
local filtered = {}
for _, plugin in pairs(plugins) do
  if plugin ~= nil then
    table.insert(filtered, plugin)
  end
end

return filtered
