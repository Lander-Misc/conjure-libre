-- [nfnl] fnl/conjure-spec/remote/stdio-prompt_spec.fnl
local _local_1_ = require("plenary.busted")
local describe = _local_1_.describe
local it = _local_1_.it
local assert = require("luassert.assert")
local stdio = require("conjure.remote.stdio")
local scheme = require("conjure.client.scheme.stdio")
local config = require("conjure.config")
local function _2_()
  for _, preserve_3f in ipairs({false, true}) do
    local function _3_()
      local repl = nil
      local done_3f = false
      local msgs = {}
      local errors = {}
      local function _4_()
        local function _5_(msg)
          table.insert(msgs, msg)
          if msg["done?"] then
            done_3f = true
            return nil
          else
            if string.match(scheme.unbatch(msgs).out, "12 $") then
              return repl["immediate-send"]("ack\n")
            else
              return nil
            end
          end
        end
        return repl.send("eval\n", _5_)
      end
      local function _8_(_241)
        return table.insert(errors, _241)
      end
      local function _9_()
      end
      local function _10_()
      end
      repl = stdio.start({cmd = {"sh", "-c", "read first; printf 'number: 42\n12 '; read ack; printf 'error> '; read last"}, ["prompt-pattern"] = config["get-in"]({"client", "scheme", "stdio", "prompt_pattern"}), ["preserve-prompt?"] = preserve_3f, ["on-success"] = _4_, ["on-error"] = _8_, ["on-exit"] = _9_, ["on-stray-output"] = _10_})
      local function _11_()
        return (done_3f or (#errors > 0))
      end
      vim.wait(2000, _11_)
      if repl then
        repl.destroy()
      else
      end
      assert.same({}, errors)
      assert.is_true(done_3f)
      assert.is_true((#msgs >= 2))
      if preserve_3f then
        assert.same("number: 42\n12 error> ", scheme.unbatch(msgs).out)
        return assert.same({"; (out) number: 42"}, scheme["format-msg"](scheme.unbatch(msgs)))
      else
        return assert.same("number: 42\n12 ", scheme.unbatch(msgs).out)
      end
    end
    it(("handles a split MIT prompt with preservation " .. tostring(preserve_3f)), _3_)
  end
  return nil
end
return describe("stdio prompt preservation", _2_)
