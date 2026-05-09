-- [nfnl] fnl/conjure-spec/tree-sitter-completions_spec.fnl
local _local_1_ = require("plenary.busted")
local describe = _local_1_.describe
local it = _local_1_.it
local before_each = _local_1_.before_each
local after_each = _local_1_.after_each
local assert = require("luassert.assert")
local res = require("conjure.resources")
local ts = require("conjure.tree-sitter")
local tsc = require("conjure.tree-sitter-completions")
local saved_get_resource_contents = nil
local saved_parse_21 = nil
local saved_query_parse = nil
local saved_language_inspect = nil
local saved_get_node = nil
local function _2_()
  local function _3_()
    local filter = tsc["make-prefix-filter"]("aa")
    return assert.same({"aaa"}, filter({"aaa", "bbb", "abb"}))
  end
  it("filters to aaa from aaa bbb abb with prefix aa", _3_)
  local function _4_()
    local filter = tsc["make-prefix-filter"]("%")
    return assert.same({"%thing"}, filter({"aaa", "%thing", "b%b"}))
  end
  it("filters to %thing from aaa %thing b%b with prefix %", _4_)
  local function _5_()
    local filter = tsc["make-prefix-filter"](nil)
    return assert.same({"aaa", "word", "2342"}, filter({"aaa", "word", "2342"}))
  end
  return it("filters nothing from aaa word 2342 with prefix nil", _5_)
end
describe("make-prefix-filter", _2_)
local function _6_()
  local function _7_()
    saved_get_resource_contents = res["get-resource-contents"]
    saved_parse_21 = ts["parse!"]
    saved_query_parse = vim.treesitter.query.parse
    saved_language_inspect = vim.treesitter.language.inspect
    saved_get_node = vim.treesitter.get_node
    return nil
  end
  before_each(_7_)
  local function _8_()
    res["get-resource-contents"] = saved_get_resource_contents
    ts["parse!"] = saved_parse_21
    vim.treesitter.query["parse"] = saved_query_parse
    vim.treesitter.language["inspect"] = saved_language_inspect
    vim.treesitter["get_node"] = saved_get_node
    return nil
  end
  after_each(_8_)
  local function _9_()
    local function _10_(_)
      return "(query)"
    end
    res["get-resource-contents"] = _10_
    local function _11_(_)
      return error("language not found")
    end
    vim.treesitter.language["inspect"] = _11_
    local function _12_(_, _0)
      return error("query parse should not be called")
    end
    vim.treesitter.query["parse"] = _12_
    return assert.same({}, tsc["get-completions-at-cursor"]("missing-test-lang", "missing-test-resource"))
  end
  it("returns no completions when the tree-sitter language is unavailable", _9_)
  local function _13_()
    local function _14_(_)
      return "(query)"
    end
    res["get-resource-contents"] = _14_
    local function _15_(_)
      return {}
    end
    vim.treesitter.language["inspect"] = _15_
    local function _16_(_, _0)
      return {}
    end
    vim.treesitter.query["parse"] = _16_
    local function _17_()
      return nil
    end
    ts["parse!"] = _17_
    local function _18_()
      return error("get_node should not be called")
    end
    vim.treesitter["get_node"] = _18_
    return assert.same({}, tsc["get-completions-at-cursor"]("parse-fail-test-lang", "parse-fail-test-resource"))
  end
  return it("returns no completions when parsing the current buffer fails", _13_)
end
return describe("get-completions-at-cursor", _6_)
