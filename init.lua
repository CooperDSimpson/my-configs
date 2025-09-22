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
vim.opt.signcolumn = "auto"
vim.opt.numberwidth = 1
vim.opt.whichwrap:append('<,>')
vim.opt.relativenumber = false -- optional: if you want absolute numbers

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
  {"lukas-reineke/indent-blankline.nvim"  },

  -- File explorer
  { "terrortylor/nvim-comment" },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" }
  },

  -- Theme & syntax
  {
  "projekt0n/github-nvim-theme",
  lazy = false, -- load immediately so the colorscheme is available
  priority = 1000, -- make sure it loads before other UI plugins
  config = function()
    require("github-theme").setup({
      options = {
        transparent = false,
        terminal_colors = true,
      },
    })
    vim.cmd("colorscheme github_dark_high_contrast")
  end,
},

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

require("ibl").setup({
})

-- which-key setup
require("which-key").setup({
  plugins = { marks = true, registers = true },
  win = { border = "single", position = "bottom" },
  layout = { align = "center", height = { min = 4, max = 10 }, width = { min = 20, max = 50 }, spacing = 10 },
})

require("github-theme").setup({
  options = {
    -- You can tweak here
    transparent = false,
    terminal_colors = true,
  }
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



--Disable Tree-sitter for significant changes (required for smooth to line)
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






