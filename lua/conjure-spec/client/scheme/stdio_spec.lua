-- [nfnl] fnl/conjure-spec/client/scheme/stdio_spec.fnl
local _local_1_ = require("conjure.nfnl.module")
local autoload = _local_1_.autoload
local _local_2_ = require("plenary.busted")
local describe = _local_2_.describe
local it = _local_2_.it
local assert = autoload("luassert.assert")
local a = autoload("conjure.nfnl.core")
local scheme = require("conjure.client.scheme.stdio")
local config = autoload("conjure.config")
local mock_stdio = require("conjure-spec.client.scheme.mock-stdio")
local mock_tsc = require("conjure-spec.mock-tree-sitter-completions")
local mock_log = require("conjure-spec.mock-log")
package.loaded["conjure.tree-sitter-completions"] = mock_tsc
package.loaded["conjure.log"] = mock_log
local function _3_()
  package.loaded["conjure.remote.stdio"] = mock_stdio
  local function _4_()
    local function _5_()
      return assert.same({"; (out) number after, with space: 1"}, scheme["format-msg"]({out = "number after, with space: 1"}))
    end
    it("preserves Chez output ending in a space and number", _5_)
    local function _6_()
      return assert.same({"; (out) first line", "; (out) 42"}, scheme["format-msg"](scheme.unbatch({{out = "first line\n"}, {out = "42"}})))
    end
    it("preserves a final numeric line in batched output", _6_)
    local function _7_()
      return assert.same({"42"}, scheme["format-msg"]({out = ";Value: 42"}))
    end
    return it("preserves numeric MIT Scheme values", _7_)
  end
  describe("format-msg", _4_)
  local function _8_()
    local key = "conjure#client#scheme#stdio#value_prefix_pattern"
    local previous = vim.g[key]
    vim.g[key] = false
    local actual = scheme["format-msg"]({out = "number: 1\n42\n"})
    vim.g[key] = previous
    return assert.same({"number: 1", "42"}, actual)
  end
  it("preserves Chez numeric output with value prefixes disabled", _8_)
  local function _9_()
    local function _10_()
      for _, prompt in ipairs({"1 ]=> ", "12 error> "}) do
        for _0, split in ipairs({0, 1, 2, 3}) do
          local msgs = {{out = ("number: 42\n" .. string.sub(prompt, 1, split))}, {out = string.sub(prompt, (split + 1))}}
          local lines = scheme["format-msg"](scheme.unbatch(msgs))
          assert.same({"; (out) number: 42"}, lines)
        end
      end
      return nil
    end
    return it("removes normal and error prompt levels after joining split reads", _10_)
  end
  describe("prompt cleanup", _9_)
  local function _11_()
    return assert.same({"42"}, scheme["format-msg"](scheme.unbatch({{out = ";Value: 42\n\n1 "}, {out = "]=> "}})))
  end
  it("keeps the MIT value as the final result without a prompt blank line", _11_)
  local function _12_()
    local key = "conjure#client#scheme#stdio#prompt_pattern"
    local previous = vim.g[key]
    vim.g[key] = "^> "
    scheme.start()
    local opts = mock_stdio["get-last-opts"]()
    local actual = scheme["format-msg"]({out = "number: 42"})
    scheme.stop()
    vim.g[key] = previous
    assert.same("^> ", opts["prompt-pattern"])
    assert.is_false(opts["preserve-prompt?"])
    return assert.same({"; (out) number: 42"}, actual)
  end
  it("keeps custom prompt stripping in the transport", _12_)
  local function _13_()
    local command_key = "conjure#client#scheme#stdio#command"
    local prompt_key = "conjure#client#scheme#stdio#prompt_pattern"
    local previous_command = vim.g[command_key]
    local previous_prompt = vim.g[prompt_key]
    vim.g[command_key] = "petite"
    vim.g[prompt_key] = "> $?"
    scheme.start()
    local opts = mock_stdio["get-last-opts"]()
    local output = "number after, without space:1\nnumber after, with space: 1\n> "
    local stripped = string.gsub(output, opts["prompt-pattern"], "")
    local actual = scheme["format-msg"]({out = stripped})
    scheme.stop()
    vim.g[command_key] = previous_command
    vim.g[prompt_key] = previous_prompt
    assert.same("petite", opts.cmd)
    assert.same("> $?", opts["prompt-pattern"])
    assert.is_false(opts["preserve-prompt?"])
    return assert.same({"; (out) number after, without space:1", "; (out) number after, with space: 1", "; (out) "}, actual)
  end
  it("preserves the reported output with the original Chez quick-start settings", _13_)
  local function _14_()
    local command_key = "conjure#client#scheme#stdio#command"
    local prompt_key = "conjure#client#scheme#stdio#prompt_pattern"
    local value_key = "conjure#client#scheme#stdio#value_prefix_pattern"
    local previous_command = vim.g[command_key]
    local previous_prompt = vim.g[prompt_key]
    local previous_value = vim.g[value_key]
    vim.g[command_key] = "petite"
    vim.g[prompt_key] = ">+ "
    vim.g[value_key] = false
    scheme.start()
    local opts = mock_stdio["get-last-opts"]()
    local results
    local function _15_(prompt)
      return scheme["format-msg"]({out = string.gsub(("number after, without space:1\nnumber after, with space: 1\n" .. prompt), opts["prompt-pattern"], "")})
    end
    results = a.map(_15_, {"> ", ">> ", ">>> "})
    scheme.stop()
    vim.g[command_key] = previous_command
    vim.g[prompt_key] = previous_prompt
    vim.g[value_key] = previous_value
    assert.is_false(opts["preserve-prompt?"])
    for _, actual in ipairs(results) do
      assert.same({"number after, without space:1", "number after, with space: 1"}, actual)
    end
    return nil
  end
  it("preserves numbers with nested Chez prompts and value prefixes disabled", _14_)
  local function _16_()
    local expected_code = "(some code)"
    local send_calls = {}
    local mock_send
    local function _17_(val)
      return table.insert(send_calls, val)
    end
    mock_send = _17_
    local function _18_(_)
      return true
    end
    scheme["valid-str?"] = _18_
    mock_stdio["set-mock-send"](mock_send)
    scheme.start()
    assert.is_true(mock_stdio["get-last-opts"]()["preserve-prompt?"])
    scheme["eval-str"]({code = expected_code})
    scheme.stop()
    return assert.same({(expected_code .. "\n")}, send_calls)
  end
  it("eval-str sends code to repl when parses", _16_)
  local function _19_()
    local send_calls = {}
    local mock_send
    local function _20_(val)
      return table.insert(send_calls, val)
    end
    mock_send = _20_
    local function _21_(_)
      return false
    end
    scheme["valid-str?"] = _21_
    mock_stdio["set-mock-send"](mock_send)
    scheme.start()
    scheme["eval-str"]({code = "(some invalid form"})
    scheme.stop()
    return assert.same({}, send_calls)
  end
  return it("eval-str does not send code to repl when valid-str? returns false", _19_)
end
local function _22_()
  local function _23_()
    local completion_results = {}
    local completion_callback
    local function _24_(res)
      return table.insert(completion_results, res)
    end
    completion_callback = _24_
    mock_tsc["set-mock-completions"]({})
    scheme.completions({prefix = "dela", cb = completion_callback})
    return assert.same({"delay"}, completion_results[1])
  end
  it("returns delay for prefix dela when no treesitter completions", _23_)
  local function _25_()
    local completion_results = {}
    local completion_callback
    local function _26_(res)
      return table.insert(completion_results, res)
    end
    completion_callback = _26_
    mock_tsc["set-mock-completions"]({"delta", "other"})
    scheme.completions({prefix = "delt", cb = completion_callback})
    return assert.same({"delta"}, completion_results[1])
  end
  it("returns delta for prefix delt when treesitter completion delta and other", _25_)
  local function _27_()
    local completion_results = {}
    local completion_callback
    local function _28_(res)
      return table.insert(completion_results, res)
    end
    completion_callback = _28_
    mock_tsc["set-mock-completions"]({"delay-more"})
    scheme.completions({prefix = "dela", cb = completion_callback})
    return assert.same({"delay-more", "delay"}, completion_results[1])
  end
  it("returns delay-more and delay for prefix dela when treesitter completion delay-more", _27_)
  local function _29_()
    local completion_results = {}
    local completion_callback
    local function _30_(res)
      return table.insert(completion_results, res)
    end
    completion_callback = _30_
    mock_tsc["set-mock-completions"]({"delta"})
    scheme.completions({prefix = nil, cb = completion_callback})
    return assert.same("delta", a["get-in"](completion_results, {1, 1}))
  end
  return it("returns delta as first result for prefix nil when treesitter completion delta", _29_)
end
local function _31_()
  local function _32_()
    config.merge({client = {scheme = {stdio = {enable_completions = false}}}}, {["overwrite?"] = true})
    local completion_results = {}
    local completion_callback
    local function _33_(res)
      return table.insert(completion_results, res)
    end
    completion_callback = _33_
    mock_tsc["set-mock-completions"]({"delay"})
    scheme.completions({prefix = "dela", cb = completion_callback})
    return assert.same({}, completion_results[1])
  end
  it("returns empty list for completions when completions disabled", _32_)
  local function _34_()
    config.merge({client = {scheme = {stdio = {enable_completions = true}}}}, {["overwrite?"] = true})
    local completion_results = {}
    local completion_callback
    local function _35_(res)
      return table.insert(completion_results, res)
    end
    completion_callback = _35_
    mock_tsc["set-mock-completions"]({"delay-more"})
    scheme.completions({prefix = "dela", cb = completion_callback})
    return assert.same({"delay-more", "delay"}, completion_results[1])
  end
  return it("returns delay delay-more for completions when completions enabled and tree sitter completion delay-more", _34_)
end
return describe("conjure.client.scheme.stdio", _3_, describe("completions", _22_), describe("config", _31_))
