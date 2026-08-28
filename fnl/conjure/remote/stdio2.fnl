(local {: autoload : define} (require :conjure.nfnl.module))
(local core (autoload :conjure.nfnl.core))
(local str (autoload :conjure.nfnl.string))
(local client (autoload :conjure.client))
(local log (autoload :conjure.log))

(local uv vim.uv)

(local M (define :conjure.remote.stdio2))

(fn M.parse-cmd [x]
  (if
    (core.table? x)
    {:cmd (core.first x)
     :args (core.rest x)}

    (core.string? x)
    (M.parse-cmd (str.split x "%s"))))

M
