-- [nfnl] fnl/conjure-spec/event_spec.fnl
local _local_1_ = require("plenary.busted")
local describe = _local_1_.describe
local it = _local_1_.it
local assert = require("luassert.assert")
local event = require("conjure.event")
local function flush()
  local function _2_()
    return false
  end
  return vim.wait(50, _2_)
end
local function capture_data(pattern)
  local state = {fired = 0, data = nil}
  local group = vim.api.nvim_create_augroup(("conjure-spec-event-" .. pattern), {clear = true})
  local function _3_(ev)
    state.fired = (state.fired + 1)
    state.data = ev.data
    return nil
  end
  vim.api.nvim_create_autocmd("User", {pattern = pattern, group = group, callback = _3_})
  return state
end
local function _4_()
  local function _5_()
    local function _6_()
      local state = capture_data("ConjureSpecfoo")
      event["emit-data"]("specfoo", "hello world")
      flush()
      assert.are.equals(1, state.fired)
      return assert.are.equals("hello world", state.data)
    end
    it("fires a User Conjure<Name> autocmd carrying the data payload", _6_)
    local function _7_()
      local state = capture_data("ConjureBar")
      event["emit-data"]("bar", "x")
      flush()
      return assert.are.equals("x", state.data)
    end
    it("upper-cases the first character of the event name", _7_)
    local function _8_()
      local state = capture_data("ConjureBaz")
      local payload = {hello = "world", n = 1}
      event["emit-data"]("baz", payload)
      flush()
      return assert.same(payload, state.data)
    end
    return it("passes table data through unchanged", _8_)
  end
  return describe("emit-data", _5_)
end
return describe("conjure.event", _4_)
