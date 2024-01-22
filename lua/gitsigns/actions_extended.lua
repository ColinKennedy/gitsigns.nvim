local Hunks = require('gitsigns.hunks')
local actions = require("gitsigns.actions")
local async = require("gitsigns.async")
local gs_cache = require('gitsigns.cache')

local api = vim.api
local cache = gs_cache.cache
local current_buf = vim.api.nvim_get_current_buf

local M = {}

local function _get_head_hunks()
  local bufnr = current_buf()
  local bcache = cache[bufnr]

  if not bcache then
    return nil
  end

  local greedy = false

  local hunks = {}
  vim.list_extend(hunks, actions.get_hunks(bufnr, bcache, greedy, false) or {})
  local hunks_head = actions.get_hunks(bufnr, bcache, greedy, true) or {}
  vim.list_extend(hunks, Hunks.filter_common(hunks_head, bcache.hunks) or {})

  return hunks or nil
end

local function _get_hunk_range(hunk)
  local start = nil
  local count = nil

  if hunk.added ~= nil
  then
    start = hunk.added.start
    count = hunk.added.count
  end

  if hunk.removed ~= nil
  then
    if hunk.removed.start < start
    then
      start = hunk.removed.start
    end

    if hunk.removed.count > count
    then
      count = hunk.removed.count
    end
  end

  return {start, start + count}
end

function M.has_next_hunk(forwards)
  local hunks = _get_head_hunks() or {}

  if vim.tbl_isempty(hunks) then
    return false
  end

  local line = api.nvim_win_get_cursor(0)[1]
  local wrap = false
  local hunk, _ = Hunks.find_nearest_hunk(line, hunks, forwards, wrap)

  if hunk == nil then
    return false
  end

  return true
end

function M.in_hunk()
  local hunks = _get_head_hunks() or {}

  if vim.tbl_isempty(hunks) then
    return false
  end

  local line = api.nvim_win_get_cursor(0)[1]

  for index = 1, #hunks do
    local hunk = hunks[index]
    local start_line, end_line = unpack(_get_hunk_range(hunk))

    if line >= start_line and line <= end_line
    then
      return true
    end
  end

  return false
end

M.move_to_first_hunk = async.void(function(opts, forwards)
  async.scheduler_if_buf_valid(current_buf())

  local hunks = _get_head_hunks() or {}

  if vim.tbl_isempty(hunks)
  then
      return
  end

  local hunk = hunks[1]
  local line = hunk.added.start or hunk.removed.start

  vim.api.nvim_win_set_cursor(0, {line, 0})
end)

return M
