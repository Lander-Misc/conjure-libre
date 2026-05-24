-- [nfnl] fnl/conjure/client/picolisp/stdio.fnl
local _local_1_ = require("conjure.nfnl.module")
local autoload = _local_1_.autoload
local define = _local_1_.define
local core = autoload("conjure.nfnl.core")
local str = autoload("conjure.nfnl.string")
local stdio = autoload("conjure.remote.stdio")
local config = autoload("conjure.config")
local mapping = autoload("conjure.mapping")
local client = autoload("conjure.client")
local log = autoload("conjure.log")
local ts = autoload("conjure.tree-sitter")
local M = define("conjure.client.picolisp.stdio")
config.merge({client = {picolisp = {stdio = {command = {"pil", "-(prog (print '>>>) (flush) (while (read) (println (eval @)) (print '>>>) (flush)))", "+"}, prompt_pattern = ">>>"}}}})
if config["get-in"]({"mapping", "enable_defaults"}) then
  config.merge({client = {picolisp = {stdio = {mapping = {start = "cs", stop = "cS"}}}}})
else
end
local cfg = config["get-in-fn"]({"client", "picolisp", "stdio"})
local or_3_ = M.state
if not or_3_ then
  local function _4_()
    return {repl = nil}
  end
  or_3_ = client["new-state"](_4_)
end
M.state = or_3_
M["buf-suffix"] = ".l"
M["comment-prefix"] = "# "
M["form-node?"] = ts["node-surrounded-by-form-pair-chars?"]
M["comment-node?"] = function(node)
  return ts["node-prefixed-by-chars?"](node, {"#"})
end
local function with_repl_or_warn(f, _opts)
  local repl = M.state("repl")
  if repl then
    return f(repl)
  else
    return log.append({(M["comment-prefix"] .. "No REPL running")})
  end
end
local function format_message(msg)
  return str.split((msg.out or msg.err), "\n")
end
local function display_result(msg)
  local function _6_(_241)
    return not ("" == _241)
  end
  return log.append(core.filter(_6_, format_message(msg)))
end
M["eval-str"] = function(opts)
  local function _7_(repl)
    local function _8_(msgs)
      if ((1 == core.count(msgs)) and ("" == core["get-in"](msgs, {1, "out"}))) then
        core["assoc-in"](msgs, {1, "out"}, (M["comment-prefix"] .. "Empty result."))
      else
      end
      if opts["on-result"] then
        opts["on-result"](str.join("\n", format_message(core.last(msgs))))
      else
      end
      return core["run!"](display_result, msgs)
    end
    return repl.send((opts.code .. "\n"), _8_, {["batch?"] = true})
  end
  return with_repl_or_warn(_7_)
end
M["eval-file"] = function(opts)
  return M["eval-str"](core.assoc(opts, "code", core.slurp(opts["file-path"])))
end
local function display_repl_status(status)
  local repl = M.state("repl")
  if repl then
    return log.append({(M["comment-prefix"] .. core["pr-str"](core["get-in"](repl, {"opts", "cmd"})) .. " (" .. status .. ")")}, {["break?"] = true})
  else
    return nil
  end
end
M.stop = function()
  local repl = M.state("repl")
  if repl then
    repl.destroy()
    display_repl_status("stopped")
    return core.assoc(M.state(), "repl", nil)
  else
    return nil
  end
end
M.start = function()
  if M.state("repl") then
    return log.append({(M["comment-prefix"] .. "Can't start, REPL is already running."), (M["comment-prefix"] .. "Stop the REPL with " .. config["get-in"]({"mapping", "prefix"}) .. cfg({"mapping", "stop"}))}, {["break?"] = true})
  else
    local function _13_()
      return display_repl_status("started")
    end
    local function _14_(err)
      return display_repl_status(err)
    end
    local function _15_(code, signal)
      if (("number" == type(code)) and (code > 0)) then
        log.append({(M["comment-prefix"] .. "process exited with code " .. code)})
      else
      end
      if (("number" == type(signal)) and (signal > 0)) then
        log.append({(M["comment-prefix"] .. "process exited with signal " .. signal)})
      else
      end
      return M.stop()
    end
    local function _18_(msg)
      return display_result(msg)
    end
    return core.assoc(M.state(), "repl", stdio.start({["prompt-pattern"] = cfg({"prompt_pattern"}), cmd = cfg({"command"}), ["on-success"] = _13_, ["on-error"] = _14_, ["on-exit"] = _15_, ["on-stray-output"] = _18_}))
  end
end
M["on-load"] = function()
  return M.start()
end
M["on-exit"] = function()
  return M.stop()
end
M["on-filetype"] = function()
  local function _20_()
    return M.start()
  end
  mapping.buf("PicolispStart", cfg({"mapping", "start"}), _20_, {desc = "Start the REPL"})
  local function _21_()
    return M.stop()
  end
  return mapping.buf("PicolispStop", cfg({"mapping", "stop"}), _21_, {desc = "Stop the REPL"})
end
return M
