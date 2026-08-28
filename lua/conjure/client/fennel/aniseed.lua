-- [nfnl] fnl/conjure/client/fennel/aniseed.fnl
local _local_1_ = require("conjure.nfnl.module")
local autoload = _local_1_.autoload
local define = _local_1_.define
local a = autoload("conjure.aniseed.core")
local client = autoload("conjure.client")
local config = autoload("conjure.config")
local extract = autoload("conjure.extract")
local fs = autoload("conjure.fs")
local log = autoload("conjure.log")
local mapping = autoload("conjure.mapping")
local str = autoload("conjure.aniseed.string")
local text = autoload("conjure.text")
local ts = autoload("conjure.tree-sitter")
local view = autoload("conjure.aniseed.view")
local M = define("conjure.client.fennel.aniseed")
M["comment-node?"] = ts["lisp-comment-node?"]
M["form-node?"] = function(node)
  return ts["node-surrounded-by-form-pair-chars?"](node, {{"#(", ")"}})
end
M["buf-suffix"] = ".fnl"
M["context-pattern"] = "%(%s*module%s+(.-)[%s){]"
M["comment-prefix"] = "; "
config.merge({client = {fennel = {aniseed = {aniseed_module_prefix = "conjure.aniseed.", use_metadata = true}}}})
if config["get-in"]({"mapping", "enable_defaults"}) then
  config.merge({client = {fennel = {aniseed = {mapping = {run_buf_tests = "tt", run_all_tests = "ta", reset_repl = "rr", reset_all_repls = "ra"}}}}})
else
end
local cfg = config["get-in-fn"]({"client", "fennel", "aniseed"})
local ani_aliases = {nu = "nvim.util"}
local function ani(mod_name, f_name)
  local mod_name0 = a.get(ani_aliases, mod_name, mod_name)
  local mod = require((cfg({"aniseed_module_prefix"}) .. mod_name0))
  if f_name then
    return a.get(mod, f_name)
  else
    return mod
  end
end
local function anic(mod, f_name, ...)
  return ani(mod, f_name)(...)
end
local repls = {}
M["reset-repl"] = function(filename)
  local filename0 = (filename or fs["localise-path"](extract["file-path"]()))
  repls[filename0] = nil
  return log.append({("; Reset REPL for " .. filename0)}, {["break?"] = true})
end
M["reset-all-repls"] = function()
  local function _4_(filename)
    repls[filename] = nil
    return nil
  end
  a["run!"](_4_, a.keys(repls))
  return log.append({"; Reset all REPLs"}, {["break?"] = true})
end
M["default-module-name"] = "conjure.user"
M["module-name"] = function(context, file_path)
  if context then
    return context
  elseif file_path then
    return (fs["file-path->module-name"](file_path) or M["default-module-name"])
  else
    return M["default-module-name"]
  end
end
M.repl = function(opts)
  local filename = a.get(opts, "filename")
  local or_6_ = (not a.get(opts, "fresh?") and a.get(repls, filename))
  if not or_6_ then
    local ret = {}
    local _
    local function _8_(err)
      ret["ok?"] = false
      ret.results = {err}
      return nil
    end
    opts["error-handler"] = _8_
    _ = nil
    local eval_21 = anic("eval", "repl", opts)
    local repl
    local function _9_(code)
      ret["ok?"] = nil
      ret.results = nil
      local results = eval_21(code)
      if a["nil?"](ret["ok?"]) then
        ret["ok?"] = true
        ret.results = results
      else
      end
      return ret
    end
    repl = _9_
    repl(("(module " .. a.get(opts, "moduleName") .. ")"))
    repls[filename] = repl
    or_6_ = repl
  end
  return or_6_
end
M["display-result"] = function(opts)
  if opts then
    local ok_3f = opts["ok?"]
    local results = opts.results
    local result_str
    local _11_
    if ok_3f then
      if not a["empty?"](results) then
        _11_ = str.join("\n", a.map(view.serialise, results))
      else
        _11_ = nil
      end
    else
      _11_ = a.first(results)
    end
    result_str = (_11_ or "nil")
    local result_lines = str.split(result_str, "\n")
    if not opts["passive?"] then
      local function _15_()
        if ok_3f then
          return result_lines
        else
          local function _14_(_241)
            return ("; " .. _241)
          end
          return a.map(_14_, result_lines)
        end
      end
      log.append(_15_())
    else
    end
    if opts["on-result-raw"] then
      opts["on-result-raw"](results)
    else
    end
    if opts["on-result"] then
      return opts["on-result"](result_str)
    else
      return nil
    end
  else
    return nil
  end
end
M["eval-str"] = function(opts)
  local function _20_()
    local out
    local function _21_()
      if (cfg({"use_metadata"}) and not package.loaded.fennel) then
        package.loaded.fennel = anic("fennel", "impl")
      else
      end
      local eval_21 = M.repl({filename = opts["file-path"], moduleName = M["module-name"](opts.context, opts["file-path"]), useMetadata = cfg({"use_metadata"}), ["fresh?"] = (("file" == opts.origin) or ("buf" == opts.origin) or text["starts-with"](opts.code, ("(module " .. (opts.context or ""))))})
      local _let_23_ = eval_21((opts.code .. "\n"))
      local ok_3f = _let_23_["ok?"]
      local results = _let_23_.results
      if ("ok" ~= a["get-in"](eval_21(":ok\n"), {"results", 1})) then
        log.append({"; REPL appears to be stuck, did you open a string or form and not close it?", str.join({"; You can use ", config["get-in"]({"mapping", "prefix"}), cfg({"mapping", "reset_repl"}), " to reset and repair the REPL."})})
      else
      end
      opts["ok?"] = ok_3f
      opts.results = results
      return nil
    end
    out = anic("nu", "with-out-str", _21_)
    if not a["empty?"](out) then
      log.append(text["prefixed-lines"](text["trim-last-newline"](out), "; (out) "))
    else
    end
    return M["display-result"](opts)
  end
  return client.wrap(_20_)()
end
M["doc-str"] = function(opts)
  a.assoc(opts, "code", (",doc " .. opts.code))
  return M["eval-str"](opts)
end
M["eval-file"] = function(opts)
  opts.code = a.slurp(opts["file-path"])
  if opts.code then
    return M["eval-str"](opts)
  else
    return nil
  end
end
local function wrapped_test(req_lines, f)
  log.append(req_lines, {["break?"] = true})
  local res = anic("nu", "with-out-str", f)
  local _27_
  if ("" == res) then
    _27_ = "No results."
  else
    _27_ = res
  end
  return log.append(text["prefixed-lines"](_27_, "; "))
end
M["run-buf-tests"] = function()
  local c = extract.context()
  if c then
    local function _29_()
      return anic("test", "run", c)
    end
    return wrapped_test({("; run-buf-tests (" .. c .. ")")}, _29_)
  else
    return nil
  end
end
M["run-all-tests"] = function()
  return wrapped_test({"; run-all-tests"}, ani("test", "run-all"))
end
M["on-filetype"] = function()
  local function _31_()
    return M["run-buf-tests"]()
  end
  mapping.buf("FnlRunBufTests", cfg({"mapping", "run_buf_tests"}), _31_, {desc = "Run loaded buffer tests"})
  local function _32_()
    return M["run-all-tests"]()
  end
  mapping.buf("FnlRunAllTests", cfg({"mapping", "run_all_tests"}), _32_, {desc = "Run all loaded tests"})
  local function _33_()
    return M["reset-repl"]()
  end
  mapping.buf("FnlResetREPL", cfg({"mapping", "reset_repl"}), _33_, {desc = "Reset the current REPL state"})
  local function _34_()
    return M["reset-all-repls"]()
  end
  return mapping.buf("FnlResetAllREPLs", cfg({"mapping", "reset_all_repls"}), _34_, {desc = "Reset all REPL states"})
end
M["value->completions"] = function(x)
  if ("table" == type(x)) then
    local function _36_(_35_)
      local k = _35_[1]
      local v = _35_[2]
      return {word = k, kind = type(v), menu = nil, info = nil}
    end
    local function _38_(_37_)
      local k = _37_[1]
      local v = _37_[2]
      return not text["starts-with"](k, "aniseed/")
    end
    local function _39_()
      if x["aniseed/autoload-enabled?"] then
        do local _ = x["trick-aniseed-into-loading-the-module"] end
        return x["aniseed/autoload-module"]
      else
        return x
      end
    end
    return a.map(_36_, a.filter(_38_, a["kv-pairs"](_39_())))
  else
    return nil
  end
end
M.completions = function(opts)
  local code
  if not str["blank?"](opts.prefix) then
    local prefix = string.gsub(opts.prefix, ".$", "")
    code = ("((. (require :conjure.client.fennel.aniseed) :value->completions) " .. prefix .. ")")
  else
    code = nil
  end
  local mods = M["value->completions"](package.loaded)
  local locals
  do
    local ok_3f, m
    local function _42_()
      return require(opts.context)
    end
    ok_3f, m = pcall(_42_)
    if ok_3f then
      locals = a.concat(M["value->completions"](m), M["value->completions"](a.get(m, "aniseed/locals")), mods)
    else
      locals = mods
    end
  end
  local result_fn
  local function _44_(results)
    local xs = a.first(results)
    local function _47_()
      if ("table" == type(xs)) then
        local function _45_(x)
          local function _46_(_241)
            return (opts.prefix .. _241)
          end
          return a.update(x, "word", _46_)
        end
        return a.concat(a.map(_45_, xs), locals)
      else
        return locals
      end
    end
    return opts.cb(_47_())
  end
  result_fn = _44_
  local ok_3f, err_or_res
  if code then
    local function _48_()
      return M["eval-str"]({["file-path"] = opts["file-path"], context = opts.context, code = code, ["passive?"] = true, ["on-result-raw"] = result_fn})
    end
    ok_3f, err_or_res = pcall(_48_)
  else
    ok_3f, err_or_res = nil
  end
  if not ok_3f then
    return opts.cb(locals)
  else
    return nil
  end
end
return M
