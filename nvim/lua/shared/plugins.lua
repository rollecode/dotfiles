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
          NvimTree = true,
          ['neo-tree'] = { event = 'BufWipeout' },
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
      auto_restore = false, -- Disable auto-restore to prevent conflicts with cd-project
      auto_create = false, -- Don't auto-create session (only save when you have files open)
      session_lens = {
        load_on_setup = false, -- Don't load session-lens picker
      },
      cwd_change_handling = false, -- Disable to avoid conflicts with cd-project position restoration
    },
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
        hooks = {
          {
            callback = function(dir)
              vim.defer_fn(function()
                pcall(function()
                  -- Just refresh neo-tree to new directory
                  vim.cmd('Neotree close')
                  vim.cmd('Neotree show dir=' .. dir)
                end)
              end, 100)
            end
          }
        }
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

  -- Neo-tree - File explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    lazy = false, -- Load on startup so custom keymaps work
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = false,
        popup_border_style = "rounded",
        enable_git_status = true,
        enable_diagnostics = true,
        -- Save state in nvim data directory, not project root
        event_handlers = {
          {
            event = "neo_tree_buffer_enter",
            handler = function()
              vim.opt_local.relativenumber = false
              vim.opt_local.number = false
            end,
          },
        },
        default_component_configs = {
          indent = {
            indent_size = 2,
            padding = 1,
            with_markers = true,
            indent_marker = "│",
            last_indent_marker = "└",
            with_expanders = true,
          },
        },
        window = {
          position = "left",
          width = 30,
          mapping_options = {
            noremap = true,
            nowait = true,
          },
        },
        filesystem = {
          filtered_items = {
            visible = false,
            hide_dotfiles = false,
            hide_gitignored = false,
          },
          follow_current_file = {
            enabled = true,
          },
          use_libuv_file_watcher = true,
          -- Don't create state files in project directories
          bind_to_cwd = false,
          hijack_netrw_behavior = "open_default",
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

      lint.linters_by_ft = {
        php = { 'phpcs' },
        css = { 'stylelint' },
        scss = { 'stylelint' },
        python = { 'flake8' },
        lua = { 'luacheck' },
        json = { 'jsonlint' },
        javascript = { 'eslint' },
      }

      -- Track which ESLint we notified about per project to avoid spam
      local notified_eslint = {}

      -- Dynamically update ESLint command before linting
      local function update_eslint_cmd()
        -- Only run for JavaScript/TypeScript files
        local ft = vim.bo.filetype
        if ft ~= 'javascript' and ft ~= 'typescript' and ft ~= 'javascriptreact' and ft ~= 'typescriptreact' then
          return
        end

        -- Only check if we have an actual file buffer
        local buffer_file = vim.fn.expand('%:p')
        if buffer_file == '' or vim.fn.filereadable(buffer_file) ~= 1 then
          return
        end

        -- Start search from current buffer's directory, not cwd
        local buffer_dir = vim.fn.expand('%:p:h')
        local search_path = buffer_dir .. ';'
        local local_eslint = vim.fn.findfile('node_modules/.bin/eslint', search_path)

        if local_eslint ~= '' then
          -- Found project-local ESLint
          local eslint_path = vim.fn.fnamemodify(local_eslint, ':p')

          -- Get the project root (where node_modules is)
          local project_root = vim.fn.fnamemodify(eslint_path, ':h:h:h')

          -- Set command and working directory
          lint.linters.eslint.cmd = eslint_path
          lint.linters.eslint.cwd = project_root

          if not notified_eslint[project_root] then
            vim.notify(
              'Using project-local ESLint from: ' .. project_root,
              vim.log.levels.INFO,
              { title = 'ESLint' }
            )
            notified_eslint[project_root] = 'local'
          end
        else
          -- Fallback to global ESLint
          lint.linters.eslint.cmd = 'eslint'
          lint.linters.eslint.cwd = vim.fn.getcwd()
          if notified_eslint[buffer_dir] ~= 'global' then
            vim.notify(
              'No project-local ESLint found for this file\nUsing global installation',
              vim.log.levels.WARN,
              { title = 'ESLint' }
            )
            notified_eslint[buffer_dir] = 'global'
          end
        end
      end

      -- Track which phpcs we notified about per project to avoid spam
      local notified_phpcs = {}

      -- Dynamically update phpcs command before linting
      local function update_phpcs_cmd()
        -- Only run for PHP files
        local ft = vim.bo.filetype
        if ft ~= 'php' then
          return
        end

        -- Only check if we have an actual file buffer
        local buffer_file = vim.fn.expand('%:p')
        if buffer_file == '' or vim.fn.filereadable(buffer_file) ~= 1 then
          return
        end

        -- Start search from current buffer's directory
        local buffer_dir = vim.fn.expand('%:p:h')
        local search_path = buffer_dir .. ';'
        local local_phpcs = vim.fn.findfile('vendor/bin/phpcs', search_path)

        if local_phpcs ~= '' then
          -- Found project-local phpcs (composer-installed)
          local phpcs_path = vim.fn.fnamemodify(local_phpcs, ':p')

          -- Get the project root (where vendor/ is)
          local project_root = vim.fn.fnamemodify(phpcs_path, ':h:h:h')

          -- Set command and working directory
          lint.linters.phpcs.cmd = phpcs_path
          lint.linters.phpcs.cwd = project_root

          if not notified_phpcs[project_root] then
            vim.notify(
              'Using project-local phpcs from: ' .. project_root,
              vim.log.levels.INFO,
              { title = 'phpcs' }
            )
            notified_phpcs[project_root] = 'local'
          end
        else
          -- Fallback to global phpcs
          lint.linters.phpcs.cmd = 'phpcs'
          lint.linters.phpcs.cwd = vim.fn.getcwd()
          if notified_phpcs[buffer_dir] ~= 'global' then
            vim.notify(
              'No project-local phpcs found\nUsing global installation (phpcs.xml will be auto-detected)',
              vim.log.levels.INFO,
              { title = 'phpcs' }
            )
            notified_phpcs[buffer_dir] = 'global'
          end
        end
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
        -- Update ESLint command to use project-local if available
        update_eslint_cmd()
        -- Update phpcs command to use project-local if available
        update_phpcs_cmd()

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

      -- Run linter on file open, edit, and save
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "TextChanged", "TextChangedI" }, {
        callback = function()
          lint.try_lint()
        end,
      })
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

  -- Trouble - diagnostics panel (opens automatically)
  {
    "folke/trouble.nvim",
    lazy = false, -- Load on startup so custom keymaps work
    config = function()
      require("trouble").setup({
        modes = {
          diagnostics = {
            auto_open = true,  -- Automatically open when there are diagnostics
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
      -- Ensure parser directory exists (fixes "No such file or directory" error)
      local parser_dir = vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/parser"
      vim.fn.mkdir(parser_dir, "p")

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

      -- Add minuet source if Ollama is enabled
      if is_enabled('enable_ollama') then
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

  -- Minuet AI - AI completion with Ollama (optional, requires GPU)
  is_enabled('enable_ollama') and {
    'milanglacier/minuet-ai.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'rcarriga/nvim-notify' },
    config = function()
      -- Check if ollama is running
      local function check_ollama()
        local handle = io.popen("curl -s http://localhost:11434/api/tags 2>&1")
        local result = handle:read("*a")
        handle:close()
        return result:match("models")
      end

      if not check_ollama() then
        vim.notify(
          "Ollama is not running or not installed\n" ..
          "Install: https://ollama.ai\n" ..
          "Start: ollama serve\n" ..
          "Pull model: ollama pull qwen2.5-coder:7b",
          vim.log.levels.WARN,
          { title = "Minuet AI" }
        )
      end

      require('minuet').setup({
        provider = 'openai_fim_compatible',
        n_completions = 1,
        context_window = 8192, -- Good for RTX 3080 16GB
        provider_options = {
          openai_fim_compatible = {
            api_key = 'TERM',
            name = 'Ollama',
            end_point = 'http://localhost:11434/v1/completions',
            model = 'qwen2.5-coder:7b',
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
      -- Set up keymaps (s to leap, S to leap from any window)
      vim.keymap.set({'n', 'x', 'o'}, 's', '<Plug>(leap)')
      vim.keymap.set('n', 'S', '<Plug>(leap-from-window)')
    end,
  },

  -- Hardtime - learn better Vim motions (optional)
  is_enabled('enable_hardtime') and {
    "m4xshen/hardtime.nvim",
    lazy = false,
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      disable_mouse = false, -- Allow mouse usage including scrolling
    },
  } or nil,

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
