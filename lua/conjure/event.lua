-- [nfnl] fnl/conjure/event.fnl
local _local_1_ = require("conjure.nfnl.module")
local autoload = _local_1_.autoload
local define = _local_1_.define
local core = autoload("conjure.nfnl.core")
local text = autoload("conjure.text")
local client = autoload("conjure.client")
local str = autoload("conjure.nfnl.string")
local M = define("conjure.event")
M.emit = function(...)
  do
    local names = core.map(text["upper-first"], {...})
    local function _2_()
      while not core["empty?"](names) do
        vim.cmd.doautocmd("User", ("Conjure" .. str.join(names)))
        table.remove(names)
      end
      return nil
    end
    client.schedule(_2_)
  end
  return nil
end
M["emit-data"] = function(name, data)
  do
    local pattern = ("Conjure" .. text["upper-first"](name))
    local function _3_()
      return vim.api.nvim_exec_autocmds("User", {pattern = pattern, data = data})
    end
    client.schedule(_3_)
  end
  return nil
end
return M
