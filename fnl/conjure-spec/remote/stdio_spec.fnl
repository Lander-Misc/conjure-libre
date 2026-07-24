(local {: describe : it} (require :plenary.busted))
(local assert (require :luassert.assert))
(local stdio (require :conjure.remote.stdio))

(describe "conjure.remote.stdio"
  (fn []
    (describe "parse-cmd"
      (fn []
        (it "parses a string"
          (fn []
            (assert.same {:cmd "foo" :args []} (stdio.parse-cmd "foo"))))
        (it "parses a list of one string"
          (fn []
            (assert.same {:cmd "foo" :args []} (stdio.parse-cmd ["foo"]))))
        (it "parses a string with words separated by spaces"
          (fn []
            (assert.same {:cmd "foo" :args ["bar" "baz"]} (stdio.parse-cmd "foo bar baz"))))
        (it "parses a list of more than one string"
          (fn []
            (assert.same {:cmd "foo" :args ["bar" "baz"]} (stdio.parse-cmd ["foo" "bar" "baz"]))))))

    (describe "start"
      (fn []
        (local flag-var "conjure#stdio#silence_missing_command")

        (fn start-missing [on-error]
          (stdio.start
            {:prompt-pattern ">> "
             :cmd "nope-this-does-not-exist"
             :on-success (fn [])
             :on-error on-error
             :on-exit (fn [])
             :on-stray-output (fn [])}))

        (it "returns nil and reports a friendly error when the command is missing"
          (fn []
            (tset vim.g flag-var false)
            (var captured nil)
            (let [result (start-missing (fn [err] (set captured err)))]
              (assert.is_nil result)
              (vim.wait 1000 (fn [] (not= captured nil)))
              (assert.is_truthy (string.find captured "command not found" 1 true))
              (assert.is_truthy (string.find captured "nope-this-does-not-exist" 1 true)))))

        (it "stays silent when silence_missing_command is enabled"
          (fn []
            (tset vim.g flag-var true)
            (var captured nil)
            (let [result (start-missing (fn [err] (set captured err)))]
              (assert.is_nil result)
              ;; Give any (incorrectly) scheduled callback a chance to run.
              (vim.wait 200 (fn [] (not= captured nil)))
              (assert.is_nil captured))
            (tset vim.g flag-var false)))))))
