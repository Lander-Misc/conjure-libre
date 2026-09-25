-- [nfnl] fnl/conjure/client/scheme/stdio.fnl
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
local cmpl = autoload("conjure.client.scheme.completions")
local vim = _G.vim
local M = define("conjure.client.scheme.stdio")
local default_prompt_pattern = "[%]e][=r]r?o?r?> "
config.merge({client = {scheme = {stdio = {command = "mit-scheme", prompt_pattern = default_prompt_pattern, value_prefix_pattern = "^;Value: ", enable_completions = true}}}})
if config["get-in"]({"mapping", "enable_defaults"}) then
  config.merge({client = {scheme = {stdio = {mapping = {start = "cs", stop = "cS", interrupt = "ei"}}}}})
else
end
local cfg = config["get-in-fn"]({"client", "scheme", "stdio"})
local state
local function _3_()
  return {repl = nil}
end
state = client["new-state"](_3_)
local function completions_enabled_3f()
  return cfg({"enable_completions"})
end
M["buf-suffix"] = ".scm"
M["comment-prefix"] = "; "
M["form-node?"] = ts["node-surrounded-by-form-pair-chars?"]
M["valid-str?"] = function(code)
  return ts["valid-str?"]("scheme", code)
end
local function with_repl_or_warn(f, opts)
  local repl = state("repl")
  if repl then
    return f(repl)
  else
    return log.append({(M["comment-prefix"] .. "No REPL running")})
  end
end
M.unbatch = function(msgs)
  local function _5_(_241)
    return (core.get(_241, "out") or core.get(_241, "err"))
  end
  return {out = str.join("", core.map(_5_, msgs))}
end
local function default_prompt_3f()
  return (default_prompt_pattern == cfg({"prompt_pattern"}))
end
local function strip_default_prompt(out)
  if default_prompt_3f() then
    return string.gsub(out, ("%s*%d* ?" .. default_prompt_pattern), "")
  else
    return out
  end
end
M["format-msg"] = function(msg)
  local function _7_(_241)
    return not str["blank?"](_241)
  end
  local function _8_(line)
    if not cfg({"value_prefix_pattern"}) then
      return line
    elseif string.match(line, cfg({"value_prefix_pattern"})) then
      return string.gsub(line, cfg({"value_prefix_pattern"}), "")
    else
      return (M["comment-prefix"] .. "(out) " .. line)
    end
  end
  return core.filter(_7_, core.map(_8_, str.split(string.gsub(strip_default_prompt(core.get(msg, "out")), "^%s*", ""), "\n")))
end
M["eval-str"] = function(opts)
  local function _10_(repl)
    if M["valid-str?"](opts.code) then
      local function _11_(msgs)
        local msgs0 = M["format-msg"](M.unbatch(msgs))
        opts["on-result"](core.last(msgs0))
        return log.append(msgs0)
      end
      return repl.send((opts.code .. "\n"), _11_, {["batch?"] = true})
    else
      return log.append({(M["comment-prefix"] .. "eval error: could not parse form")})
    end
  end
  return with_repl_or_warn(_10_)
end
M["eval-file"] = function(opts)
  return M["eval-str"](core.assoc(opts, "code", ("(load \"" .. opts["file-path"] .. "\")")))
end
local function display_repl_status(status)
  return log.append({(M["comment-prefix"] .. cfg({"command"}) .. " (" .. (status or "no status") .. ")")}, {["break?"] = true})
end
M.stop = function()
  local repl = state("repl")
  if repl then
    repl.destroy()
    display_repl_status("stopped")
    return core.assoc(state(), "repl", nil)
  else
    return nil
  end
end
M.start = function()
  if state("repl") then
    return log.append({(M["comment-prefix"] .. "Can't start, REPL is already running."), (M["comment-prefix"] .. "Stop the REPL with " .. config["get-in"]({"mapping", "prefix"}) .. cfg({"mapping", "stop"}))}, {["break?"] = true})
  else
    local function _14_()
      if completions_enabled_3f() then
        cmpl["get-completions"]()
      else
      end
      return display_repl_status("started")
    end
    local function _16_(err)
      return display_repl_status(err)
    end
    local function _17_(code, signal)
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
    local function _20_(msg)
      return log.append(M["format-msg"](msg))
    end
    return core.assoc(state(), "repl", stdio.start({["prompt-pattern"] = cfg({"prompt_pattern"}), ["preserve-prompt?"] = default_prompt_3f(), cmd = cfg({"command"}), ["on-success"] = _14_, ["on-error"] = _16_, ["on-exit"] = _17_, ["on-stray-output"] = _20_}))
  end
end
M.interrupt = function()
  local function _22_(repl)
    log.append({(M["comment-prefix"] .. " Sending interrupt signal.")}, {["break?"] = true})
    return repl["send-signal"]("sigint")
  end
  return with_repl_or_warn(_22_)
end
M["on-load"] = function()
  return M.start()
end
M["on-filetype"] = function()
  local function _24_(_23_)
    local args = _23_.args
    local function _25_(repl)
      log.append({(M["comment-prefix"] .. "Sending input to REPL: " .. args)}, {["break?"] = true})
      return repl["immediate-send"]((args .. "\n"))
    end
    with_repl_or_warn(_25_)
    return nil
  end
  vim.api.nvim_create_user_command("ConjureSchemeInput", _24_, {nargs = 1})
  local function _26_()
    return M.start()
  end
  mapping.buf("SchemeStart", cfg({"mapping", "start"}), _26_, {desc = "Start the REPL"})
  local function _27_()
    return M.stop()
  end
  mapping.buf("SchemeStop", cfg({"mapping", "stop"}), _27_, {desc = "Stop the REPL"})
  local function _28_()
    return M.interrupt()
  end
  return mapping.buf("SchemeInterrupt", cfg({"mapping", "interrupt"}), _28_, {desc = "Interrupt the REPL"})
end
M["on-exit"] = function()
  return M.stop()
end
M.completions = function(opts)
  if completions_enabled_3f() then
    local prefix = (opts.prefix or "")
    local suggestions = cmpl["get-completions"](prefix)
    return opts.cb(suggestions)
  else
    return opts.cb({})
  end
end
return M
