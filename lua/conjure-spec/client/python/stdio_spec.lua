-- [nfnl] fnl/conjure-spec/client/python/stdio_spec.fnl
local _local_1_ = require("plenary.busted")
local describe = _local_1_.describe
local it = _local_1_.it
local assert = require("luassert.assert")
local python = require("conjure.client.python.stdio")
local function _2_()
  local function _3_()
    local function _4_()
      local function _5_(_)
        return true
      end
      python["str-is-python-expr?"] = _5_
      return assert.same("__file__ = base64.b64decode('L3RtcC9leGFtcGxlLnB5').decode()\n__file__\n", python["prep-code"]({code = "__file__", ["file-path"] = "/tmp/example.py"}))
    end
    it("sets __file__ before evaluating expressions", _4_)
    local function _6_()
      local function _7_(_)
        return false
      end
      python["str-is-python-expr?"] = _7_
      return assert.same("__file__ = base64.b64decode('L3RtcC9leGFtcGxlLnB5').decode()\nexec(compile(base64.b64decode('cHJpbnQoX19maWxlX18p'), __file__, 'exec'))\n", python["prep-code"]({code = "print(__file__)", ["file-path"] = "/tmp/example.py"}))
    end
    it("sets __file__ and uses it as the filename for exec evaluations", _6_)
    local function _8_()
      local function _9_(_)
        return true
      end
      python["str-is-python-expr?"] = _9_
      return assert.same("__file__ = base64.b64decode('PGNvbmp1cmU+').decode()\n__file__\n", python["prep-code"]({code = "__file__"}))
    end
    return it("uses a fallback filename when no file path is available", _8_)
  end
  return describe("prep-code", _3_)
end
return describe("conjure.client.python.stdio", _2_)
