-- Neovim configuration entry point

local opt = vim.opt
local g = vim.g
local keymap = vim.keymap.set

-- Leader key
g.mapleader = ' '
g.maplocalleader = '\\'

-- UI
opt.number = true
opt.relativenumber = true
opt.signcolumn = 'yes'
opt.cursorline = true
opt.termguicolors = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.showmode = false
opt.laststatus = 3
opt.cmdheight = 0

-- Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

-- Files
opt.undofile = true
opt.swapfile = false
opt.backup = false
opt.updatetime = 100

-- Splits
opt.splitbelow = true
opt.splitright = true

-- Clipboard
opt.clipboard = 'unnamedplus'

-- Completion
opt.completeopt = { 'menu', 'menuone', 'noselect' }
opt.pumheight = 10

-----------------------------------------------------------------------------
-- Keymaps
-----------------------------------------------------------------------------

-- Better escape
keymap('i', 'jk', '<Esc>', { desc = 'Exit insert mode' })

-- Window navigation
keymap('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
keymap('n', '<C-j>', '<C-w>j', { desc = 'Move to lower window' })
keymap('n', '<C-k>', '<C-w>k', { desc = 'Move to upper window' })
keymap('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })

-- Buffer navigation
keymap('n', '<S-h>', ':bprevious<CR>', { desc = 'Prev buffer' })
keymap('n', '<S-l>', ':bnext<CR>', { desc = 'Next buffer' })
keymap('n', '<leader>bd', ':bdelete<CR>', { desc = 'Delete buffer' })

-- Move lines
keymap('n', '<A-j>', ':m .+1<CR>==', { desc = 'Move line down' })
keymap('n', '<A-k>', ':m .-2<CR>==', { desc = 'Move line up' })
keymap('v', '<A-j>', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
keymap('v', '<A-k>', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })

-- Better indenting
keymap('v', '<', '<gv', { desc = 'Indent left' })
keymap('v', '>', '>gv', { desc = 'Indent right' })

-- Paste without overwriting register
keymap('v', 'p', '"_dP', { desc = 'Paste without yanking replaced text' })

-- Delete without yanking
keymap({ 'n', 'v' }, '<leader>d', '"_d', { desc = 'Delete to black hole' })

-- Clear search highlight
keymap('n', '<Esc>', ':nohlsearch<CR>', { desc = 'Clear highlights' })

-- File operations
keymap('n', '<leader>w', ':w<CR>', { desc = 'Save file' })
keymap('n', '<leader>q', ':q<CR>', { desc = 'Quit' })
keymap('n', '<leader>Q', ':qa!<CR>', { desc = 'Force quit all' })

-- Quick fix list
keymap('n', ']q', ':cnext<CR>', { desc = 'Next quickfix' })
keymap('n', '[q', ':cprev<CR>', { desc = 'Prev quickfix' })

-- Diagnostics
keymap('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
keymap('n', '[d', vim.diagnostic.goto_prev, { desc = 'Prev diagnostic' })
keymap('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic' })

-----------------------------------------------------------------------------
-- Autocommands
-----------------------------------------------------------------------------

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Highlight on yank
autocmd('TextYankPost', {
  group = augroup('highlight_yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 150 })
  end,
})

-- Remove trailing whitespace on save
autocmd('BufWritePre', {
  group = augroup('trim_whitespace', { clear = true }),
  pattern = '*',
  callback = function()
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd([[%s/\s\+$//e]])
    vim.api.nvim_win_set_cursor(0, pos)
  end,
})

-- Restore cursor position
autocmd('BufReadPost', {
  group = augroup('restore_cursor', { clear = true }),
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= line_count then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})

-- Load plugins
require('plugins')
