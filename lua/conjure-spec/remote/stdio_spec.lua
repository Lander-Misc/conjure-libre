-- [nfnl] fnl/conjure-spec/remote/stdio_spec.fnl
local _local_1_ = require("plenary.busted")
local describe = _local_1_.describe
local it = _local_1_.it
local assert = require("luassert.assert")
local stdio = require("conjure.remote.stdio")
local function _2_()
  local function _3_()
    local function _4_()
      return assert.same({cmd = "foo", args = {}}, stdio["parse-cmd"]("foo"))
    end
    it("parses a string", _4_)
    local function _5_()
      return assert.same({cmd = "foo", args = {}}, stdio["parse-cmd"]({"foo"}))
    end
    it("parses a list of one string", _5_)
    local function _6_()
      return assert.same({cmd = "foo", args = {"bar", "baz"}}, stdio["parse-cmd"]("foo bar baz"))
    end
    it("parses a string with words separated by spaces", _6_)
    local function _7_()
      return assert.same({cmd = "foo", args = {"bar", "baz"}}, stdio["parse-cmd"]({"foo", "bar", "baz"}))
    end
    return it("parses a list of more than one string", _7_)
  end
  describe("parse-cmd", _3_)
  local function _8_()
    local flag_var = "conjure#stdio#silence_missing_command"
    local function start_missing(on_error)
      local function _9_()
      end
      local function _10_()
      end
      local function _11_()
      end
      return stdio.start({["prompt-pattern"] = ">> ", cmd = "nope-this-does-not-exist", ["on-success"] = _9_, ["on-error"] = on_error, ["on-exit"] = _10_, ["on-stray-output"] = _11_})
    end
    local function _12_()
      vim.g[flag_var] = false
      local captured = nil
      local result
      local function _13_(err)
        captured = err
        return nil
      end
      result = start_missing(_13_)
      assert.is_nil(result)
      local function _14_()
        return (captured ~= nil)
      end
      vim.wait(1000, _14_)
      assert.is_truthy(string.find(captured, "command not found", 1, true))
      return assert.is_truthy(string.find(captured, "nope-this-does-not-exist", 1, true))
    end
    it("returns nil and reports a friendly error when the command is missing", _12_)
    local function _15_()
      vim.g[flag_var] = true
      local captured = nil
      do
        local result
        local function _16_(err)
          captured = err
          return nil
        end
        result = start_missing(_16_)
        assert.is_nil(result)
        local function _17_()
          return (captured ~= nil)
        end
        vim.wait(200, _17_)
        assert.is_nil(captured)
      end
      vim.g[flag_var] = false
      return nil
    end
    return it("stays silent when silence_missing_command is enabled", _15_)
  end
  return describe("start", _8_)
end
return describe("conjure.remote.stdio", _2_)
