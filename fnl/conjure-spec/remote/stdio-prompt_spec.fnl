(local {: describe : it} (require :plenary.busted))
(local assert (require :luassert.assert))
(local stdio (require :conjure.remote.stdio))
(local scheme (require :conjure.client.scheme.stdio))
(local config (require :conjure.config))

(describe "stdio prompt preservation"
  (fn []
    (each [_ preserve? (ipairs [false true])]
      (it (.. "handles a split MIT prompt with preservation " (tostring preserve?))
        (fn []
          (var repl nil)
          (var done? false)
          (local msgs [])
          (local errors [])
          ;; The child waits for an acknowledgement between writes, guaranteeing
          ;; the prompt number and suffix arrive in separate OS reads.
          (set repl
            (stdio.start
              {:cmd ["sh" "-c" "read first; printf 'number: 42\n12 '; read ack; printf 'error> '; read last"]
               :prompt-pattern (config.get-in [:client :scheme :stdio :prompt_pattern])
               :preserve-prompt? preserve?
               :on-success
               (fn []
                 (repl.send "eval\n"
                   (fn [msg]
                     (table.insert msgs msg)
                     (if msg.done?
                       (set done? true)
                       (when (string.match (. (scheme.unbatch msgs) :out) "12 $")
                         (repl.immediate-send "ack\n"))))))
               :on-error #(table.insert errors $1)
               :on-exit (fn [])
               :on-stray-output (fn [])}))
          (vim.wait 2000 (fn [] (or done? (> (length errors) 0))))
          (when repl (repl.destroy))
          (assert.same [] errors)
          (assert.is_true done?)
          (assert.is_true (>= (length msgs) 2))
          (if preserve?
            (do
              (assert.same "number: 42\n12 error> " (. (scheme.unbatch msgs) :out))
              (assert.same ["; (out) number: 42"]
                (scheme.format-msg (scheme.unbatch msgs))))
            (assert.same "number: 42\n12 " (. (scheme.unbatch msgs) :out))))))))
