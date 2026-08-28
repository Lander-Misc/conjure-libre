-- [nfnl] fnl/conjure/tree-sitter.fnl
local _local_1_ = require("conjure.nfnl.module")
local autoload = _local_1_.autoload
local define = _local_1_.define
local a = autoload("conjure.nfnl.core")
local client = autoload("conjure.client")
local config = autoload("conjure.config")
local text = autoload("conjure.text")
local M = define("conjure.tree-sitter")
M["enabled?"] = function()
  local and_2_ = config["get-in"]({"extract", "tree_sitter", "enabled"})
  if and_2_ then
    local ok_3f, parser = pcall(vim.treesitter.get_parser)
    and_2_ = (ok_3f and parser)
  end
  if and_2_ then
    return true
  else
    return false
  end
end
M["parse!"] = function()
  local ok_3f, parser = pcall(vim.treesitter.get_parser)
  if (ok_3f and (nil ~= parser)) then
    return parser:parse()
  else
    return nil
  end
end
M["node->str"] = function(node)
  if node then
    if vim.treesitter.get_node_text then
      return vim.treesitter.get_node_text(node, vim.api.nvim_get_current_buf())
    else
      return vim.treesitter.query.get_node_text(node, vim.api.nvim_get_current_buf())
    end
  else
    return nil
  end
end
M["lisp-comment-node?"] = function(node)
  return text["starts-with"](M["node->str"](node), "(comment")
end
M.parent = function(node)
  if node then
    return node:parent()
  else
    return nil
  end
end
M["document?"] = function(node)
  return not M.parent(node)
end
M.range = function(node)
  if node then
    local sr, sc, er, ec = node:range()
    return {start = {a.inc(sr), sc}, ["end"] = {a.inc(er), a.dec(ec)}}
  else
    return nil
  end
end
M["node->table"] = function(node)
  if (a.get(node, "range") and a.get(node, "content")) then
    return node
  elseif node then
    return {range = M.range(node), content = M["node->str"](node), node = node}
  else
    return nil
  end
end
M["get-root"] = function(node)
  M["parse!"]()
  local node0 = (node or vim.treesitter.get_node())
  local parent_node = M.parent(node0)
  if M["document?"](node0) then
    return nil
  elseif M["document?"](parent_node) then
    return node0
  elseif client["optional-call"]("comment-node?", parent_node) then
    return node0
  else
    return M["get-root"](parent_node)
  end
end
M["leaf?"] = function(node)
  if node then
    return (0 == node:child_count())
  else
    return nil
  end
end
M["sym?"] = function(node)
  if node then
    return (string.find(node:type(), "sym") or (node:type() == "package_lit") or vim.tbl_contains({"field_expression", "scoped_identifier"}, node:type()) or client["optional-call"]("symbol-node?", node))
  else
    return nil
  end
end
M["get-leaf"] = function(node)
  M["parse!"]()
  local node0 = (node or vim.treesitter.get_node())
  if (M["leaf?"](node0) or M["sym?"](node0)) then
    local node1 = node0
    while M["sym?"](M.parent(node1)) do
      node1 = M.parent(node1)
    end
    return node1
  else
    return nil
  end
end
M["node-surrounded-by-form-pair-chars?"] = function(node, extra_pairs)
  local node_str = M["node->str"](node)
  local first_and_last_chars = text["first-and-last-chars"](node_str)
  local function fn_16_(arg_15_)
    local start = arg_15_[1]
    local _end = arg_15_[2]
    return (first_and_last_chars == (start .. _end))
  end
  local or_17_ = a.some(fn_16_, config["get-in"]({"extract", "form_pairs"}))
  if not or_17_ then
    local function fn_19_(arg_18_)
      local start = arg_18_[1]
      local _end = arg_18_[2]
      return (vim.startswith(node_str, start) and vim.endswith(node_str, _end))
    end
    or_17_ = a.some(fn_19_, extra_pairs)
  end
  return (or_17_ or false)
end
M["node-prefixed-by-chars?"] = function(node, prefixes)
  local node_str = M["node->str"](node)
  local function fn_20_(prefix)
    return vim.startswith(node_str, prefix)
  end
  return (a.some(fn_20_, prefixes) or false)
end
M["get-form"] = function(node)
  if not node then
    M["parse!"]()
  else
  end
  local node0 = (node or vim.treesitter.get_node())
  if M["document?"](node0) then
    return nil
  elseif (M["leaf?"](node0) or (false == client["optional-call"]("form-node?", node0))) then
    return M["get-form"](M.parent(node0))
  else
    local _let_22_ = (client["optional-call"]("get-form-modifier", node0) or {})
    local modifier = _let_22_.modifier
    local res = _let_22_
    if (not modifier or ("none" == modifier)) then
      return node0
    elseif ("parent" == modifier) then
      return M["get-form"](M.parent(node0))
    elseif ("node" == modifier) then
      return res.node
    elseif ("raw" == modifier) then
      return res["node-table"]
    else
      a.println("Warning: Conjure client returned an unknown get-form-modifier", res)
      return node0
    end
  end
end
M["add-language"] = function(lang)
  local add
  do
    local case_25_ = vim.treesitter
    if ((_G.type(case_25_) == "table") and ((_G.type(case_25_.language) == "table") and (nil ~= case_25_.language.add))) then
      local f = case_25_.language.add
      add = f
    elseif ((_G.type(case_25_) == "table") and ((_G.type(case_25_.language) == "table") and (nil ~= case_25_.language.require_language))) then
      local f = case_25_.language.require_language
      local function fn_26_(...)
        return pcall(f, ...)
      end
      add = fn_26_
    elseif ((_G.type(case_25_) == "table") and (nil ~= case_25_.require_language)) then
      local f = case_25_.require_language
      local function fn_27_(...)
        return pcall(f, ...)
      end
      add = fn_27_
    else
      add = nil
    end
  end
  return add(lang)
end
local function get_root_node_for_str(lang, code)
  local parser = vim.treesitter.get_string_parser(code, lang)
  parser:parse()
  local trees = parser:trees()
  if (trees and (#trees > 0)) then
    local root_tree = trees[1]
    return root_tree:root()
  else
    return nil
  end
end
M["valid-str?"] = function(lang, code)
  if M["enabled?"]() then
    local root_node = get_root_node_for_str(lang, code)
    return (root_node and not root_node:has_error())
  else
    return true
  end
end
return M
