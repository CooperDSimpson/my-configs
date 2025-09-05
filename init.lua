-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- general settings
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.number = true
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.opt.guifont = "JetBrainsMono Nerd Font:h10"
vim.opt.signcolumn = "yes"
vim.opt.whichwrap:append('<,>')

-- Insert-mode line wrapping without inserting characters
vim.keymap.set('i', '<Left>', function()
  if vim.fn.col('.') == 1 then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>gkA', true, false, true), 'n', true)
    return ''
  else
    return '<Left>'
  end
end, {expr = true, noremap = true})

vim.keymap.set('i', '<Right>', function()
  local col = vim.fn.col('.')
  local line_len = vim.fn.col('$') - 1
  if col > line_len then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>gjI', true, false, true), 'n', true)
    return ''
  else
    return '<Right>'
  end
end, {expr = true, noremap = true})

-- setup plugins
require("lazy").setup({
  -- LSP & completion
  { "neovim/nvim-lspconfig" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "saadparwaiz1/cmp_luasnip" },
  { "l3mon4d3/luasnip" },

  -- UI & utilities
  { "nvim-lualine/lualine.nvim" },
  { "junegunn/fzf.vim" },
  { "glepnir/dashboard-nvim" },
  { "echasnovski/mini.nvim" }, 
  { "sbdchd/neoformat" },
  { "mhinz/vim-signify" },
  { "norcalli/nvim-colorizer.lua" },
  { "folke/which-key.nvim" },
  { "ThePrimeagen/harpoon" },
  { "lukas-reineke/indent-blankline.nvim" },

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" }
  },
  { "nvim-tree/nvim-web-devicons" },
  { "terrortylor/nvim-comment" },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" }
  },

  -- Theme & syntax
  { "projekt0n/github-nvim-theme" },

  -- Autopairs
  {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup({
        enable_check_bracket_line = false,
        ignored_next_char = "[%w%.]",
      })
    end,
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "c", "cpp", "lua", "python", "javascript", "java", "html", "xml", "asm" }, 
        indent = { enable = true },
        incremental_selection = { enable = false },
        textobjects = { enable = true },
        playground = { enable = true },
      })
    end,
  }
})

-- comments
require('nvim_comment').setup({
  marker_padding = true,
  comment_empty = false,
  create_mappings = false,
  comment_string = '//',
})

-- nvim-tree setup
require("nvim-tree").setup({
  renderer = {
    icons = {
      show = {
        file = true,
        folder = true,
        folder_arrow = true,
        git = true,
      },
    },
    group_empty = true,
  },
  view = {
    width = 30,
    side = 'right'
  },
  filters = {
    dotfiles = false
  },
  actions = {
    open_file = {
      quit_on_open = true
    }
  },
})

-- lualine setup
require("lualine").setup({
  sections = {
    lualine_c = {
      "filename",
      {
        "diagnostics",
        sources = { "nvim_lsp" }
      },
    },
  },
})

require("indent_blankline").setup({
  char = "│",
  space_char_blankline = " ",
  show_trailing_blankline_indent = false,
  show_first_indent_level = true,
  use_treesitter = true,
  filetype_exclude = {"help", "dashboard", "NvimTree"},
})

-- which-key setup
require("which-key").setup({
  plugins = { marks = true, registers = true },
  win = { border = "single", position = "bottom" },
  layout = { align = "center", height = { min = 4, max = 10 }, width = { min = 20, max = 50 }, spacing = 10 },
})

-- LSP setup
local lspconfig = require("lspconfig")
local cmp_nvim_lsp = require("cmp_nvim_lsp")

lspconfig.clangd.setup({
  cmd = {
    "clangd",
    "--query-driver=" .. "C:/path/to/mingw64/bin/x86_64-w64-mingw32-g++.exe"
  },
  capabilities = cmp_nvim_lsp.default_capabilities(),
  on_attach = function(client, _)
    if client.server_capabilities.semanticTokensProvider then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end,
})

lspconfig.pyright.setup({
  capabilities = cmp_nvim_lsp.default_capabilities(),
  on_attach = function(client, _)
    if client.server_capabilities.semanticTokensProvider then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end,
})

-- nvim-cmp setup
local cmp = require("cmp")
cmp.setup({
  mapping = {
    ["<Tab>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
    ["<S-Tab>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
  },
  sources = {
    { name = "nvim_lsp" },
    { name = "buffer" },
    { name = "path" },
  },
})

-- Autopairs extra rules
local npairs = require("nvim-autopairs")
local rule = require("nvim-autopairs.rule")

npairs.add_rules({
  rule("<", ">", { "cpp", "c", "lua", "python", "javascript", "html", "xml", "java", "asm" })
    :with_pair(function(opts)
      local before_char = opts.line:sub(opts.col - 1, opts.col - 1)
      return before_char ~= " "
    end)
})

-- Diagnostics
vim.diagnostic.config({
  virtual_text = { prefix = '✗', source = 'always', severity = vim.diagnostic.severity.ERROR },
  signs = true,
  underline = true,
  update_in_insert = true,
  severity_sort = true,
})

vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { noremap = true, silent = true })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { noremap = true, silent = true })
vim.keymap.set("n", "e", vim.diagnostic.open_float, { noremap = true, silent = true })

-- Telescope keymaps
vim.keymap.set('n', 'ff', ":Telescope find_files<CR>", { noremap = true, silent = true })
vim.keymap.set('n', 'fg', ":Telescope live_grep<CR>", { noremap = true, silent = true })
vim.keymap.set('n', 'fb', ":Telescope buffers<CR>", { noremap = true, silent = true })
vim.keymap.set('n', 'fh', ":Telescope help_tags<CR>", { noremap = true, silent = true })

-- Cycle nvim-tree keymap
local commands = { "NvimTreeToggle" }
local command_index = 1

function CycleCommands()
  vim.cmd(commands[command_index])
  command_index = (command_index % #commands) + 1
end

vim.keymap.set("n", "<C-n>", ":lua CycleCommands()<CR>", { noremap = true, silent = true })

-- Auto format on save for non-clangd LSPs
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = {"*.cpp","*.h","*.c","*.lua","*.py","*.js","*.java","*.html","*.xml","*.asm"},
  callback = function()
    vim.lsp.buf.format({
      async = false,
      filter = function(client)
        return client.name ~= "clangd"
      end
    })
  end
})

-- Smooth scroll
local is_smooth_scrolling = false
local function smooth_to_line(target_line, duration_ms)
  if is_smooth_scrolling then return end
  is_smooth_scrolling = true

  local start_line = vim.fn.line(".")
  local buf_last = vim.fn.line("$")
  target_line = math.max(1, math.min(target_line, buf_last))
  local distance = target_line - start_line

  if distance == 0 then
    is_smooth_scrolling = false
    return
  end

  local max_steps = 100
  local steps = math.min(math.abs(distance), max_steps)
  local delta = distance / steps
  local interval = duration_ms / steps

  for i = 1, steps do
    vim.defer_fn(function()
      if not is_smooth_scrolling then return end

      local new_line
      if i == steps then
        new_line = target_line
      else
        new_line = math.floor(start_line + delta * i + 0.5)
      end

      local cursor_col = math.min(vim.fn.col("$") - 1, vim.fn.col(".") - 1)
      pcall(vim.api.nvim_win_set_cursor, 0, {new_line, cursor_col})

      if i == steps then
        vim.defer_fn(function() is_smooth_scrolling = false end, 50)
      end
    end, interval * i)
  end
end

vim.keymap.set("n", "gg", function() smooth_to_line(1, 200) end, { noremap = true, silent = true })
vim.keymap.set("n", "G", function() smooth_to_line(vim.fn.line("$"), 200) end, { noremap = true, silent = true })
vim.keymap.set("x", "gg", function() smooth_to_line(1, 200) end, { noremap = true, silent = true })
vim.keymap.set("x", "G", function() smooth_to_line(vim.fn.line("$"), 200) end, { noremap = true, silent = true })

-- Theme
vim.cmd("colorscheme github_dark_high_contrast")

-- Helper function to check if a change is significant
local function is_significant_change()
  local mode = vim.fn.mode()
  if mode == "i" or mode == "R" then
    local col = vim.fn.col(".")
    local line = vim.fn.getline(".")
    if col > #line then
      return false
    end
    local sel = vim.fn.getpos("v")
    if sel[2] ~= sel[3] then
      return true
    else
      return false
    end
  end
  return true
end

-- Disable Tree-sitter for significant changes
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI"}, {
  callback = function()
    if is_significant_change() then
      pcall(vim.treesitter.stop, 0)
    end
  end,
})

-- Re-enable automatically after changes
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWritePost" }, {
  callback = function()
    vim.schedule(function()
      pcall(vim.treesitter.start, 0)
    end)
  end,
})
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    pcall(vim.treesitter.start, 0)
  end,
})

